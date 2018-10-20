//
//  WeatherDetailViewController.swift
//  NearbyWeather
//
//  Created by Erik Maximilian Martens on 04.02.18.
//  Copyright © 2018 Erik Maximilian Martens. All rights reserved.
//

import UIKit
import MapKit
import SafariServices
import APTimeZones
import MapKit

class WeatherDetailViewController: UIViewController {
    
    static func instantiateFromStoryBoard(withTitle title: String, weatherDTO: WeatherInformationDTO) -> WeatherDetailViewController {
        let viewController = UIStoryboard(name: "Details", bundle: .main).instantiateViewController(withIdentifier: "WeatherDetailViewController") as! WeatherDetailViewController
        viewController.titleString = title
        viewController.weatherDTO = weatherDTO
        return viewController
    }
    
    
    // MARK: - Properties
    
    /* Injected */
    
    private var titleString: String!
    private var weatherDTO: WeatherInformationDTO!
    
    /* Outlets */
    
    @IBOutlet weak var conditionSymbolLabel: UILabel!
    @IBOutlet weak var conditionNameLabel: UILabel!
    @IBOutlet weak var conditionDescriptionLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var daytimeStackView: UIStackView!
    @IBOutlet weak var sunriseImageView: UIImageView!
    @IBOutlet weak var sunriseNoteLabel: UILabel!
    @IBOutlet weak var sunriseLabel: UILabel!
    @IBOutlet weak var sunsetImageView: UIImageView!
    @IBOutlet weak var sunsetNoteLabel: UILabel!
    @IBOutlet weak var sunsetLabel: UILabel!
    
    @IBOutlet weak var cloudCoverImageView: UIImageView!
    @IBOutlet weak var cloudCoverNoteLabel: UILabel!
    @IBOutlet weak var cloudCoverLabel: UILabel!
    @IBOutlet weak var humidityImageView: UIImageView!
    @IBOutlet weak var humidityNoteLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var pressureImageView: UIImageView!
    @IBOutlet weak var pressureNoteLabel: UILabel!
    @IBOutlet weak var pressureLabel: UILabel!
    
    @IBOutlet weak var windSpeedImageView: UIImageView!
    @IBOutlet weak var windSpeedNoteLabel: UILabel!
    @IBOutlet weak var windSpeedLabel: UILabel!
    @IBOutlet weak var windDirectionStackView: UIStackView!
    @IBOutlet weak var windDirectionImageView: UIImageView!
    @IBOutlet weak var windDirectionNoteLabel: UILabel!
    @IBOutlet weak var windDirectionLabel: UILabel!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var coordinatesImageView: UIImageView!
    @IBOutlet weak var coordinatesNoteLabel: UILabel!
    @IBOutlet weak var coordinatesLabel: UILabel!
    @IBOutlet weak var distanceStackView: UIStackView!
    @IBOutlet weak var distanceImageView: UIImageView!
    @IBOutlet weak var distanceNoteLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    
    @IBOutlet var separatorLineHeightConstraints: [NSLayoutConstraint]!
    
    
    // MARK: - ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = titleString
        mapView.delegate = self
        
