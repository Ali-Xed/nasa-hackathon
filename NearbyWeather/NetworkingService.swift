//
//  NetworkingService.swift
//  NearbyWeather
//
//  Created by Erik Maximilian Martens on 10.02.18.
//  Copyright © 2018 Erik Maximilian Martens. All rights reserved.
//

import Foundation
import Alamofire

enum ReachabilityStatus {
    case unknown
    case disconnected
    case connected
}

private let kOpenWeatherSingleLocationBaseURL = "http://api.openweathermap.org/data/2.5/weather"
private let kOpenWeatherMultiLocationBaseURL = "http://api.openweathermap.org/data/2.5/find"

class NetworkingService {
    
    // MARK: - Public Assets
    
    public static var shared: NetworkingService!

    
    // MARK: - Properties
    
    private let reachabilityManager: NetworkReachabilityManager?
    public private(set) var reachabilityStatus: ReachabilityStatus
    
    
    // MARK: - Initialization
    
    private init() {
        self.reachabilityManager = NetworkReachabilityManager()
        self.reachabilityStatus = .unknown
        
        beginListeningNetworkReachability()
    }
    
    deinit {
        reachabilityManager?.stopListening()
    }
    
    
    // MARK: - Private Methods
    
    func beginListeningNetworkReachability() {
        reachabilityManager?.listener = { status in
            switch status {
            case .unknown: self.reachabilityStatus = .unknown
            case .notReachable: self.reachabilityStatus = .disconnected
            case .reachable(.ethernetOrWiFi), .reachable(.wwan): self.reachabilityStatus = .connected
            }
            NotificationCenter.default.post(name: Notification.Name(rawValue: kNetworkReachabilityChanged), object: self)
        }
        reachabilityManager?.startListening()
    }
    
    
    // MARK: - Public Methods
    
    public static func instantiateSharedInstance() {
        shared = NetworkingService()
    }
    
    public func fetchWeatherInformationForStation(withIdentifier identifier: Int, completionHandler: @escaping ((WeatherDataContainer) -> ())) {
        let session = URLSession.shared
        
        guard let apiKey = UserDefaults.standard.value(forKey: kNearbyWeatherApiKeyKey),
            let requestURL = URL(string: "\(kOpenWeatherSingleLocationBaseURL)?APPID=\(apiKey)&id=\(identifier)") else {
                let errorDataDTO = ErrorDataDTO(errorType: ErrorType(value: .malformedUrlError), httpStatusCode: nil)
                return completionHandler(WeatherDataContainer(locationId: identifier, errorDataDTO: errorDataDTO, weatherInformationDTO: nil))
        }
        
        let request = URLRequest(url: requestURL)
        let dataTask = session.dataTask(with: request, completionHandler: { data, response, error in
            guard let receivedData = data, let _ = response, error == nil else {
                let errorDataDTO = ErrorDataDTO(errorType: ErrorType(value: .httpError), httpStatusCode: (response as? HTTPURLResponse)?.statusCode)
                return completionHandler(WeatherDataContainer(locationId: identifier, errorDataDTO: errorDataDTO, weatherInformationDTO: nil))
            }
            completionHandler(self.extractWeatherInformation(receivedData, identifier: identifier))
        })
        dataTask.resume()
    }
    
    public func fetchBulkWeatherInformation(completionHandler: @escaping (BulkWeatherDataContainer) -> Void) {
        let session = URLSession.shared
        
        guard let currentLatitude = LocationService.shared.currentLatitude, let currentLongitude = LocationService.shared.currentLongitude else {
            let errorDataDTO = ErrorDataDTO(errorType: ErrorType(value: .locationUnavailableError), httpStatusCode: nil)
            return completionHandler(BulkWeatherDataContainer(errorDataDTO: errorDataDTO, weatherInformationDTOs: nil))
        }
        guard let apiKey = UserDefaults.standard.value(forKey: kNearbyWeatherApiKeyKey),
            let requestURL = URL(string: "\(kOpenWeatherMultiLocationBaseURL)?APPID=\(apiKey)&lat=\(currentLatitude)&lon=\(currentLongitude)&cnt=\(PreferencesManager.shared.amountOfResults.integerValue)") else {
                let errorDataDTO = ErrorDataDTO(errorType: ErrorType(value: .malformedUrlError), httpStatusCode: nil)
                return completionHandler(BulkWeatherDataContainer(errorDataDTO: errorDataDTO, weatherInformationDTOs: nil))
        }
        let request = URLRequest(url: requestURL)
        let dataTask = session.dataTask(with: request, completionHandler: { data, response, error in
            guard let receivedData = data, let _ = response, error == nil else {
                let errorDataDTO = ErrorDataDTO(errorType: ErrorType(value: .httpError), httpStatusCode: (response as? HTTPURLResponse)?.statusCode)
                return completionHandler(BulkWeatherDataContainer(errorDataDTO: errorDataDTO, weatherInformationDTOs: nil))
            }
            completionHandler(self.extractBulkWeatherInformation(receivedData))
        })
        dataTask.resume()
    }
    
    
    // MARK: - Private Helpers
    
