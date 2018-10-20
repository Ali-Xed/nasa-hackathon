//
//  OWMCityFilterTableViewController.swift
//  NearbyWeather
//
//  Created by Erik Maximilian Martens on 07.01.18.
//  Copyright © 2018 Erik Maximilian Martens. All rights reserved.
//

import UIKit
import PKHUD

class WeatherLocationSelectionTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    private let searchController = UISearchController(searchResultsController: nil)
    private var filteredCities = [WeatherStationDTO]()
    
    
    // MARK: - ViewController Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = R.string.localizable.add_location()
        
        tableView.delegate = self
        searchController.delegate = self
        
        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = R.string.localizable.search_by_name()
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false
        tableView.tableHeaderView = searchController.searchBar
        definesPresentationContext = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.styleStandard(withBarTintColor: .nearbyWeatherStandard, isTransluscent: false, animated: true)
        navigationController?.navigationBar.addDropShadow(offSet: CGSize(width: 0, height: 1), radius: 10)
        
        tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.main.async {
            self.searchController.searchBar.becomeFirstResponder()
        }
    }
    
    
    // MARK: - TableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredCities.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "OWMCityCell", for: indexPath) as! LocationWeatherDataCell
        cell.contentLabel.text = "\(filteredCities[indexPath.row].name), \(filteredCities[indexPath.row].country)"
        return cell
    }
    
    
    // MARK: - TableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        WeatherDataManager.shared.bookmarkedLocations.append(filteredCities[indexPath.row])
        HUD.flash(.success, delay: 1.0)
        navigationController?.popViewController(animated: true)
    }
    
}

extension WeatherLocationSelectionTableViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else {
            filteredCities = [WeatherStationDTO]()
            tableView.reloadData()
            return
        }
        WeatherLocationService.shared.locations(forSearchString: searchText, completionHandler: { [unowned self] weatherLocationDTOs in
            if let weatherLocationDTOs = weatherLocationDTOs {
                self.filteredCities = weatherLocationDTOs
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        })
    }
}

extension WeatherLocationSelectionTableViewController: UISearchControllerDelegate {
    
    func didDismissSearchController(_ searchController: UISearchController) {
        filteredCities = [WeatherStationDTO]()
        tableView.reloadData()
    }
}
