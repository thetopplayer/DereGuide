//
//  TeamTableViewCell.swift
//  CGSSGuide
//
//  Created by zzk on 16/7/28.
//  Copyright © 2016年 zzk. All rights reserved.
//

import UIKit

class TeamTableViewCell: UITableViewCell {
    
    var icons: [CGSSCardIconView]!
    var skillLvLabels: [UILabel]!
    var leftSpace: CGFloat = 20
    var rightSpace: CGFloat = 50
    var space: CGFloat = 10
    var rawValueLabels: [UILabel]!
    
    var lifeLabel: UILabel!
    var vocalLabel: UILabel!
    var danceLabel: UILabel!
    var visualLabel: UILabel!
    var totalLabel: UILabel!
    static var btnW: CGFloat = (CGSSGlobal.width - 50 - 20 + 10) / 6 - 10
    override func awakeFromNib() {
        super.awakeFromNib()
        let btnW = (CGSSGlobal.width - rightSpace - leftSpace + space) / 6 - space
        icons = [CGSSCardIconView]()
        skillLvLabels = [UILabel]()
        for index in 0...5 {
            let icon = CGSSCardIconView.init(frame: CGRectMake(leftSpace + (btnW + space) * CGFloat(index), 10, btnW, btnW))
            
            let label = UILabel.init(frame: CGRectMake(icon.frame.origin.x, icon.frame.origin.y + icon.frame.size.height, icon.frame.size.width, 21))
            label.adjustsFontSizeToFitWidth = true
            label.textAlignment = .Center
            label.font = UIFont.systemFontOfSize(12)
            label.textColor = UIColor.darkGrayColor()
            contentView.addSubview(label)
            skillLvLabels.append(label)
            
            contentView.addSubview(icon)
            icons.append(icon)
        }
        let originY = 10 + btnW + 23
        
        let width = (CGSSGlobal.width - leftSpace - rightSpace - 4) / 5
        let fontSize: CGFloat = 12
        let height: CGFloat = 12
        let originX: CGFloat = 20
        
        lifeLabel = UILabel()
        lifeLabel.frame = CGRectMake(originX, originY, width, height)
        lifeLabel.font = UIFont.init(name: "menlo", size: fontSize)
        lifeLabel.textColor = CGSSGlobal.lifeColor
        lifeLabel.textAlignment = .Right
        
        vocalLabel = UILabel()
        vocalLabel.frame = CGRectMake(originX + width, originY, width, height)
        vocalLabel.font = UIFont.init(name: "menlo", size: fontSize)
        vocalLabel.textColor = CGSSGlobal.vocalColor
        vocalLabel.textAlignment = .Right
        
        danceLabel = UILabel()
        danceLabel.frame = CGRectMake(originX + 2 * width, originY, width, height)
        danceLabel.font = UIFont.init(name: "menlo", size: fontSize)
        danceLabel.textColor = CGSSGlobal.danceColor
        danceLabel.textAlignment = .Right
        
        visualLabel = UILabel()
        visualLabel.frame = CGRectMake(originX + 3 * width, originY, width, height)
        visualLabel.font = UIFont.init(name: "menlo", size: fontSize)
        visualLabel.textColor = CGSSGlobal.visualColor
        visualLabel.textAlignment = .Right
        
        totalLabel = UILabel()
        totalLabel.frame = CGRectMake(originX + 4 * width, originY, width, height)
        totalLabel.font = UIFont.init(name: "menlo", size: fontSize)
        totalLabel.textColor = UIColor.darkGrayColor()
        totalLabel.textAlignment = .Right
        
        contentView.addSubview(vocalLabel)
        contentView.addSubview(lifeLabel)
        contentView.addSubview(danceLabel)
        contentView.addSubview(visualLabel)
        contentView.addSubview(totalLabel)
        
        let asView = UIImageView.init(frame: CGRectMake(0, 0, 10, 20))
        asView.image = UIImage.init(named: "766-arrow-right-toolbar-selected")!.imageWithRenderingMode(.AlwaysTemplate)
        asView.tintColor = UIColor.lightGrayColor()
        
        self.accessoryView = asView
        
        // Initialization code
    }
    
    func initWith(team: CGSSTeam) {
        for i in 0...5 {
            let tm = team[i]
            if let card = tm?.cardRef {
                icons[i].setWithCardId(card.id!)
                if i != 5 {
                    if card.skill != nil {
                        skillLvLabels[i].text = "SLv.\((tm?.skillLevel)!)"
                    } else {
                        skillLvLabels[i].text = "n/a"
                    }
                } else {
                    skillLvLabels[i].text = "n/a"
                }
            }
        }
        vocalLabel.text = String(team.rawVocal)
        visualLabel.text = String(team.rawVisual)
        danceLabel.text = String(team.rawDance)
        totalLabel.text = String(team.rawPresentValue.total)
        lifeLabel.text = String(team.rawHP)
    }
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}