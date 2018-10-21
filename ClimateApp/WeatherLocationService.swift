

import Foundation
import FMDB

class WeatherLocationService {
    
    // MARK: - Public Assets
    
    public static var shared: WeatherLocationService!
    
    
    // MARK: - Private Assets
    
    private let openWeatherMapCityServiceBackgroundQueue = DispatchQueue(label: "com.maxchen666.climateapp.openWeatherMapCityService", qos: .userInitiated, attributes: [.concurrent], autoreleaseFrequency: .inherit, target: nil)
    
    fileprivate let databaseQueue: FMDatabaseQueue
    
    
    // MARK: - Initialization
    
    private init() {
        let sqliteFilePath = Bundle.main.path(forResource: "locationsSQLite", ofType: "sqlite")! // crash app if not found, cannot run without db
        self.databaseQueue = FMDatabaseQueue(path: sqliteFilePath)!
    }
    
    // MARK: - Public Properties & Methods
    
    public static func instantiateSharedInstance() {
        shared = WeatherLocationService()
    }
    
    public func locations(forSearchString searchString: String, completionHandler: @escaping (([WeatherStationDTO]?)->())) {
        
        if searchString.count == 0 || searchString == "" { return completionHandler(nil) }
        
        openWeatherMapCityServiceBackgroundQueue.async {
            self.databaseQueue.inDatabase { database in
                let usedLocationIdentifiers: [String] = WeatherDataManager.shared.bookmarkedLocations.compactMap {
                    return String($0.identifier)
                }
                let sqlUsedLocationsIdentifierssArray = "('" + usedLocationIdentifiers.joined(separator: "','") + "')"
                let query = !usedLocationIdentifiers.isEmpty ? "SELECT * FROM locations l WHERE l.id NOT IN \(sqlUsedLocationsIdentifierssArray) AND (lower(name) LIKE '%\(searchString.lowercased())%') ORDER BY country, l.name" : "SELECT * FROM locations l WHERE (lower(name) LIKE '%\(searchString.lowercased())%') ORDER BY l.name, l.country"
                var queryResult: FMResultSet?
                
                do {
                    queryResult = try database.executeQuery(query, values: nil)
                } catch {
                    print(error.localizedDescription)
                    return completionHandler(nil)
                }
                
                guard let result = queryResult else {
                    completionHandler(nil)
                    return
                }
                
                var retrievedLocations = [WeatherStationDTO]()
                while result.next() {
                    guard let location = WeatherStationDTO(from: result) else {
                        return
                    }
                    retrievedLocations.append(location)
                }
                
                guard !retrievedLocations.isEmpty else {
                    return completionHandler(nil)
                }
                completionHandler(retrievedLocations)
            }
        }
    }
}
