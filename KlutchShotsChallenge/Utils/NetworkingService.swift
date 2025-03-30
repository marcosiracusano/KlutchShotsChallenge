//
//  NetworkingService.swift
//  KlutchShotsChallenge
//
//  Created by Marco Siracusano on 27/03/2025.
//

import Foundation
import OSLog

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case serverError(statusCode: Int)
    case decodingError(Error)
    case unknownError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "The URL provided is invalid"
        case .serverError(let statusCode):
            "Server returned error code: \(statusCode)"
        case .decodingError:
            "Failed to decode response data"
        case .unknownError(let error):
            "An unknown error occurred: \(error.localizedDescription)"
        }
    }
}

protocol NetworkingProtocol {
    func fetchVideos() async throws -> [Video]
}

protocol URLSessionProtocol {
    func data(from url: URL) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

struct NetworkingService: NetworkingProtocol {
    private let log: Logger = .networking
    private let session: URLSessionProtocol
    private let apiUrl: String
    
    init(
        session: URLSessionProtocol = URLSession.shared,
        apiUrl: String = Constants.apiUrl
    ) {
        self.session = session
        self.apiUrl = apiUrl
    }
    
    func fetchVideos() async throws -> [Video] {
        guard let url = URL(string: apiUrl) else {
            log.error("Invalid API URL: \(Constants.apiUrl)")
            throw NetworkError.invalidURL
        }
        
        log.info("Fetching videos from: \(url.absoluteString)")
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                log.error("Response is not HTTPURLResponse")
                throw NetworkError.unknownError(NSError(domain: "NetworkingService", code: -1))
            }
            
            log.debug("Received HTTP status code: \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                log.error("Server error with status code: \(httpResponse.statusCode)")
                throw NetworkError.serverError(statusCode: httpResponse.statusCode)
            }
            
            do {
                let videos = try JSONDecoder().decode([Video].self, from: data)
                return videos
            } catch {
                log.error("JSON decoding error: \(error.localizedDescription)")
                throw NetworkError.decodingError(error)
            }
        } catch {
            if let networkError = error as? NetworkError {
                // Already logged, just rethrow
                throw networkError
            } else {
                log.error("Network request failed: \(error.localizedDescription)")
                throw NetworkError.unknownError(error)
            }
        }
    }
}
