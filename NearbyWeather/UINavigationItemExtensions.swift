//
//  UINavigationItemExtensions.swift
//  NearbyWeather
//
//  Created by Erik Maximilian Martens on 15.01.18.
//  Copyright © 2018 Erik Maximilian Martens. All rights reserved.
//

import UIKit

extension UINavigationItem {
    
    func removeTextFromBackBarButton() {
        let barButton = UIBarButtonItem()
        barButton.title = ""
        self.backBarButtonItem = barButton
    }
    
    func setTitle(_ title: String, andSubtitle subtitle: String) {
        let titleLabelFrame = CGRect(x: 0, y: 0, width: 0, height: 0)
        let titleLabel = UILabel(frame: titleLabelFrame)
        
        titleLabel.textColor = .white
        titleLabel.font = .boldSystemFont(ofSize: 17)
        titleLabel.text = title
        titleLabel.sizeToFit()
        
        let subtitleLabelFrame = CGRect(x: 0, y: 20, width: 0, height: 0)
        let subtitleLabel = UILabel(frame: subtitleLabelFrame)
        
        subtitleLabel.textColor = .white
        subtitleLabel.font = .systemFont(ofSize: 12)
        subtitleLabel.text = subtitle
        subtitleLabel.sizeToFit()
        
        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: max(titleLabel.frame.size.width, subtitleLabel.frame.size.width), height: 30))
        titleView.addSubview(titleLabel)
        titleView.addSubview(subtitleLabel)
        
        titleLabel.center = CGPoint(x: titleView.frame.size.width / 2, y: titleLabel.frame.origin.y)
        subtitleLabel.center = CGPoint(x: titleView.frame.size.width / 2, y: subtitleLabel.frame.origin.y)
        
        self.titleView = titleView
    }
}
