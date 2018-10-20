//
//  ButtonCell.swift
//  NearbyWeather
//
//  Created by Erik Maximilian Martens on 12.02.18.
//  Copyright © 2018 Erik Maximilian Martens. All rights reserved.
//

import UIKit

class ButtonCell: UITableViewCell {
    
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    
    private var leftButtonHandler: ((UIButton) -> ())?
    private var rightButtonHandler: ((UIButton) -> ())?
    
    @objc private func leftButtonPressed(_ sender: UIButton) {
        leftButtonHandler?(sender)
    }
    
    @objc private func rightButtonPressed(_ sender: UIButton) {
        rightButtonHandler?(sender)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        leftButtonHandler = nil
        leftButton.removeTarget(self, action: #selector(ButtonCell.leftButtonPressed(_:)), for: .touchUpInside)
        
        rightButtonHandler = nil
        rightButton.removeTarget(self, action: #selector(ButtonCell.rightButtonPressed(_:)), for: .touchUpInside)
    }
    
    public func configure(withTitle title: String, leftButtonTitle: String, rightButtonTitle: String, leftButtonHandler: @escaping ((UIButton) -> ()), rightButtonHandler: @escaping ((UIButton) -> ())) {
        
        contentLabel.text = title
        
        self.rightButtonHandler = rightButtonHandler
        self.leftButtonHandler = leftButtonHandler
        
        leftButton.setTitle(leftButtonTitle, for: .normal)
        leftButton.addTarget(self, action: #selector(ButtonCell.leftButtonPressed(_:)), for: .touchUpInside)
        
        rightButton.setTitle(rightButtonTitle, for: .normal)
        rightButton.addTarget(self, action: #selector(ButtonCell.rightButtonPressed(_:)), for: .touchUpInside)
        
        [rightButton, leftButton].forEach {           
            $0?.layer.cornerRadius = 5.0
            $0?.layer.borderColor = UIColor.nearbyWeatherStandard.cgColor
            $0?.layer.borderWidth = 1.0
        }
    }
}
