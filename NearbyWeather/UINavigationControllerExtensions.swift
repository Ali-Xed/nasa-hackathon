//
//  UINavigationControllerExtensions.swift
//  NearbyWeather
//
//  Created by Erik Maximilian Martens on 22.10.17.
//  Copyright © 2017 Erik Maximilian Martens. All rights reserved.
//

import UIKit

extension UINavigationController {
    
    func addVerticalCloseButton(withCompletionHandler handler: (() -> ())?) {
        let verticalArrow = UIImage(named: "VerticalCloseButton")
        
        let closeButton = UIBarButtonItem(image: verticalArrow, style: .plain) { [unowned self] _ in
            self.topViewController?.view.endEditing(true)
            self.presentingViewController?.dismiss(animated: true) {
                handler?()
            }
        }
        self.viewControllers.first?.navigationItem.leftBarButtonItem = closeButton
    }
}

fileprivate class DynamicTarget {
    let closure: ((UIBarButtonItem)->())
    
    init(closure: @escaping ((UIBarButtonItem)->())) {
        self.closure = closure
    }
    
    @objc func invokeClosure(_ sender: UIBarButtonItem) {
        closure(sender)
    }
}

fileprivate extension UIBarButtonItem {
    convenience init(title: String?, style: UIBarButtonItemStyle, handler: @escaping ((UIBarButtonItem) -> ())) {
        let dynamicTarget = DynamicTarget(closure: handler)
        self.init(title: title, style: style, target: dynamicTarget, action: #selector(DynamicTarget.invokeClosure(_:)))
        objc_setAssociatedObject(self, String(format: "[%d]", arc4random()), dynamicTarget, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    convenience init(image: UIImage?, style: UIBarButtonItemStyle, handler: @escaping ((UIBarButtonItem) -> ())) {
        let dynamicTarget = DynamicTarget(closure: handler)
        self.init(image: image, style: style, target: dynamicTarget, action: #selector(DynamicTarget.invokeClosure(_:)))
        objc_setAssociatedObject(self, String(format: "[%d]", arc4random()), dynamicTarget, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}
