//
//  InfoTableViewController.swift
//  NearbyWeather
//
//  Created by Erik Maximilian Martens on 16.04.17.
//  Copyright © 2017 Erik Maximilian Martens. All rights reserved.
//

import UIKit
import SafariServices
import MessageUI

class InfoTableViewController: UITableViewController {
    
    struct CocoaPodMeta { var name: String; var urlString: String }
    private static let cocoaPods: [CocoaPodMeta] = [CocoaPodMeta(name: "Alamofire", urlString: "https://github.com/Alamofire/Alamofire"),
                                                    CocoaPodMeta(name: "APTimeZones", urlString: "https://github.com/Alterplay/APTimeZones"),
                                                    CocoaPodMeta(name: "FMDB", urlString: "https://github.com/ccgus/fmdb"),
                                                    CocoaPodMeta(name: "PKHUD", urlString: "https://github.com/pkluz/PKHUD"),
                                                    CocoaPodMeta(name: "RainyRefreshControl", urlString: "https://github.com/Onix-Systems/RainyRefreshControl"),
                                                    CocoaPodMeta(name: "R.swift", urlString: "https://github.com/mac-cain13/R.swift"),
                                                    CocoaPodMeta(name: "TextFieldCounter", urlString: "https://github.com/serralvo/TextFieldCounter")]
    
    struct Contributor { var name: String; var subtitle: String }
    private static let contributors: [Contributor] = [Contributor(name: "Erik Maximilian Martens", subtitle: R.string.localizable.project_owner())]
    
    //MARK: - Assets
    
    @IBOutlet weak var appTitleLabel: UILabel!
    @IBOutlet weak var appVersionLabel: UILabel!

    
    
    //MARK: - ViewController Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = R.string.localizable.about()
        
        tableView.delegate = self
        tableView.estimatedRowHeight = 44
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configure()
        tableView.reloadData() // in case of preferred content size change
    }
    
    
    // MARK: - TableView Delegate
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        var urlStringValue: String?
        if indexPath.section == 0 && indexPath.row == 0 {
            let urlString = "https://itunes.apple.com/app/id1227313069?action=write-review&mt=8"
            UIApplication.shared.openURL(URL(string: urlString)!)
            return
        }
        if indexPath.section == 0 && indexPath.row == 1 {
            return
        }
        if indexPath.section == 1 && indexPath.row == 0 {
            urlStringValue = "http://www.erikmartens.de/contact.html"
        }
        if indexPath.section == 2 && indexPath.row == 0 {
            urlStringValue = "https://github.com/erikmartens/NearbyWeather/blob/master/CONTRIBUTING.md"
        }
        if indexPath.section == 2 && indexPath.row == 1 {
            urlStringValue = "https://github.com/erikmartens/NearbyWeather"
        }
        if indexPath.section == 3 {
            urlStringValue = InfoTableViewController.cocoaPods[indexPath.row].urlString
        }
        if indexPath.section == 4 && indexPath.row == 0 {
            urlStringValue = "https://www.icons8.com"
        }
        guard let urlString = urlStringValue, let url = URL(string: urlString) else {
            return
        }
        presentSafariViewController(for: url)
    }
    
    
    // MARK: - TableView Data Source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 2
        case 1:
            return 1
        case 2:
            return 2
        case 3:
            return InfoTableViewController.cocoaPods.count
        case 4:
            return 1
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return R.string.localizable.resources()
        case 1:
            return R.string.localizable.contributors()
        case 2:
            return nil
        case 3:
            return R.string.localizable.libraries()
        case 4:
            return R.string.localizable.icons()
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let labelCell = tableView.dequeueReusableCell(withIdentifier: "LabelCell", for: indexPath) as! LabelCell
        let subtitleCell = tableView.dequeueReusableCell(withIdentifier: "SubtitleCell", for: indexPath) as! SubtitleCell
        let buttonCell = tableView.dequeueReusableCell(withIdentifier: "ButtonCell", for: indexPath) as! ButtonCell
        
        [labelCell, subtitleCell].forEach {
            $0.selectionStyle = .default
            $0.accessoryType = .disclosureIndicator
        }
        buttonCell.selectionStyle = .none
        buttonCell.accessoryType = .none
        
        switch indexPath.section {
        case 0:
            if indexPath.row == 0 {
                labelCell.contentLabel.text = R.string.localizable.rate_version()
                return labelCell
            } else {
                buttonCell.configure(withTitle: R.string.localizable.report_issue(),
                                     leftButtonTitle: R.string.localizable.viaGitHub(),
                                     rightButtonTitle: R.string.localizable.viaEmail(),
                                     leftButtonHandler: { [unowned self] button in
                                        guard let url = URL(string: "https://github.com/erikmartens/NearbyWeather/issues") else {
                                            return
                                        }
                                        DispatchQueue.main.async {
                                            self.presentSafariViewController(for: url)
                                        }
                },
                                     rightButtonHandler: { [unowned self] button in
                                        let mailAddress = "erikmartens.developer@gmail.com"
                                        let subject = "NearbyWeather - \(R.string.localizable.report_issue())"
                                        let message = "Hey Erik, \n"
                                        self.sendMail(to: [mailAddress], withSubject: subject, withMessage: message)
                })
                return buttonCell
            }
        case 1:
            let contributor = InfoTableViewController.contributors[indexPath.row]
            subtitleCell.contentLabel.text = contributor.name
            subtitleCell.subtitleLabel.text = contributor.subtitle
            return subtitleCell
        case 2:
            if indexPath.row == 0 {
                labelCell.contentLabel.text = R.string.localizable.how_to_contribute()
                return labelCell
            } else {
                labelCell.contentLabel.text = R.string.localizable.source_code_via_github()
                return labelCell
            }
        case 3:
            let pod = InfoTableViewController.cocoaPods[indexPath.row]
            labelCell.contentLabel.text = pod.name
            return labelCell
        case 4:
            labelCell.contentLabel.text = "Icons8"
            return labelCell
        default:
            return UITableViewCell()
        }
    }

    
    // MARK: - Private Helpers
    
    private func configure() {
        navigationController?.navigationBar.styleStandard(withBarTintColor: .nearbyWeatherStandard, isTransluscent: false, animated: true)
        navigationController?.navigationBar.addDropShadow(offSet: CGSize(width: 0, height: 1), radius: 10)
        configureText()
    }
    
    private func configureText() {
        appTitleLabel.text = R.string.localizable.app_title()
        
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "#UNDEFINED"
        let appBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "#UNDEFINED"
        appVersionLabel.text = "Version \(appVersion) Build #\(appBuild)"
    }
    
    private func sendMail(to recipients: [String], withSubject subject: String, withMessage message: String) {
        guard MFMailComposeViewController.canSendMail() else {
            return
        }
        
        let mailController = MFMailComposeViewController()
        mailController.mailComposeDelegate = self
        
        mailController.setToRecipients(recipients)
        mailController.setSubject(subject)
        mailController.setMessageBody(message, isHTML: false)
        
        navigationController?.present(mailController, animated: true, completion: nil)
    }
}

extension InfoTableViewController: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
