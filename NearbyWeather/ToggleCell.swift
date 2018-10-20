//
//  ToggleCell.swift
//  NearbyWeather
//
//  Created by Erik Maximilian Martens on 03.02.18.
//  Copyright © 2018 Erik Maximilian Martens. All rights reserved.
//

import UIKit

class ToggleCell: UITableViewCell {
    
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var toggle: UISwitch!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        toggleSwitchHandler = nil
    }
    
    var toggleSwitchHandler: ((UISwitch)->())?
    
    @IBAction func didToggleSwitch(_ sender: UISwitch) {
        toggleSwitchHandler?(sender)
    }
}
