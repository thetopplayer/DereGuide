//
//  UnitDownloader.swift
//  CGSSGuide
//
//  Created by Daniel Eggert on 22/05/2015.
//  Copyright (c) 2015 objc.io. All rights reserved.
//

import CoreData

/// download the newest remote units and re
final class UnitDownloader: ChangeProcessor {
   
    typealias Element = Unit
    
    var remote: UnitsRemote
    
    var unitsInFetching = [RemoteIdentifier]()
    
    init(remote: UnitsRemote) {
        self.remote = remote
    }
    
    func setup(for context: ChangeProcessorContext) {
        remote.setupSubscription()
    }

    func processChangedLocalObjects(_ objects: [NSManagedObject], in context: ChangeProcessorContext) {
        // no-op
    }

    func processRemoteChanges<T>(_ changes: [RemoteRecordChange<T>], in context: ChangeProcessorContext, completion: () -> ()) {
        var creates: [RemoteUnit] = []
        var deletionIDs: [RemoteIdentifier] = []
        var updates: [RemoteUnit] = []
        for change in changes {
            switch change {
            case .insert(let r) where r is RemoteUnit:
                creates.append(r as! RemoteUnit)
            case .delete(let id):
                deletionIDs.append(id)
            case .update(let r) where r is RemoteUnit:
                updates.append(r as! RemoteUnit)
            default:
                continue
            }
        }
        insert(creates, in: context)
        deleteUnits(with: deletionIDs, in: context)
        update(updates, in: context)
        if Config.cloudKitDebug && creates.count + deletionIDs.count + updates.count > 0 {
            print("Unit remote fetch inserts: \(creates.count) delete: \(deletionIDs.count) and updates: \(updates.count)")
        }
        context.delayedSaveOrRollback()
        completion()
    }

    func fetchLatestRemoteRecords(in context: ChangeProcessorContext) {
        remote.fetchLatestRecords(completion: { (remoteUnits) in
            self.insert(remoteUnits, in: context)
            self.reserve(remoteUnits, in: context)
            self.update(remoteUnits, in: context)
        })
    }

    func entityAndPredicateForLocallyTrackedObjects(in context: ChangeProcessorContext) -> EntityAndPredicate<NSManagedObject>? {
        return nil
    }

}


extension UnitDownloader {

    fileprivate func deleteUnits(with ids: [RemoteIdentifier], in context: ChangeProcessorContext) {
        guard !ids.isEmpty else { return }
        context.perform {
            let units = Unit.fetch(in: context.managedObjectContext) { (request) -> () in
                request.predicate = Unit.predicateForRemoteIdentifiers(ids)
                request.returnsObjectsAsFaults = false
            }
            units.forEach { $0.markForLocalDeletion() }
        }
    }
    
    fileprivate func reserve(_ reserves: [RemoteUnit], in context: ChangeProcessorContext) {
        context.perform {
            let remoteRemoveds = { () -> [RemoteIdentifier] in
                let ids = reserves.map { $0.id }
                let units = Unit.fetch(in: context.managedObjectContext) { request in
                    request.predicate = Unit.predicateForNotInRemoteIdentifiers(ids)
                    request.returnsObjectsAsFaults = false
                }
                return units.map { $0.remoteIdentifier }.flatMap { $0 }
            }()
            
            // delete those have no remote records but left in local database
            self.deleteUnits(with: remoteRemoveds, in: context)
            context.delayedSaveOrRollback()
        }
    }

    fileprivate func insert(_ remoteUnit: RemoteUnit, into context: ChangeProcessorContext) {
        remoteUnit.insert(into: context.managedObjectContext) { success in
            if success {
                context.delayedSaveOrRollback()
                guard let index = self.unitsInFetching.index(of: remoteUnit.id) else {
                    return
                }
                self.unitsInFetching.remove(at: index)
            } else {
                self.retryAfter(in: context, task: {
                    self.insert(remoteUnit, into: context)
                })
            }
        }
    }
    
    fileprivate func insert(_ inserts: [RemoteUnit], in context: ChangeProcessorContext) {
        context.perform {
            let existingUnits = { () -> [RemoteIdentifier: Unit] in
                let ids = inserts.map { $0.id }
                let units = Unit.fetch(in: context.managedObjectContext) { request in
                    request.predicate = Unit.predicateForRemoteIdentifiers(ids)
                    request.returnsObjectsAsFaults = false
                }
                var result: [RemoteIdentifier: Unit] = [:]
                for unit in units {
                    result[unit.remoteIdentifier!] = unit
                }
                return result
            }()
            
            for remoteUnit in inserts {
                guard existingUnits[remoteUnit.id] == nil && !self.unitsInFetching.contains(remoteUnit.id) else { continue }
                
                // insertion of unit need to fetch participated members from cloudkit async, so keep an in-fetching tracking array to avoid insert the same unit more than once(cause the CloudKit subscription may fire more than once for the same change.
                self.unitsInFetching.append(remoteUnit.id)
                self.insert(remoteUnit, into: context)
            }
        }
    }
    
    fileprivate func update(_ updates: [RemoteUnit], in context: ChangeProcessorContext) {
        context.perform {
            let existingUnits = { () -> [RemoteIdentifier: Unit] in
                let ids = updates.map { $0.id }
                let units = Unit.fetch(in: context.managedObjectContext) { request in
                    request.predicate = Unit.predicateForRemoteIdentifiers(ids)
                    request.returnsObjectsAsFaults = false
                }
                var result: [RemoteIdentifier: Unit] = [:]
                for unit in units {
                    result[unit.remoteIdentifier!] = unit
                }
                return result
            }()
            
            for remoteUnit in updates {
                guard let unit = existingUnits[remoteUnit.id] else { continue }
                unit.update(using: remoteUnit)
                context.delayedSaveOrRollback()
            }
        }
    }

}

