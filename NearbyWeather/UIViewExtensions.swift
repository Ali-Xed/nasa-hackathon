//
//  UIViewExtensions.swift
//  NearbyWeather
//
//  Created by Erik Maximilian Martens on 20.10.17.
//  Copyright © 2017 Erik Maximilian Martens. All rights reserved.
//

import UIKit

extension UIView {
    
    func addDropShadow(with color: UIColor = UIColor.black, opacity: Float = 0.75, offSet: CGSize = CGSize(width: -1, height: 1), radius: CGFloat = 1, scale: Bool = true, shouldRasterize: Bool = true) {
        self.layer.masksToBounds = false
        self.layer.shadowColor = color.cgColor
        self.layer.shadowOpacity = opacity
        self.layer.shadowOffset = offSet
        self.layer.shadowRadius = radius
        
        self.layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
        self.layer.shouldRasterize = shouldRasterize
        self.layer.rasterizationScale = scale ? UIScreen.main.scale : 1
    }
    
    func animatePulse(withAnimationDelegate delegate: CAAnimationDelegate) {
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.delegate = delegate
        animation.timingFunction = CAMediaTimingFunction(name:kCAMediaTimingFunctionEaseIn)
        animation.duration = 0.25
        animation.toValue = 1.5
        animation.repeatCount = 2.0
        animation.autoreverses = true
        layer.add(animation, forKey: "pulse")
    }
}
