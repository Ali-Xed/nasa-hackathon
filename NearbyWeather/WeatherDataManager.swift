//
//  Weather.swift
//  NearbyWeather
//
//  Created by Erik Maximilian Martens on 04.12.16.
//  Copyright © 2016 Erik Maximilian Martens. All rights reserved.
//

import Foundation
import MapKit
import Alamofire


/// This value type represents single location data.
/// Each WeatherInformationDTO is fetched indvidually and therefore needs its own
/// associated ErrorDataDTO. This is because each download may fail on it's own
/// while other information may still be representable.
struct WeatherDataContainer: Codable {
    var locationId: Int
    var errorDataDTO: ErrorDataDTO?
    var weatherInformationDTO: WeatherInformationDTO?
}

/// This value type represents bulk location data.
/// It contains multiple WeatherInformationDTOs but only one associated ErrorDataDTO
/// This is because the fetch either succeeds as a whole or not at all.
struct BulkWeatherDataContainer: Codable {
    var errorDataDTO: ErrorDataDTO?
    var weatherInformationDTOs: [WeatherInformationDTO]?
}

let kDefaultBookmarkedLocation = WeatherStationDTO(identifier: 5341145, name: "Cupertino", country: "US", coordinates: Coordinates(latitude: 37.323002, longitude: -122.032181))

fileprivate let kWeatherDataManagerStoredContentsFileName = "WeatherDataManagerStoredContents"

struct WeatherDataManagerStoredContentsWrapper: Codable {
    var bookmarkedLocations: [WeatherStationDTO]
    var bookmarkedWeatherDataObjects: [WeatherDataContainer]?
    var nearbyWeatherDataObject: BulkWeatherDataContainer?
}

class WeatherDataManager {
    
    // MARK: - Public Assets
    
    public static var shared: WeatherDataManager!
    
    public var hasDisplayableData: Bool {
        
        
        return bookmarkedWeatherDataObjects?.first { $0.errorDataDTO != nil } != nil
            || bookmarkedWeatherDataObjects?.first { $0.weatherInformationDTO != nil } != nil
            || nearbyWeatherDataObject?.errorDataDTO != nil
            || nearbyWeatherDataObject?.weatherInformationDTOs != nil
    }
    
    public var hasDisplayableWeatherData: Bool {
        return bookmarkedWeatherDataObjects?.first { $0.weatherInformationDTO != nil } != nil
            || nearbyWeatherDataObject?.weatherInformationDTOs != nil
    }
    
    public var apiKeyUnauthorized: Bool {
        return ((bookmarkedWeatherDataObjects?.first { $0.errorDataDTO?.httpStatusCode == 401 }) != nil)
            || nearbyWeatherDataObject?.errorDataDTO?.httpStatusCode == 401
    }
    
    
    // MARK: - Properties
    
    public var bookmarkedLocations: [WeatherStationDTO] {
        didSet {
            update(withCompletionHandler: nil)
            sortBookmarkedLocationWeatherData()
            WeatherDataManager.storeService()
        }
    }
    public private(set) var bookmarkedWeatherDataObjects: [WeatherDataContainer]?
    public private(set) var nearbyWeatherDataObject: BulkWeatherDataContainer?
    
    private var locationAuthorizationObserver: NSObjectProtocol!
    private var sortingOrientationChangedObserver: NSObjectProtocol!
    
    // MARK: - Initialization
    
