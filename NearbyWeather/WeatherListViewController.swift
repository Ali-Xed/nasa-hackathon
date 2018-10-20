//
//  WeatherListViewController.swift
//  NearbyWeather
//
//  Created by Erik Maximilian Martens on 20.10.17.
//  Copyright © 2017 Erik Maximilian Martens. All rights reserved.
//

import UIKit
import MapKit
import RainyRefreshControl

enum ListType {
    case bookmarked
    case nearby
    
    static let cases: [ListType] = [.bookmarked, .nearby]
    static let titles: [ListType: String] = [.bookmarked: R.string.localizable.bookmarked(),
                                             .nearby: R.string.localizable.nearby()]
}

class WeatherListViewController: UIViewController {
    
    // MARK: - Properties
    
    private var refreshControl = RainyRefreshControl()
    
    private var listType: ListType = .bookmarked
    
    
    // MARK: - Outlets
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var separatoLineViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var refreshDateLabel: UILabel!
    
    @IBOutlet weak var emptyListOverlayContainerView: UIView!
    @IBOutlet weak var emptyListImageView: UIImageView!
    @IBOutlet weak var emptyListTitleLabel: UILabel!
    @IBOutlet weak var emptyListDescriptionLabel: UILabel!
    
    @IBOutlet weak var reloadButton: UIButton!
    
    
    // MARK: - ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configure()
        tableView.reloadData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(WeatherListViewController.reconfigureOnWeatherDataServiceDidUpdate), name: Notification.Name(rawValue: kWeatherServiceDidUpdate), object: nil)
        
        if !WeatherDataManager.shared.hasDisplayableData {
            NotificationCenter.default.addObserver(self, selector: #selector(WeatherListViewController.reconfigureOnNetworkDidBecomeAvailable), name: Notification.Name(rawValue: kNetworkReachabilityChanged), object: nil)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if UserDefaults.standard.value(forKey: kIsInitialLaunch) == nil {
            UserDefaults.standard.set(false, forKey: kIsInitialLaunch)
            updateWeatherData()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        refreshControl.endRefreshing()
        
        NotificationCenter.default.removeObserver(self)
    }
    
    
    // MARK: - Private Helpers
    
    private func configure() {
        navigationItem.title = navigationItem.title?.capitalized
        
        navigationController?.navigationBar.styleStandard(withBarTintColor: .nearbyWeatherStandard, isTransluscent: false, animated: true)
        navigationController?.navigationBar.addDropShadow(offSet: CGSize(width: 0, height: 1), radius: 10)
        
        configureLastRefreshDate()
        configureButtons()
        configureWeatherDataUnavailableElements()
        
        refreshControl.addTarget(self, action: #selector(WeatherListViewController.updateWeatherData), for: .valueChanged)
        tableView.addSubview(refreshControl)
        tableView.isHidden = !WeatherDataManager.shared.hasDisplayableData
        
        emptyListOverlayContainerView.isHidden = WeatherDataManager.shared.hasDisplayableData
        
        separatoLineViewHeightConstraint.constant = 1/UIScreen.main.scale
    }                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
    
    @objc private func reconfigureOnWeatherDataServiceDidUpdate() {
        configureLastRefreshDate()
        configureButtons()
        tableView.isHidden = !WeatherDataManager.shared.hasDisplayableData
        tableView.reloadData()
    }
    
    @objc private func reconfigureOnNetworkDidBecomeAvailable() {
        UIView.animate(withDuration: 0.5) {
            self.reloadButton.isHidden = NetworkingService.shared.reachabilityStatus != .connected
        }
    }
    
    private func configureWeatherDataUnavailableElements() {
        emptyListImageView.tintColor = .lightGray
        emptyListTitleLabel.text = R.string.localizable.no_weather_data()
        emptyListDescriptionLabel.text = R.string.localizable.no_data_description()
    }
    
    private func configureLastRefreshDate() {
        if let lastRefreshDate = UserDefaults.standard.object(forKey: kWeatherDataLastRefreshDateKey) as? Date {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            let dateString = dateFormatter.string(from: lastRefreshDate)
            let title = R.string.localizable.last_refresh_at(dateString)
            refreshDateLabel.text = title
            refreshDateLabel.isHidden = false
        } else {
            refreshDateLabel.isHidden = true
        }
    }
    
    private func configureButtons() {
        reloadButton.isHidden = NetworkingService.shared.reachabilityStatus != .connected
        if !reloadButton.isHidden {
            reloadButton.setTitle(R.string.localizable.reload().uppercased(), for: .normal)
            reloadButton.setTitleColor(.nearbyWeatherStandard, for: .normal)
            reloadButton.layer.cornerRadius = 5.0
            reloadButton.layer.borderColor = UIColor.nearbyWeatherStandard.cgColor
            reloadButton.layer.borderWidth = 1.0
        }
        if WeatherDataManager.shared.hasDisplayableData {
            navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "swap"), style: .plain, target: self, action: #selector(WeatherListViewController.listTypeBarButtonTapped(_:)))
        } else {
            navigationItem.leftBarButtonItem = nil
        }
    }
    
    @objc private func updateWeatherData() {
        refreshControl.beginRefreshing()
        WeatherDataManager.shared.update(withCompletionHandler: {
            DispatchQueue.main.async {
                self.refreshControl.endRefreshing()
                self.configureButtons()
                self.tableView.reloadData()
            }
        })
    }
    
    @objc private func reloadTableView(_ notification: Notification) {
        tableView.reloadData()
    }
    
    
    // MARK: - Button Interaction
    
    @objc private func listTypeBarButtonTapped(_ sender: UIBarButtonItem) {
        triggerListTypeAlert()
    }

    @IBAction func didTapReloadButton(_ sender: UIButton) {
        updateWeatherData()
    }
    
    @IBAction func openWeatherMapButtonPressed(_ sender: UIButton) {
        guard let url = URL(string: "https://openweathermap.org") else {
            return
        }
        presentSafariViewController(for: url)
    }
    
    // MARK: - Helpers
    
    private func triggerListTypeAlert() {
        let optionsAlert = UIAlertController(title: R.string.localizable.select_list_type().capitalized, message: nil, preferredStyle: .alert)
        
        ListType.cases.forEach { listTypeCase in
            let action = UIAlertAction(title: ListType.titles[listTypeCase], style: .default, handler: { _ in
                self.listType = listTypeCase
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            })
            if listTypeCase == self.listType {
                action.setValue(true, forKey: "checked")
            }
            optionsAlert.addAction(action)
        }
        let cancelAction = UIAlertAction(title: R.string.localizable.cancel(), style: .cancel, handler: nil)
        optionsAlert.addAction(cancelAction)
        
        present(optionsAlert, animated: true, completion: nil)
    }
}

