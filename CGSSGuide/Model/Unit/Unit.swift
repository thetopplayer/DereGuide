//
//  Unit+CoreDataClass.swift
//  CGSSGuide
//
//  Created by zzk on 2017/7/7.
//  Copyright © 2017年 zzk. All rights reserved.
//
//

import Foundation
import CoreData
import CloudKit

public class Unit: NSManagedObject {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Unit> {
        return NSFetchRequest<Unit>(entityName: "Unit")
    }
    
    @NSManaged public var customAppeal: Int64
    @NSManaged public var supportAppeal: Int64
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var usesCustomAppeal: Bool
    @NSManaged public var otherMembers: Set<Member>
    @NSManaged public var center: Member
    @NSManaged public var guest: Member
    
    @NSManaged fileprivate var primitiveCreatedAt: Date
    @NSManaged fileprivate var primitiveUpdatedAt: Date
    
    public lazy var ckReference: CKReference = CKReference(record: self.toCKRecord(), action: .deleteSelf)
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        primitiveUpdatedAt = Date()
        primitiveCreatedAt = Date()
    }
    
    public override func willSave() {
        super.willSave()
        if hasChanges {
            refreshUpdateDate()
            markForRemoteModification()
        }
    }
    
    @discardableResult
    private static func insert(into moc: NSManagedObjectContext, customAppeal: Int64, supportAppeal: Int64, usesCustomAppeal: Bool, center: Member, guest: Member, otherMembers: Set<Member>) -> Unit {
        let unit: Unit = moc.insertObject()
        unit.customAppeal = customAppeal
        unit.supportAppeal = supportAppeal
        unit.usesCustomAppeal = usesCustomAppeal
        unit.center = center
        unit.guest = guest
        unit.otherMembers = otherMembers
        return unit
    }
    
    @discardableResult
    static func insert(into moc: NSManagedObjectContext, customAppeal: Int = 0, supportAppeal: Int = CGSSGlobal.defaultSupportAppeal, usesCustomAppeal: Bool = false, center: Member, guest: Member, otherMembers: [Member]) -> Unit {
        otherMembers.forEach {
            $0.participatedPosition = Int16(otherMembers.index(of: $0)!) + 1
        }
        return insert(into: moc, customAppeal: Int64(customAppeal), supportAppeal: Int64(supportAppeal), usesCustomAppeal: usesCustomAppeal, center: center, guest: guest, otherMembers: Set(otherMembers))
    }
    
    @discardableResult
    static func insert(into moc: NSManagedObjectContext, anotherUnit: Unit) -> Unit {
        return insert(into: moc, customAppeal: anotherUnit.customAppeal, supportAppeal: anotherUnit.supportAppeal, usesCustomAppeal: anotherUnit.usesCustomAppeal, center: Member.insert(into: moc, anotherMember: anotherUnit.center), guest: Member.insert(into: moc, anotherMember: anotherUnit.guest), otherMembers: Set(anotherUnit.otherMembers.map {
            return Member.insert(into: moc, anotherMember: $0)
        }))
    }
    
}

extension Unit: Managed {
    
    public static var entityName: String {
        return "Unit"
    }
    
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(key: #keyPath(updatedAt), ascending: false)]
    }
    
    public static var defaultPredicate: NSPredicate {
        return notMarkedForDeletionPredicate
    }
    
}

extension Unit: RemoteModifiable {
    @NSManaged public var markedForLocalChange: Bool
}

extension Unit {}

extension Unit: UpdateTimestampable {}

extension Unit: DelayedDeletable {
    @NSManaged public var markedForDeletionDate: Date?
}

extension Unit: RemoteDeletable {
    @NSManaged public var markedForRemoteDeletion: Bool
    @NSManaged public var remoteIdentifier: String?
}

extension Unit: UserOwnable {
    @NSManaged public var creatorID: String?
}