    private init(bookmarkedLocations: [WeatherStationDTO]) {
        self.bookmarkedLocations = bookmarkedLocations
        
        locationAuthorizationObserver = NotificationCenter.default.addObserver(forName: Notification.Name.UIApplicationDidBecomeActive, object: nil, queue: nil, using: { [unowned self] notification in
            self.discardLocationBasedWeatherDataIfNeeded()
        })
        sortingOrientationChangedObserver = NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: kSortingOrientationPreferenceChanged), object: nil, queue: nil, using: { [unowned self] notification in
            self.sortNearbyLocationWeatherData()
        })
    }
    
    deinit {
        NotificationCenter.default.removeObserver(locationAuthorizationObserver)
    }
    
    
    // MARK: - Public Properties & Methods
    
    public static func instantiateSharedInstance() {
        shared = WeatherDataManager.loadService() ?? WeatherDataManager(bookmarkedLocations: [kDefaultBookmarkedLocation])
    }
    
    public func update(withCompletionHandler completionHandler: (() -> ())?) {
        let fetchWeatherDataBackgroundQueue = DispatchQueue(label: "de.erikmaximilianmartens.nearbyWeather.fetchWeatherDataQueue", qos: .userInitiated, attributes: [.concurrent], autoreleaseFrequency: .inherit, target: nil)
        
        guard NetworkingService.shared.reachabilityStatus == .connected else {
            completionHandler?()
            return
        }
        
        fetchWeatherDataBackgroundQueue.async {
            let dispatchGroup = DispatchGroup()
            
            var bookmarkednWeatherDataObjects = [WeatherDataContainer]()
            var nearbyWeatherDataObject: BulkWeatherDataContainer?
            
            self.bookmarkedLocations.forEach { location in
                dispatchGroup.enter()
                NetworkingService.shared.fetchWeatherInformationForStation(withIdentifier: location.identifier, completionHandler: { weatherDataContainer in
                    bookmarkednWeatherDataObjects.append(weatherDataContainer)
                    dispatchGroup.leave()
                })
            }
            
            dispatchGroup.enter()
            NetworkingService.shared.fetchBulkWeatherInformation(completionHandler: { weatherData in
                nearbyWeatherDataObject = weatherData
                dispatchGroup.leave()
            })
            
            let waitResult = dispatchGroup.wait(timeout: .now() + 60.0)
            if waitResult == .timedOut {
                completionHandler?() // todo: notify user
                return
            }
            
            // do not publish refresh if not data was loaded
            if bookmarkednWeatherDataObjects.count == 0 && nearbyWeatherDataObject == nil {
                return
            }
            
            // only override previous record if there is any new data
            if bookmarkednWeatherDataObjects.count != 0 {
                self.bookmarkedWeatherDataObjects = bookmarkednWeatherDataObjects
                self.sortBookmarkedLocationWeatherData()
            }
            if nearbyWeatherDataObject != nil {
                self.nearbyWeatherDataObject = nearbyWeatherDataObject
                self.sortNearbyLocationWeatherData()
            }
            
            WeatherDataManager.storeService()
            DispatchQueue.main.async {
                UserDefaults.standard.set(Date(), forKey: kWeatherDataLastRefreshDateKey)
                NotificationCenter.default.post(name: Notification.Name(rawValue: kWeatherServiceDidUpdate), object: self)
                completionHandler?()
            }
        }
    }
    
    public func weatherDTO(forIdentifier identifier: Int) -> WeatherInformationDTO? {
        if let bookmarkedLocationMatch = bookmarkedWeatherDataObjects?.first(where: {
            return $0.weatherInformationDTO?.cityID == identifier
        }), let weatherDTO = bookmarkedLocationMatch.weatherInformationDTO {
            return weatherDTO
        }
        
        if let nearbyLocationMatch = nearbyWeatherDataObject?.weatherInformationDTOs?.first(where: { weatherDTO in
            return weatherDTO.cityID == identifier
        }) {
            return nearbyLocationMatch
        }
        return nil
    }
    
    
    // MARK: - Private Helper Methods
    
    private func sortBookmarkedLocationWeatherData() {
        let result: [WeatherDataContainer]?
        result = bookmarkedWeatherDataObjects?.sorted { weatherDataObject0, weatherDataObject1 in
            guard let correspondingLocation0 = bookmarkedLocations.first(where: { return weatherDataObject0.locationId == $0.identifier }),
                let correspondingLocation1 = bookmarkedLocations.first(where: { return weatherDataObject1.locationId == $0.identifier }),
                let index0 = bookmarkedLocations.index(of: correspondingLocation0),
                let index1 = bookmarkedLocations.index(of: correspondingLocation1) else {
                    return false
            }
            return index0 < index1
        }
        guard let sortedResult = result else { return }
        bookmarkedWeatherDataObjects = sortedResult
    }
    
    private func sortNearbyLocationWeatherData() {
        let result: [WeatherInformationDTO]?
        switch PreferencesManager.shared.sortingOrientation.value {
        case .name:
            result = nearbyWeatherDataObject?.weatherInformationDTOs?.sorted { $0.cityName < $1.cityName }
        case .temperature:
             result = nearbyWeatherDataObject?.weatherInformationDTOs?.sorted { $0.atmosphericInformation.temperatureKelvin > $1.atmosphericInformation.temperatureKelvin }
        case .distance:
            guard LocationService.shared.locationPermissionsGranted,
                let currentLocation = LocationService.shared.currentLocation else {
                    return
            }
            result = nearbyWeatherDataObject?.weatherInformationDTOs?.sorted {
                let weatherLocation1 = CLLocation(latitude: $0.coordinates.latitude, longitude: $0.coordinates.longitude)
                let weatherLocation2 = CLLocation(latitude: $1.coordinates.latitude, longitude: $1.coordinates.longitude)
                return weatherLocation1.distance(from: currentLocation) < weatherLocation2.distance(from: currentLocation)
            }
        }
        guard let sortedResult = result else { return }
        self.nearbyWeatherDataObject?.weatherInformationDTOs = sortedResult
    }
    
    /* NotificationCenter Notifications */
    
    @objc private func discardLocationBasedWeatherDataIfNeeded() {
        if !LocationService.shared.locationPermissionsGranted {
            nearbyWeatherDataObject = nil
            WeatherDataManager.storeService()
            NotificationCenter.default.post(name: Notification.Name(rawValue: kWeatherServiceDidUpdate), object: self)
        }
    }
    
    /* Internal Storage Helpers */
    
    private static func loadService() -> WeatherDataManager? {
        guard let weatherDataManagerStoredContents = DataStorageService.retrieveJson(fromFileWithName: kWeatherDataManagerStoredContentsFileName, andDecodeAsType: WeatherDataManagerStoredContentsWrapper.self, fromStorageLocation: .documents) else {
            return nil
        }
        
        let weatherService = WeatherDataManager(bookmarkedLocations: weatherDataManagerStoredContents.bookmarkedLocations)
        weatherService.bookmarkedWeatherDataObjects = weatherDataManagerStoredContents.bookmarkedWeatherDataObjects
        weatherService.nearbyWeatherDataObject = weatherDataManagerStoredContents.nearbyWeatherDataObject
        
        return weatherService
    }
    
    private static func storeService() {
        let weatherServiceBackgroundQueue = DispatchQueue(label: "de.erikmaximilianmartens.nearbyWeather.weatherDataManagerBackgroundQueue", qos: .utility, attributes: [DispatchQueue.Attributes.concurrent], autoreleaseFrequency: .inherit, target: nil)
        
        let dispatchSemaphore = DispatchSemaphore(value: 1)
        
        dispatchSemaphore.wait()
        weatherServiceBackgroundQueue.async {
            let weatherDataManagerStoredContents = WeatherDataManagerStoredContentsWrapper(bookmarkedLocations: WeatherDataManager.shared.bookmarkedLocations,
                                                                                           bookmarkedWeatherDataObjects: WeatherDataManager.shared.bookmarkedWeatherDataObjects,
                                                                                           nearbyWeatherDataObject: WeatherDataManager.shared.nearbyWeatherDataObject)
            DataStorageService.storeJson(forCodable: weatherDataManagerStoredContents, inFileWithName: kWeatherDataManagerStoredContentsFileName, toStorageLocation: .documents)
            dispatchSemaphore.signal()
        }
    }
}
