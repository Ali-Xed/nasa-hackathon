//
//  DataStorageService.swift
//  NearbyWeather
//
//  Created by Erik Maximilian Martens on 08.01.18.
//  Copyright © 2018 Erik Maximilian Martens. All rights reserved.
//

import Foundation

enum StorageLocationType {
    case documents
    case applicationSupport
}

class DataStorageService {    
    
    // MARK: -  Public Functions
    
    static func storeJson<T: Encodable>(forCodable codable: T, inFileWithName fileName: String, toStorageLocation location: StorageLocationType) {
        guard let destinationDirectoryURL = directoryURL(forLocation: location) else {
            print("💥 DataStorageService: Could not construct directory url.")
            return
        }
        if !FileManager.default.fileExists(atPath: destinationDirectoryURL.path, isDirectory: nil) {
            do {
                try FileManager.default.createDirectory(at: destinationDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("💥 DataStorageService: Error while creating directory \(destinationDirectoryURL.path). Error-Description: \(error.localizedDescription)")
                return
            }
        }
        let fileExtension = "json"
        let filePathURL = destinationDirectoryURL.appendingPathComponent(fileName).appendingPathExtension(fileExtension)
        
        do {
            let data = try JSONEncoder().encode(codable)
            try data.write(to: filePathURL)
        } catch let error {
            print("💥 DataStorageService: Error while writing data to \(filePathURL.path). Error-Description: \(error.localizedDescription)")
        }
    }
    
    static func retrieveJson<T: Decodable>(fromFileWithName fileName: String, andDecodeAsType type: T.Type, fromStorageLocation location: StorageLocationType) -> T? {
        guard let fileBaseURL = directoryURL(forLocation: location) else {
            print("💥 DataStorageService: Could not construct directory url.")
            return nil
        }
        let fileExtension = "json"
        let filePathURL = fileBaseURL.appendingPathComponent(fileName).appendingPathExtension(fileExtension)
    
        if !FileManager.default.fileExists(atPath: filePathURL.path) {
            print("💥 DataStorageService: File at path \(filePathURL.path) does not exist!")
            return nil
        }
        do {
            let data = try Data(contentsOf: filePathURL)
            let model = try JSONDecoder().decode(type, from: data)
            return model
        } catch let error {
            print("💥 DataStorageService: Error while retrieving data from \(filePathURL.path). Error-Description: \(error.localizedDescription)")
            return nil
        }
    }
    
    
    // MARK: - Private Functions
    
    static private func directoryURL(forLocation location: StorageLocationType) -> URL? {
        var fileBaseUrl: URL?
        switch location {
        case .documents:
            fileBaseUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        case .applicationSupport:
            fileBaseUrl =  FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        }
        return fileBaseUrl
    }
}
