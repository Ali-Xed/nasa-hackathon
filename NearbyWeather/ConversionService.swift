//
//  ConversionService.swift
//  NearbyWeather
//
//  Created by Erik Maximilian Martens on 09.01.18.
//  Copyright © 2018 Erik Maximilian Martens. All rights reserved.
//

import Foundation
import MapKit
import APTimeZones

class ConversionService {
    
    public static func weatherConditionSymbol(fromWeathercode: Int) -> String {
        switch fromWeathercode {
        case let x where (x >= 200 && x <= 202) || (x >= 230 && x <= 232):
            return "⛈"
        case let x where x >= 210 && x <= 211:
            return "🌩"
        case let x where x >= 212 && x <= 221:
            return "⚡️"
        case let x where x >= 300 && x <= 321:
            return "🌦"
        case let x where x >= 500 && x <= 531:
            return "🌧"
        case let x where x >= 600 && x <= 602:
            return "☃️"
        case let x where x >= 603 && x <= 622:
            return "🌨"
        case let x where x >= 701 && x <= 771:
            return "🌫"
        case let x where x == 781 || x == 900:
            return "🌪"
        case let x where x == 800:
            return "☀️"
        case let x where x == 801:
            return "🌤"
        case let x where x == 802:
            return "⛅️"
        case let x where x == 803:
            return "🌥"
        case let x where x == 804:
            return "☁️"
        case let x where x >= 952 && x <= 956 || x == 905:
            return "🌬"
        case let x where x >= 957 && x <= 961 || x == 771:
            return "💨"
        case let x where x == 901 || x == 902 || x == 962:
            return "🌀"
        case let x where x == 903:
            return "❄️"
        case let x where x == 904:
            return "🌡"
        case let x where x == 962:
            return "🌋"
        default:
            return "❓"
        }
    }
    
    public static func temperatureDescriptor(forTemperatureUnit temperatureUnit: TemperatureUnit, fromRawTemperature rawTemperature: Double) -> String {
        switch temperatureUnit.value {
        case .celsius:
            return "\(String(format:"%.02f", rawTemperature - 273.15))°C"
        case . fahrenheit:
            return "\(String(format:"%.02f", rawTemperature * (9/5) - 459.67))°F"
        case .kelvin:
            return "\(String(format:"%.02f", rawTemperature))°K"
        }
    }
    
    public static func windspeedDescriptor(forDistanceSpeedUnit distanceSpeedUnit: DistanceSpeedUnit, forWindspeed windspeed: Double) -> String {
        switch distanceSpeedUnit.value {
        case .kilometres:
            return "\(String(format:"%.02f", windspeed)) \(R.string.localizable.kph())"
        case .miles:
            return "\(String(format:"%.02f", windspeed / 1.609344)) \(R.string.localizable.mph())"
        }
    }
    
    public static func distanceDescriptor(forDistanceSpeedUnit distanceSpeedUnit: DistanceSpeedUnit, forDistanceInMetres distance: Double) -> String {
        switch distanceSpeedUnit.value {
        case .kilometres:
            return "\(String(format:"%.02f", distance/1000)) \(R.string.localizable.km())"
        case .miles:
            return "\(String(format:"%.02f", distance/1609.344)) \(R.string.localizable.mi())"
        }
    }
    
    public static func windDirectionDescriptor(forWindDirection degrees: Double) -> String {
        return String(format: "%.02f", degrees) + "°"
    }
    
    public static func isDayTime(forWeatherDTO weatherDTO: WeatherInformationDTO?) -> Bool? {
        
        guard let weatherDTO = weatherDTO,
            let sunrise =  weatherDTO.daytimeInformation?.sunrise,
            let sunset =  weatherDTO.daytimeInformation?.sunset else {
                return nil
        }
        let location = CLLocation(latitude: weatherDTO.coordinates.latitude, longitude: weatherDTO.coordinates.longitude)
        
        var calendar = Calendar.current
        calendar.timeZone = location.timeZone()
        
        let currentTimeDateComponents = calendar.dateComponents([.hour, .minute], from: Date())
        let sunriseDate = Date(timeIntervalSince1970: sunrise)
        let sunriseDateComponents = calendar.dateComponents([.hour, .minute], from: sunriseDate)
        let sunsetDate = Date(timeIntervalSince1970: sunset)
        let sunsetDateComponents = calendar.dateComponents([.hour, .minute], from: sunsetDate)
        
        guard let currentTimeDateComponentHour = currentTimeDateComponents.hour,
            let currentTimeDateComponentMinute = currentTimeDateComponents.minute,
            let sunriseDateComponentHour = sunriseDateComponents.hour,
            let sunriseDateComponentMinute = sunriseDateComponents.minute,
            let sunsetDateComponentHour = sunsetDateComponents.hour,
            let sunsetDateComponentMinute = sunsetDateComponents.minute else {
                return nil
        }
        
        return ((currentTimeDateComponentHour == sunriseDateComponentHour
            && currentTimeDateComponentMinute >= sunriseDateComponentMinute)
            || currentTimeDateComponentHour > sunriseDateComponentHour)
            && ((currentTimeDateComponentHour == sunsetDateComponentHour
                && currentTimeDateComponentMinute <= sunsetDateComponentMinute)
                || currentTimeDateComponentHour < sunsetDateComponentHour)
    }
}