extension WeatherListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(100)
    }
}

extension WeatherListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
       return nil
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if !WeatherDataManager.shared.hasDisplayableData {
            return 0
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !WeatherDataManager.shared.hasDisplayableData {
            return 0
        }
        if WeatherDataManager.shared.apiKeyUnauthorized {
            return 1
        }
        switch listType {
        case .bookmarked:
            if WeatherDataManager.shared.bookmarkedWeatherDataObjects == nil {
                return 0
            }
            return WeatherDataManager.shared.bookmarkedWeatherDataObjects?.count ?? 1
        case .nearby:
            if !LocationService.shared.locationPermissionsGranted {
                return 1
            }
            if WeatherDataManager.shared.nearbyWeatherDataObject == nil {
                return 0
            }
            return WeatherDataManager.shared.nearbyWeatherDataObject?.weatherInformationDTOs?.count ?? 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let weatherCell = tableView.dequeueReusableCell(withIdentifier: "WeatherDataCell", for: indexPath) as! WeatherDataCell
        let alertCell = tableView.dequeueReusableCell(withIdentifier: "AlertCell", for: indexPath) as! AlertCell
        
        [weatherCell, alertCell].forEach {
            $0.backgroundColor = .clear
            $0.selectionStyle = .none
        }
        
        if WeatherDataManager.shared.apiKeyUnauthorized {
            let errorDataDTO = (WeatherDataManager.shared.bookmarkedWeatherDataObjects?.first { $0.errorDataDTO != nil})?.errorDataDTO ?? WeatherDataManager.shared.nearbyWeatherDataObject?.errorDataDTO
            alertCell.configureWithErrorDataDTO(errorDataDTO)
            return alertCell
        }
        
        switch listType {
        case .bookmarked:
            guard let weatherDTO = WeatherDataManager.shared.bookmarkedWeatherDataObjects?[indexPath.row].weatherInformationDTO else {
                    alertCell.configureWithErrorDataDTO(WeatherDataManager.shared.bookmarkedWeatherDataObjects?[indexPath.row].errorDataDTO)
                    return alertCell
            }
            weatherCell.configureWithWeatherDTO(weatherDTO)
            return weatherCell
        case .nearby:
            if !LocationService.shared.locationPermissionsGranted {
                let errorDataDTO = ErrorDataDTO(errorType: ErrorType(value: .locationAccessDenied), httpStatusCode: nil)
                alertCell.configureWithErrorDataDTO(errorDataDTO)
                return alertCell
            }
            guard let weatherDTO = WeatherDataManager.shared.nearbyWeatherDataObject?.weatherInformationDTOs?[indexPath.row] else {
                alertCell.configureWithErrorDataDTO(WeatherDataManager.shared.nearbyWeatherDataObject?.errorDataDTO)
                return alertCell
            }
            weatherCell.configureWithWeatherDTO(weatherDTO)
            return weatherCell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let selectedCell = tableView.cellForRow(at: indexPath) as? WeatherDataCell,
            let weatherDataIdentifier = selectedCell.weatherDataIdentifier else {
                return
        }
        guard let weatherDTO = WeatherDataManager.shared.weatherDTO(forIdentifier: weatherDataIdentifier) else {
            return
        }
        let destinationViewController = WeatherDetailViewController.instantiateFromStoryBoard(withTitle: weatherDTO.cityName, weatherDTO: weatherDTO)
        let destinationNavigationController = UINavigationController(rootViewController: destinationViewController)
        destinationNavigationController.addVerticalCloseButton(withCompletionHandler: nil)
        navigationController?.present(destinationNavigationController, animated: true, completion: nil)
    }
}
