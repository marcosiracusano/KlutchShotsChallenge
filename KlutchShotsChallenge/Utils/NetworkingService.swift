//
//  NetworkingService.swift
//  KlutchShotsChallenge
//
//  Created by Marco Siracusano on 27/03/2025.
//

import Foundation

protocol NetworkingProtocol {
    func fetchVideos() async throws -> [Video]
}

struct NetworkingService: NetworkingProtocol {
    func fetchVideos() async throws -> [Video] {
        let url = URL(string: Constants.apiUrl)!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([Video].self, from: data)
    }
}