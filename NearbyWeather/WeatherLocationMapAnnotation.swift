//
//  WeatherLocationMapAnnotation.swift
//  NearbyWeather
//
//  Created by Erik Maximilian Martens on 04.02.18.
//  Copyright © 2018 Erik Maximilian Martens. All rights reserved.
//

import Foundation
import MapKit

class WeatherLocationMapAnnotation: NSObject, MKAnnotation {
    let title: String?
    let subtitle: String?
    let isDayTime: Bool?
    let coordinate: CLLocationCoordinate2D
    let locationId: Int
    
    init(title: String?, subtitle: String?, isDayTime: Bool?, coordinate: CLLocationCoordinate2D, locationId: Int) {
        self.title = title
        self.subtitle = subtitle
        self.isDayTime = isDayTime
        self.coordinate = coordinate
        self.locationId = locationId
    }
    
    convenience init?(weatherDTO: WeatherInformationDTO?) {
        guard let weatherDTO = weatherDTO else { return nil }
        
        let weatherConditionIdentifier = weatherDTO.weatherCondition.first?.identifier
        let weatherConditionSymbol = weatherConditionIdentifier != nil ? ConversionService.weatherConditionSymbol(fromWeathercode: weatherConditionIdentifier!) : nil
        let temperatureDescriptor = ConversionService.temperatureDescriptor(forTemperatureUnit: PreferencesManager.shared.temperatureUnit, fromRawTemperature: weatherDTO.atmosphericInformation.temperatureKelvin)
        
        let subtitle = weatherConditionSymbol != nil ? "\(weatherConditionSymbol!) \(temperatureDescriptor)" : "\(temperatureDescriptor)"
        
        let isDayTime = ConversionService.isDayTime(forWeatherDTO: weatherDTO)
        
        let coordinate = CLLocationCoordinate2D(latitude: weatherDTO.coordinates.latitude, longitude: weatherDTO.coordinates.longitude)
        
        self.init(title: weatherDTO.cityName, subtitle: subtitle, isDayTime: isDayTime, coordinate: coordinate, locationId: weatherDTO.cityID)
    }
}
