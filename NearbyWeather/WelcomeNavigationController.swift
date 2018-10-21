

import UIKit

protocol WelcomeNavigationDelegate: class {
    func dismissSplashScreen()
}

class WelcomeNavigationController: UINavigationController {
    
    weak var welcomeNavigationDelegate: WelcomeNavigationDelegate?
}
