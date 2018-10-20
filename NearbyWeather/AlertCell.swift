//
//  AlertCell.swift
//  NearbyWeather
//
//  Created by Erik Maximilian Martens on 14.04.17.
//  Copyright © 2017 Erik Maximilian Martens. All rights reserved.
//

import UIKit

class AlertCell: UITableViewCell {
    
    private var timer: Timer?
    
    @IBOutlet weak var backgroundColorView: UIView!
    @IBOutlet weak var warningImageView: UIView!
    @IBOutlet weak var noticeLabel: UILabel!
    
    deinit {
        warningImageView.layer.removeAllAnimations()
        timer?.invalidate()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        warningImageView.layer.removeAllAnimations()
        timer?.invalidate()
    }
    
    func configureWithErrorDataDTO(_ errorDataDTO: ErrorDataDTO?) {
        backgroundColorView.layer.cornerRadius = 5.0
        backgroundColorView.layer.backgroundColor = UIColor.black.cgColor
        
        if let errorDataDTO = errorDataDTO {
            switch errorDataDTO.errorType.value {
            case .httpError:
                let errorCode = errorDataDTO.httpStatusCode ?? -1
                noticeLabel.text = R.string.localizable.http_error("\(errorCode)")
            case .requestTimOutError:
                noticeLabel.text = R.string.localizable.request_timeout_error()
            case .malformedUrlError:
                noticeLabel.text = R.string.localizable.malformed_url_error()
            case .unparsableResponseError:
                noticeLabel.text = R.string.localizable.unreadable_result_error()
            case .jsonSerializationError:
                noticeLabel.text = R.string.localizable.unreadable_result_error()
            case .unrecognizedApiKeyError:
                noticeLabel.text = R.string.localizable.unauthorized_api_key_error()
            case .locationUnavailableError:
                noticeLabel.text = R.string.localizable.location_unavailable_error()
            case .locationAccessDenied:
               noticeLabel.text =  R.string.localizable.location_denied_error()
            }
        } else {
            noticeLabel.text = R.string.localizable.unknown_error()
        }
        startAnimationTimer()
    }
    
    private func startAnimationTimer() {
        timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(AlertCell.animateWarningShake), userInfo: nil, repeats: false)
    }
    
    @objc private func animateWarningShake() {
        warningImageView.layer.removeAllAnimations()
        warningImageView.animatePulse(withAnimationDelegate: self)
    }
}

extension AlertCell: CAAnimationDelegate {
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        startAnimationTimer()
    }
}
