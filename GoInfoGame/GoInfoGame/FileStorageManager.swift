//
//  FileStorageManager.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 13/08/24.
//

import Foundation

class FileStorageManager {

    static let shared = FileStorageManager()

    private let fileManager = FileManager.default
    private let directoryURL: URL

    private init() {
        self.directoryURL = fileManager.temporaryDirectory
    }

    func save(questModels: [LongFormModel], to fileName: String) throws {
           let fileURL = directoryURL.appendingPathComponent("\(fileName).json")
           let data = try JSONEncoder().encode(questModels)
           try data.write(to: fileURL)
       }

       func load(from fileName: String) throws -> [LongFormModel]? {
           let fileURL = directoryURL.appendingPathComponent("\(fileName).json")
           
           guard fileManager.fileExists(atPath: fileURL.path) else {
               return nil
           }

           let data = try Data(contentsOf: fileURL)
           let questModels = try JSONDecoder().decode([LongFormModel].self, from: data)
           return questModels
       }
    
    // delete on logout ?
    func delete(fileName: String) throws {
           let fileURL = directoryURL.appendingPathComponent("\(fileName).json")
           
           if fileManager.fileExists(atPath: fileURL.path) {
               try fileManager.removeItem(at: fileURL)
           }
       }

}
