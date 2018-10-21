

import UIKit

extension UINavigationBar {
    
    func styleStandard(withBarTintColor barTintColor: UIColor, isTransluscent: Bool, animated: Bool) {
        isTranslucent = isTransluscent
        
        self.barTintColor = barTintColor
        tintColor = .white
        titleTextAttributes = [.foregroundColor: UIColor.white]
        barStyle = .black
    }
}