        configureMap()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configure()
    }
    
    
    // MARK: - Private Helpers
    
    private func configure() {
        let barTintColor: UIColor = ConversionService.isDayTime(forWeatherDTO: weatherDTO) ?? true ? .nearbyWeatherStandard : .nearbyWeatherNight
        navigationController?.navigationBar.styleStandard(withBarTintColor: barTintColor, isTransluscent: false, animated: true)
        navigationController?.navigationBar.addDropShadow(offSet: CGSize(width: 0, height: 1), radius: 10)
        
        separatorLineHeightConstraints.forEach { $0.constant = 1/UIScreen.main.scale }
        
        let weatherCode = weatherDTO.weatherCondition[0].identifier
        conditionSymbolLabel.text = ConversionService.weatherConditionSymbol(fromWeathercode: weatherCode)
        conditionNameLabel.text = weatherDTO.weatherCondition.first?.conditionName
        conditionDescriptionLabel.text = weatherDTO.weatherCondition.first?.conditionDescription.capitalized
        let temperatureUnit = PreferencesManager.shared.temperatureUnit
        let temperatureKelvin = weatherDTO.atmosphericInformation.temperatureKelvin
        temperatureLabel.text = ConversionService.temperatureDescriptor(forTemperatureUnit: temperatureUnit, fromRawTemperature: temperatureKelvin)
        
        if let sunriseTimeSinceReferenceDate = weatherDTO.daytimeInformation?.sunrise, let sunsetTimeSinceReferenceDate = weatherDTO.daytimeInformation?.sunset {
            let sunriseDate = Date(timeIntervalSince1970: sunriseTimeSinceReferenceDate)
            let sunsetDate = Date(timeIntervalSince1970: sunsetTimeSinceReferenceDate)
            
            let location = CLLocation(latitude: weatherDTO.coordinates.latitude, longitude: weatherDTO.coordinates.longitude)
            
            let dateFormatter = DateFormatter()
            dateFormatter.calendar = .current
            dateFormatter.timeZone = location.timeZone()
            dateFormatter.dateStyle = .none
            dateFormatter.timeStyle = .short
            
            let isDayTime = ConversionService.isDayTime(forWeatherDTO: weatherDTO) ?? true // can never be nil here
            let description = isDayTime ? R.string.localizable.dayTime() : R.string.localizable.nightTime()
            let localTime = dateFormatter.string(from: Date())
            timeLabel.text = "\(description), \(localTime)"
            
            sunriseImageView.tintColor = .darkGray
            sunriseNoteLabel.text = "\(R.string.localizable.sunrise()):"
            sunriseLabel.text = dateFormatter.string(from: sunriseDate)
            
            sunsetImageView.tintColor = .darkGray
            sunsetNoteLabel.text = "\(R.string.localizable.sunset()):"
            sunsetLabel.text = dateFormatter.string(from: sunsetDate)
        } else {
            daytimeStackView.isHidden = true
            timeLabel.isHidden = true
        }
        
        cloudCoverImageView.tintColor = .darkGray
        cloudCoverNoteLabel.text = "\(R.string.localizable.cloud_coverage()):"
        cloudCoverLabel.text = "\(weatherDTO.cloudCoverage.coverage)%"
        humidityImageView.tintColor = .darkGray
        humidityNoteLabel.text = "\(R.string.localizable.humidity()):"
        humidityLabel.text = "\(weatherDTO.atmosphericInformation.humidity)%"
        pressureImageView.tintColor = .darkGray
        pressureNoteLabel.text = "\(R.string.localizable.air_pressure()):"
        pressureLabel.text = "\(weatherDTO.atmosphericInformation.pressurePsi) hpa"
        
        windSpeedImageView.tintColor = .darkGray
        windSpeedNoteLabel.text = "\(R.string.localizable.windspeed()):"
        let windspeedDescriptor = ConversionService.windspeedDescriptor(forDistanceSpeedUnit: PreferencesManager.shared.distanceSpeedUnit, forWindspeed: weatherDTO.windInformation.windspeed)
        windSpeedLabel.text = windspeedDescriptor
        if let windDirection = weatherDTO.windInformation.degrees {
            windDirectionImageView.transform = CGAffineTransform(rotationAngle: CGFloat(windDirection)*0.0174532925199) // convert to radians
            windDirectionImageView.tintColor = .darkGray
            windDirectionNoteLabel.text = " \(R.string.localizable.wind_direction()):"
            windDirectionLabel.text = ConversionService.windDirectionDescriptor(forWindDirection: windDirection)
        } else {
            windDirectionStackView.isHidden = true
        }
        
        coordinatesImageView.tintColor = .darkGray
        coordinatesNoteLabel.text = "\(R.string.localizable.coordinates()):"
        coordinatesLabel.text = "\(weatherDTO.coordinates.latitude), \(weatherDTO.coordinates.longitude)"
        if LocationService.shared.locationPermissionsGranted, let userLocation = LocationService.shared.location {
            let location = CLLocation(latitude: weatherDTO.coordinates.latitude, longitude: weatherDTO.coordinates.longitude)
            let distanceInMetres = location.distance(from: userLocation)
            
            let distanceSpeedUnit = PreferencesManager.shared.distanceSpeedUnit
            let distanceString = ConversionService.distanceDescriptor(forDistanceSpeedUnit: distanceSpeedUnit, forDistanceInMetres: distanceInMetres)
            
            distanceImageView.tintColor = .darkGray
            distanceNoteLabel.text = "\(R.string.localizable.distance()):"
            distanceLabel.text = distanceString
        } else {
            distanceStackView.isHidden = true
        }
    }
    
    private func configureMap() {
        mapView.layer.cornerRadius = 10
        
        if let mapAnnotation = WeatherLocationMapAnnotation(weatherDTO: weatherDTO) {
            mapView.addAnnotation(mapAnnotation)
        }
        
        let location = CLLocation(latitude: weatherDTO.coordinates.latitude, longitude: weatherDTO.coordinates.longitude)
        let region = MKCoordinateRegionMakeWithDistance(location.coordinate, 5000, 5000)
        mapView.setRegion(region, animated: false)
    }
    
    
    // MARK: - IBActions
    
    @IBAction func openWeatherMapButtonPressed(_ sender: UIButton) {
        guard let url = URL(string: "https://openweathermap.org/find?q=\(weatherDTO.cityName)") else {
                return
        }
        presentSafariViewController(for: url)
    }
}

extension WeatherDetailViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? WeatherLocationMapAnnotation else {
            return nil
        }
        
        var viewForCurrentAnnotation: WeatherLocationMapAnnotationView?
        if let dequeuedAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: kMapAnnotationViewIdentifier) as? WeatherLocationMapAnnotationView {
            viewForCurrentAnnotation = dequeuedAnnotationView
        } else {
            viewForCurrentAnnotation = WeatherLocationMapAnnotationView(frame: kMapAnnotationViewInitialFrame)
        }
        viewForCurrentAnnotation?.annotation = annotation
        viewForCurrentAnnotation?.configure(withTitle: annotation.title ?? "<Not Set>", subtitle: annotation.subtitle ?? "<Not Set>", fillColor: (annotation.isDayTime ?? true) ? .nearbyWeatherStandard : .nearbyWeatherNight, tapHandler: nil)
        
        return viewForCurrentAnnotation
    }
}
