//
//  MockDownloadManager.swift
//  KlutchShotsChallenge
//
//  Created by Marco Siracusano on 30/03/2025.
//

import Foundation
import Combine

final class MockDownloadManager: DownloadManagerProtocol {
    
    // MARK: - Properties
    private(set) var currentVideoId: String?
    
    // Configuration
    var mockVideoExists = false
    var mockPlaybackURL: URL?
    var mockLocalURL: URL?
    
    // State tracking
    var downloadVideoCalled = false
    var cancelDownloadCalled = false
    var deleteDownloadedVideoCalled = false
    var lastRequestedVideoId: String?
    var lastRequestedFallbackUrl: String?
    var lastDownloadedVideoId: String?
    var lastDownloadedURL: URL?
    var lastDeletedVideoId: String?
    
    var onDownloadVideoCalled: ((String) -> Void)?
    var onDeleteDownloadedVideoCalled: ((String) -> Void)?
    
    private let stateSubject = CurrentValueSubject<DownloadState, Never>(.notStarted)
    
    // MARK: - Protocol Methods
    func downloadVideo(_ videoId: String, from url: URL) -> AnyPublisher<DownloadState, Never> {
        downloadVideoCalled = true
        lastDownloadedVideoId = videoId
        lastDownloadedURL = url
        currentVideoId = videoId
        
        onDownloadVideoCalled?(videoId)
        
        return stateSubject.eraseToAnyPublisher()
    }
    
    func videoExists(for videoId: String) -> Bool {
        mockVideoExists
    }
    
    func cancelDownload() {
        cancelDownloadCalled = true
        currentVideoId = nil
        stateSubject.send(.notStarted)
    }
    
    func getPlaybackURL(for videoId: String, fallbackUrl: String) -> URL? {
        lastRequestedVideoId = videoId
        lastRequestedFallbackUrl = fallbackUrl
        return mockPlaybackURL
    }
    
    func getLocalURL(for videoId: String) -> URL? {
        mockLocalURL
    }
    
    func deleteDownloadedVideo(videoId: String) -> AnyPublisher<DownloadState, Never> {
        deleteDownloadedVideoCalled = true
        lastDeletedVideoId = videoId
        
        onDeleteDownloadedVideoCalled?(videoId)
        
        return stateSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Test Control Methods
    /// Method for tests to trigger state changes
    func simulateStateUpdate(_ state: DownloadState) {
        stateSubject.send(state)
    }
}