extension Unit: RemoteUploadable {
    public func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: RemoteMember.recordType)
        record["customAppeal"] = customAppeal as CKRecordValue
        record["supportAppeal"] = supportAppeal as CKRecordValue
        record["usesCustomAppeal"] = (usesCustomAppeal ? 1 : 0) as CKRecordValue
        record["localCreatedAt"] = createdAt as CKRecordValue
        record["localModifiedAt"] = updatedAt as CKRecordValue
        return record
    }
}

extension Unit {
    
    @discardableResult
    static func insert(into moc: NSManagedObjectContext, team: CGSSTeam) -> Unit {
        let center = Member.insert(into: moc, cardID: team.leader.id!, skillLevel: team.leader.skillLevel!, potential: team.leader.potential)
        let guest = Member.insert(into: moc, cardID: team.friendLeader.id!, skillLevel: team.friendLeader.skillLevel!, potential: team.friendLeader.potential)
        var otherMembers = [Member]()
        for sub in team.subs {
            let member = Member.insert(into: moc, cardID: sub.id!, skillLevel: sub.skillLevel!, potential: sub.potential)
            otherMembers.append(member)
        }
        
        return Unit.insert(into: moc, customAppeal: team.customAppeal, supportAppeal: team.supportAppeal, usesCustomAppeal: team.usingCustomAppeal, center: center, guest: guest, otherMembers: otherMembers)
    }
    
}

extension Unit {
    
    var leader: Member {
        return center
    }
    
    var friendLeader: Member {
        return guest
    }
    
    var subs: [Member] {
        return otherMembers.sorted { $0.participatedPosition < $1.participatedPosition }
    }
    
    var members: [Member] {
        var result = [Member]()
        result.append(leader)
        result.append(contentsOf: subs)
        result.append(friendLeader)
        return result
    }
    
    var skills: [CGSSRankedSkill] {
        var arr = [CGSSRankedSkill]()
        for i in 0...4 {
            if let skill = self[i].card?.skill {
                let level = Int(self[i].skillLevel)
                let rankedSkill = CGSSRankedSkill(level: level, skill: skill)
                arr.append(rankedSkill)
            }
        }
        return arr
    }
    
    subscript (index: Int) -> Member {
        switch index {
        case 0:
            return leader
        case 1...4:
            return subs[index - 1]
        case 5:
            return guest
        default:
            fatalError("index out of range")
        }
    }
    
    subscript (range: CountableClosedRange<Int>) -> ArraySlice<Member> {
        var arraySlice = ArraySlice<Member>()
        for index in range.lowerBound...range.upperBound {
            arraySlice.insert(self[index], at: index)
        }
        return arraySlice
    }
    
    func hasUnknownSkills() -> Bool {
        for i in 0...5 {
            if let type = self[i].card?.skillType, type == .unknown {
                return true
            }
        }
        return false
    }
    
    // 队伍原始值
    var rawAppeal: CGSSAppeal {
        var appeal = rawAppealInGroove
        let member = self[5]
        guard let card = member.card else {
            return appeal
        }
        appeal += card.appeal.addBy(potential: member.potential, rarity: card.rarityType)
        return appeal
    }
    
    var rawAppealInGroove: CGSSAppeal {
        var appeal = CGSSAppeal.zero
        for i in 0...4 {
            guard let card = self[i].card else {
                fatalError()
            }
            appeal += card.appeal.addBy(potential: self[i].potential, rarity: card.rarityType)
        }
        return appeal
    }
    
    private func getAppeal(_ type: CGSSCardTypes) -> CGSSAppeal {
        var appeal = CGSSAppeal.zero
        let contents = getUpContent()
        for i in 0...5 {
            guard let card = self[i].card else {
                fatalError()
            }
            appeal += card.getAppealBy(liveType: type, contents: contents, potential: self[i].potential)
        }
        return appeal
    }
    
    private func getAppealInGroove(_ type: CGSSCardTypes, burstType: LeaderSkillUpType) -> CGSSAppeal {
        var appeal = CGSSAppeal.zero
        let contents = getUpContentInGroove(by: burstType)
        for i in 0...4 {
            guard let card = self[i].card else {
                fatalError()
            }
            appeal += card.getAppealBy(liveType: type, contents: contents, potential: self[i].potential)
        }
        return appeal
    }
    
