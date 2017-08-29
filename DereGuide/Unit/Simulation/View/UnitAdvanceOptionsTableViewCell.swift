//
//  UnitAdvanceOptionsTableViewCell.swift
//  DereGuide
//
//  Created by zzk on 2017/6/3.
//  Copyright © 2017年 zzk. All rights reserved.
//

import UIKit
import SnapKit

class UnitAdvanceOptionsTableViewCell: UITableViewCell {

    enum OptionStyle {
        case slider(SliderOption)
        case textField(TextFieldOption)
        case `switch`(SwitchOption)
        case stepper(StepperOption)
        case plain
    }
    
    private(set) var optionStyle: OptionStyle = .plain
    
    convenience init(optionStyle: OptionStyle) {
        self.init()
        self.optionStyle = optionStyle
        
        var optionView: UIView
        switch optionStyle {
        case .`switch`(let view):
            optionView = view
        case .textField(let view):
            optionView = view
        case .slider(let view):
            optionView = view
        case .stepper(let view):
            optionView = view
        default:
            optionView = UIView()
        }
        
        contentView.addSubview(optionView)
        optionView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
        }
        
        selectionStyle = .none
    }
    
}