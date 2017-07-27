//
//  CardImageController.swift
//  CGSSGuide
//
//  Created by zzk on 2017/1/22.
//  Copyright © 2017年 zzk. All rights reserved.
//

import UIKit

class CardImageController: BaseViewController {
    
    var card: CGSSCard!
    
    var imageView: BannerView!
    
    var item: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView = BannerView()
        view.addSubview(imageView)
        
        imageView.snp.makeConstraints { (make) in
            make.width.lessThanOrEqualToSuperview()
            make.top.greaterThanOrEqualTo(topLayoutGuide.snp.bottom)
            make.bottom.lessThanOrEqualTo(bottomLayoutGuide.snp.top)
            make.height.equalTo(imageView.snp.width).multipliedBy(340.0 / 272.0)
            make.center.equalToSuperview()
        }
        
        imageView.style = .custom
        
        prepareToolbar()
        if let url = URL.init(string: card.cardImageRef) {
            imageView.sd_setImage(with: url, completed: { (image, error, cache, url) in
                self.item.isEnabled = true
            })
        }
    }
    
    func prepareToolbar() {
        item = UIBarButtonItem.init(image: #imageLiteral(resourceName: "702-share-toolbar"), style: .plain, target: self, action: #selector(shareAction(item:)))
        item.isEnabled = false
        toolbarItems = [item]
    }
    
    @objc func shareAction(item: UIBarButtonItem) {
        if imageView.image == nil {
            return
        }
        let urlArray = [imageView.image!]
        let activityVC = UIActivityViewController.init(activityItems: urlArray, applicationActivities: nil)
        activityVC.popoverPresentationController?.barButtonItem = item
        //activityVC.popoverPresentationController?.sourceRect = CGRect(x: item.width / 2, y: 0, width: 0, height: 0)
        // 需要屏蔽的模块
        let cludeActivitys:[UIActivityType] = []
        // 排除活动类型
        activityVC.excludedActivityTypes = cludeActivitys
        
        // 呈现分享界面
        self.present(activityVC, animated: true, completion: nil)
    }
}
