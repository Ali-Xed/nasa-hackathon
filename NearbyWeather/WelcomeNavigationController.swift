//
//  WelcomeNavigationController.swift
//  NearbyWeather
//
//  Created by Erik Maximilian Martens on 15.07.18.
//  Copyright © 2018 Erik Maximilian Martens. All rights reserved.
//

import UIKit

protocol WelcomeNavigationDelegate: class {
    func dismissSplashScreen()
}

class WelcomeNavigationController: UINavigationController {
    
    weak var welcomeNavigationDelegate: WelcomeNavigationDelegate?
}
