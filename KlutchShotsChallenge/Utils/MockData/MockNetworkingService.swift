//
//  MockNetworkingService.swift
//  KlutchShotsChallenge
//
//  Created by Marco Siracusano on 30/03/2025.
//

import Foundation

final class MockNetworkingService: NetworkingProtocol {
    var mockResult: Result<[Video], Error> = .success([])
    var mockDelay: TimeInterval = 0.0
    var fetchVideosCalled = false
    
    func fetchVideos() async throws -> [Video] {
        fetchVideosCalled = true
        
        if mockDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        }
        
        switch mockResult {
        case .success(let videos):
            return videos
        case .failure(let error):
            throw error
        }
    }
}