    private func extractWeatherInformation(_ data: Data, identifier: Int) -> WeatherDataContainer {
        do {
            guard let extractedData = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: AnyHashable],
                let httpStatusCode = extractedData["cod"] as? Int else {
                    let errorDataDTO = ErrorDataDTO(errorType: ErrorType(value: .unparsableResponseError), httpStatusCode: nil)
                    return WeatherDataContainer(locationId: identifier, errorDataDTO: errorDataDTO, weatherInformationDTO: nil)
            }
            guard httpStatusCode == 200 else {
                if httpStatusCode == 401 {
                    let errorDataDTO = ErrorDataDTO(errorType: ErrorType(value: .unrecognizedApiKeyError), httpStatusCode: httpStatusCode)
                    return WeatherDataContainer(locationId: identifier, errorDataDTO: errorDataDTO, weatherInformationDTO: nil)
                }
                let errorDataDTO = ErrorDataDTO(errorType: ErrorType(value: .httpError), httpStatusCode: httpStatusCode)
                return WeatherDataContainer(locationId: identifier, errorDataDTO: errorDataDTO, weatherInformationDTO: nil)
            }
            let weatherInformationDTO = try JSONDecoder().decode(WeatherInformationDTO.self, from: data)
            return WeatherDataContainer(locationId: identifier, errorDataDTO: nil, weatherInformationDTO: weatherInformationDTO)
        } catch {
            print("💥 NetworkingService: Error while extracting single-location-data json: \(error.localizedDescription)")
            let errorDataDTO = ErrorDataDTO(errorType: ErrorType(value: .jsonSerializationError), httpStatusCode: nil)
            return WeatherDataContainer(locationId: identifier, errorDataDTO: errorDataDTO, weatherInformationDTO: nil)
        }
    }
    
    private func extractBulkWeatherInformation(_ data: Data) -> BulkWeatherDataContainer {
        do {
            guard let extractedData = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: AnyHashable],
                let httpStatusCodeString = extractedData["cod"] as? String,
                let httpStatusCode = Int(httpStatusCodeString) else {
                    let errorDataDTO = ErrorDataDTO(errorType: ErrorType(value: .unparsableResponseError), httpStatusCode: nil)
                    return BulkWeatherDataContainer(errorDataDTO: errorDataDTO, weatherInformationDTOs: nil)
            }
            guard httpStatusCode == 200 else {
                if httpStatusCode == 401 {
                    let errorDataDTO = ErrorDataDTO(errorType: ErrorType(value: .unrecognizedApiKeyError), httpStatusCode: httpStatusCode)
                    return BulkWeatherDataContainer(errorDataDTO: errorDataDTO, weatherInformationDTOs: nil)
                }
                let errorDataDTO = ErrorDataDTO(errorType: ErrorType(value: .httpError), httpStatusCode: httpStatusCode)
                return BulkWeatherDataContainer(errorDataDTO: errorDataDTO, weatherInformationDTOs: nil)
            }
            let multiWeatherData = try JSONDecoder().decode(MultiWeatherInformationDTO.self, from: data)
            return BulkWeatherDataContainer(errorDataDTO: nil, weatherInformationDTOs: multiWeatherData.list)
        } catch {
            print("💥 NetworkingService: Error while extracting multi-location-data json: \(error.localizedDescription)")
            let errorDataDTO = ErrorDataDTO(errorType: ErrorType(value: .jsonSerializationError), httpStatusCode: nil)
            return BulkWeatherDataContainer(errorDataDTO: errorDataDTO, weatherInformationDTOs: nil)
        }
    }
}