    private func getAppealInParade(_ type: CGSSLiveTypes) -> CGSSAppeal {
        var appeal = CGSSAppeal.zero
        let contents = getUpContentInParade()
        for i in 0...4 {
            guard let card = self[i].card else {
                fatalError()
            }
            appeal += card.getAppealBy(liveType: type, contents: contents, potential: self[i].potential)
        }
        return appeal
    }
    
    func getAppealBy(simulatorType: CGSSLiveSimulatorType, liveType: CGSSLiveTypes) -> CGSSAppeal {
        switch simulatorType {
        case .normal:
            return getAppeal(liveType)
        case .visual, .dance, .vocal:
            return getAppealInGroove(liveType, burstType: LeaderSkillUpType.init(simulatorType: simulatorType)!)
        case .parade:
            return getAppealInParade(liveType)
        }
    }
    
    func getLeaderSkillUpContentBy(simulatorType: CGSSLiveSimulatorType) -> [CGSSCardTypes: [LeaderSkillUpType: Int]] {
        switch simulatorType {
        case .normal:
            return getUpContent()
        case .parade:
            return getUpContentInParade()
        case .vocal, .dance, .visual:
            return getUpContentInGroove(by: LeaderSkillUpType.init(simulatorType: simulatorType)!)
        }
    }
    
    // 判断需要的指定颜色的队员是否满足条件
    private func hasType(_ type: CGSSCardTypes, count: Int, isInGrooveOrParade: Bool) -> Bool {
        if count == 0 {
            return true
        }
        
        var c = 0
        for i in 0...(isInGrooveOrParade ? 4 : 5) {
            guard let card = self[i].card else {
                fatalError()
            }
            if card.cardType == type {
                c += 1
            }
        }
        
        // 对于deep系列的技能 当在groove或parade中 要求队员数量降低为5
        if count == 6 && isInGrooveOrParade {
            return c >= 5
        } else {
            return c >= count
        }
    }
    
    private func getContentFor(_ leaderSkill: CGSSLeaderSkill, isInGrooveOrParade: Bool) -> [LeaderSkillUpContent] {
        var contents = [LeaderSkillUpContent]()
        if hasType(.cute, count: leaderSkill.needCute, isInGrooveOrParade: isInGrooveOrParade) && hasType(.cool, count: leaderSkill.needCool, isInGrooveOrParade: isInGrooveOrParade) && hasType(.passion, count: leaderSkill.needPassion, isInGrooveOrParade: isInGrooveOrParade) {
            switch leaderSkill.targetAttribute! {
            case "cute":
                for upType in getUpType(leaderSkill) {
                    let content = LeaderSkillUpContent.init(upType: upType, upTarget: .cute, upValue: leaderSkill.upValue!)
                    contents.append(content)
                }
            case "cool":
                for upType in getUpType(leaderSkill) {
                    let content = LeaderSkillUpContent.init(upType: upType, upTarget: .cool, upValue: leaderSkill.upValue!)
                    contents.append(content)
                }
            case "passion":
                for upType in getUpType(leaderSkill) {
                    let content = LeaderSkillUpContent.init(upType: upType, upTarget: .passion, upValue: leaderSkill.upValue!)
                    contents.append(content)
                }
            case "all":
                for upType in getUpType(leaderSkill) {
                    let content1 = LeaderSkillUpContent.init(upType: upType, upTarget: .cute, upValue: leaderSkill.upValue!)
                    contents.append(content1)
                    let content2 = LeaderSkillUpContent.init(upType: upType, upTarget: .cool, upValue: leaderSkill.upValue!)
                    contents.append(content2)
                    let content3 = LeaderSkillUpContent.init(upType: upType, upTarget: .passion, upValue: leaderSkill.upValue!)
                    contents.append(content3)
                }
            default:
                break
            }
            
        }
        return contents
    }
    
