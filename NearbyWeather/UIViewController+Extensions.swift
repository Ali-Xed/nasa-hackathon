

import UIKit
import SafariServices

extension UIViewController {
    
    func presentSafariViewController(for url: URL) {
        let safariController = SFSafariViewController(url: url)
        if #available(iOS 10, *) {
            safariController.preferredControlTintColor = .nearbyWeatherStandard
        } else {
            safariController.view.tintColor = .nearbyWeatherStandard
        }
        safariController.modalPresentationStyle = .overFullScreen
        present(safariController, animated: true, completion: nil)
    }
}
