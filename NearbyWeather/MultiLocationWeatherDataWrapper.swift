//
//  MultiLocationWeatherDataWrapper.swift
//  NearbyWeather
//
//  Created by Erik Maximilian Martens on 08.02.18.
//  Copyright © 2018 Erik Maximilian Martens. All rights reserved.
//

import Foundation

struct MultiLocationWeatherData: Codable {
    
    var statusCode: Int
    var locationWeatherData: [LocationWeatherDataDTO]?
}
