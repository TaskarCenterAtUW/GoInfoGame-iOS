//
//  Res.swift
//  GoInfoGame
//
//  Created by Prashamsa on 29/06/25.
//

import Foundation

// MARK: - ResponseHandler
protocol ResponseHandler {
    /**
     Decodes raw `Data` into a specified `Decodable` type.

     This method attempts to decode the provided `Data` into the specified `T` type using `JSONDecoder` and returns the result via a completion handler.

     - Generic Parameter:
       - `T`: A type that conforms to `Decodable`, representing the expected model.

     - Parameters:
       - data: The raw `Data` to be decoded.
       - type: The type of the model to decode the data into.
       - completion: A closure that returns a `Result<T, Error>`, containing the decoded object on success or an error on failure.

     - Note: Ensure that the data format matches the expected `Decodable` model structure.
     */
    func decode<T: Decodable>(_ data: Data, type: T.Type, completion: @escaping (Result<T, Error>) -> Void)
}

// MARK: - ResponseManager

class ResponseManager: ResponseHandler {
    func decode<T: Decodable>(_ data: Data, type: T.Type, completion: @escaping (Result<T, Error>) -> Void) {
        if let response = try? JSONDecoder().decode(T.self, from: data) {
            completion(.success(response))
        } else {
            completion(.failure( NetworkError.decodingFailed))
        }
    }
}
