//
//  WelcomeScreenViewController.swift
//  NearbyWeather
//
//  Created by Erik Maximilian Martens on 15.04.17.
//  Copyright © 2017 Erik Maximilian Martens. All rights reserved.
//

import UIKit
import SafariServices
import TextFieldCounter

class WelcomeScreenViewController: UIViewController {
    
    // MARK: - Properties
    
    private var timer: Timer?
    
    
    // MARK: - Outlets
    
    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet weak var warningImageView: UIImageView!
    
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var inputTextField: TextFieldCounter!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var getInstructionsButtons: UIButton!
    
    
    // MARK: - Override Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = R.string.localizable.welcome()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configure()
        checkValidTextFieldInput()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        inputTextField.becomeFirstResponder()
        animatePulse()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        warningImageView.layer.removeAllAnimations()
        timer?.invalidate()
    }
    
    // MARK: - Helper Functions
    
    func configure() {
        navigationController?.navigationBar.styleStandard(withBarTintColor: .nearbyWeatherStandard, isTransluscent: false, animated: true) 
        navigationController?.navigationBar.addDropShadow(offSet: CGSize(width: 0, height: 1), radius: 10)
        
        bubbleView.layer.cornerRadius = 10
        bubbleView.backgroundColor = .black
        
        descriptionLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        descriptionLabel.textColor = .white
        descriptionLabel.text! = R.string.localizable.welcome_api_key_description()
        
        inputTextField.counterColor = inputTextField.textColor ?? .black
        inputTextField.limitColor = .nearbyWeatherStandard
        inputTextField.textColor = .lightGray
        inputTextField.tintColor = .lightGray
        
        saveButton.setTitle(R.string.localizable.save().uppercased(), for: .normal)
        saveButton.setTitleColor(.nearbyWeatherStandard, for: .normal)
        saveButton.setTitleColor(.nearbyWeatherStandard, for: .highlighted)
        saveButton.setTitleColor(.lightGray, for: .disabled)
        saveButton.layer.cornerRadius = 5.0
        saveButton.layer.borderColor = UIColor.lightGray.cgColor
        saveButton.layer.borderWidth = 1.0
        
        getInstructionsButtons.setTitle(R.string.localizable.get_api_key_description().uppercased(), for: .normal)
        getInstructionsButtons.setTitleColor(.nearbyWeatherStandard, for: .normal)
        getInstructionsButtons.setTitleColor(.nearbyWeatherStandard, for: .highlighted)
    }
    
    fileprivate func startAnimationTimer() {
        timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: (#selector(WelcomeScreenViewController.animatePulse)), userInfo: nil, repeats: false)
    }
    
    @objc private func animatePulse() {
        warningImageView.layer.removeAllAnimations()
        warningImageView.animatePulse(withAnimationDelegate: self)
    }
    
    
    // MARK: - TextField Interaction
    
    @IBAction func inputTextFieldEditingChanged(_ sender: TextFieldCounter) {
        checkValidTextFieldInput()
        if saveButton.isEnabled {
            saveButton.layer.borderColor = UIColor.nearbyWeatherStandard.cgColor
            return
        }
        saveButton.layer.borderColor = UIColor.lightGray.cgColor
    }
    
    private func checkValidTextFieldInput() {
        guard let text = inputTextField.text,
            text.count == 32 else {
            saveButton.isEnabled = false
            inputTextField.textColor = .lightGray
            return
        }
        saveButton.isEnabled = true
        inputTextField.textColor = .nearbyWeatherStandard
    }
    
    
    // MARK: - Button Interaction
    
    @IBAction func didTapSaveButton(_ sender: UIButton) {
        inputTextField.resignFirstResponder()
        UserDefaults.standard.set(inputTextField.text, forKey: kNearbyWeatherApiKeyKey)
        
        let storyboard = UIStoryboard(name: "Welcome", bundle: nil)
        let destinationViewController = storyboard.instantiateViewController(withIdentifier: "SetPermissionsVC") as! SetPermissionsViewController
        
        navigationController?.pushViewController(destinationViewController, animated: true)
        
    }
    
    @IBAction func didTapGetInstructionsButton(_ sender: UIButton) {
        guard let url = URL(string: "https://openweathermap.org/appid") else {
            return
        }
        presentSafariViewController(for: url)
    }
}

extension WelcomeScreenViewController: CAAnimationDelegate {
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        startAnimationTimer()
    }
}
