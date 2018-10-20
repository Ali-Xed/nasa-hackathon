//
//  SettingsInputTableViewController.swift
//  NearbyWeather
//
//  Created by Erik Maximilian Martens on 04.12.16.
//  Copyright © 2016 Erik Maximilian Martens. All rights reserved.
//

import UIKit
import TextFieldCounter
import PKHUD

class SettingsInputTableViewController: UITableViewController {
    
    // MARK: - Assets

    /* Outlets */
    
    @IBOutlet weak var inputTextField: TextFieldCounter!
    
    
    // MARK: - ViewController Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = R.string.localizable.api_settings()
        
        tableView.delegate = self
        inputTextField.delegate = self
        inputTextField.text = UserDefaults.standard.string(forKey: kNearbyWeatherApiKeyKey)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configure()
        
        tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        inputTextField.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        validateAndSave()
    }
    
    
    // MARK: - TableViewDataSource
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return R.string.localizable.enter_api_key()
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return R.string.localizable.api_key_length_description()
    }
    
    
    // MARK: - ScrollViewDelegate
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        inputTextField.resignFirstResponder()
    }
    
    
    // MARK: - Private Helpers
    
    private func configure() {
        navigationController?.navigationBar.styleStandard(withBarTintColor: .nearbyWeatherStandard, isTransluscent: false, animated: true)
        navigationController?.navigationBar.addDropShadow(offSet: CGSize(width: 0, height: 1), radius: 10)
        
        inputTextField.animate = true
        inputTextField.ascending = true
        inputTextField.maxLength = 32
        inputTextField.counterColor = inputTextField.textColor ?? .black
        inputTextField.limitColor = .nearbyWeatherStandard
    }
    
    @discardableResult fileprivate func validateAndSave() -> Bool {
        guard let text = inputTextField.text, text.count == 32  else {
            return false
        }
        
        inputTextField.resignFirstResponder()
        
        if let currentApiKey = UserDefaults.standard.string(forKey: kNearbyWeatherApiKeyKey), text == currentApiKey {
            return true // saving is unnecessary as there was no change
        }
        UserDefaults.standard.set(text, forKey: kNearbyWeatherApiKeyKey)
        HUD.flash(.success, delay: 1.0)
        WeatherDataManager.shared.update(withCompletionHandler: nil)
        return true
    }
}

extension SettingsInputTableViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        navigationController?.popViewController(animated: true)
        return validateAndSave()
    }
}