    // 获取队长技能对队伍的加成效果
    private func getUpContent() -> [CGSSCardTypes: [LeaderSkillUpType: Int]] {
        var contents = [LeaderSkillUpContent]()
        // 自己的队长技能
        if let leaderSkill = leader.card?.leaderSkill {
            contents.append(contentsOf: getContentFor(leaderSkill, isInGrooveOrParade: false))
        }
        // 队友的队长技能
        if let leaderSkill = friendLeader.card?.leaderSkill {
            contents.append(contentsOf: getContentFor(leaderSkill, isInGrooveOrParade: false))
        }
        
        // 合并同类型
        var newContents = [CGSSCardTypes: [LeaderSkillUpType: Int]]()
        for content in contents {
            if newContents.keys.contains(content.upTarget) {
                if newContents[content.upTarget]!.keys.contains(content.upType) {
                    newContents[content.upTarget]![content.upType]! += content.upValue
                } else {
                    newContents[content.upTarget]![content.upType] = content.upValue
                }
            } else {
                newContents[content.upTarget] = [LeaderSkillUpType: Int]()
                newContents[content.upTarget]![content.upType] = content.upValue
            }
            
        }
        return newContents
    }
    
    private func getUpContentInGroove(by burstType: LeaderSkillUpType) -> [CGSSCardTypes: [LeaderSkillUpType: Int]] {
        var contents = [LeaderSkillUpContent]()
        // 自己的队长技能
        if let leaderSkill = leader.card?.leaderSkill {
            contents.append(contentsOf: getContentFor(leaderSkill, isInGrooveOrParade: true))
        }
        // 设定Groove中的up值
        contents.append(LeaderSkillUpContent.init(upType: burstType, upTarget: .cool, upValue: 150))
        contents.append(LeaderSkillUpContent.init(upType: burstType, upTarget: .cute, upValue: 150))
        contents.append(LeaderSkillUpContent.init(upType: burstType, upTarget: .passion, upValue: 150))
        
        // 合并同类型
        var newContents = [CGSSCardTypes: [LeaderSkillUpType: Int]]()
        for content in contents {
            if newContents.keys.contains(content.upTarget) {
                if newContents[content.upTarget]!.keys.contains(content.upType) {
                    newContents[content.upTarget]![content.upType]! += content.upValue
                } else {
                    newContents[content.upTarget]![content.upType] = content.upValue
                }
            } else {
                newContents[content.upTarget] = [LeaderSkillUpType: Int]()
                newContents[content.upTarget]![content.upType] = content.upValue
            }
            
        }
        return newContents
    }
    
    private func getUpContentInParade() -> [CGSSCardTypes: [LeaderSkillUpType: Int]] {
        var contents = [LeaderSkillUpContent]()
        // 自己的队长技能
        if let leaderSkill = leader.card?.leaderSkill {
            contents.append(contentsOf: getContentFor(leaderSkill, isInGrooveOrParade: true))
        }
        var newContents = [CGSSCardTypes: [LeaderSkillUpType: Int]]()
        for content in contents {
            if
                newContents.keys.contains(content.upTarget) {
                newContents[content.upTarget]![content.upType] = content.upValue
            } else {
                newContents[content.upTarget] = [LeaderSkillUpType: Int]()
                newContents[content.upTarget]![content.upType] = content.upValue
            }
        }
        return newContents
    }
    
    func getUpType(_ leaderSkill: CGSSLeaderSkill) -> [LeaderSkillUpType] {
        switch leaderSkill.targetParam! {
        case "vocal":
            return [LeaderSkillUpType.vocal]
        case "dance":
            return [LeaderSkillUpType.dance]
        case "visual":
            return [LeaderSkillUpType.visual]
        case "all":
            return [LeaderSkillUpType.vocal, LeaderSkillUpType.dance, LeaderSkillUpType.visual]
        case "life":
            return [LeaderSkillUpType.life]
        case "skill_probability":
            return [LeaderSkillUpType.proc]
        default:
            return [LeaderSkillUpType]()
        }
    }
    
    func validateMembers() -> Bool {
        return members.count == 6 && members.flatMap { (member) -> CGSSCard? in
           return member.card
        }.count == 6
    }
    
}
