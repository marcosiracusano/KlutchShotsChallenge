//
//  VideoDetailViewModel.swift
//  KlutchShotsChallenge
//
//  Created by Marco Siracusano on 27/03/2025.
//

import SwiftUI
import AVFoundation
import Combine

final class VideoDetailViewModel: ObservableObject {
    
    // MARK: - Internal properties
    @Published var player: AVPlayer?
    @Published var isBuffering = false
    @Published var isFullScreen = false
    @Published var downloadState: DownloadState = .notStarted
    
    // MARK: - Private properties
    private var cancellables = Set<AnyCancellable>()
    private let downloadManager: DownloadManagerProtocol
    
    // MARK: - Initializer
    init(downloadManager: DownloadManagerProtocol = DownloadManager()) {
        self.downloadManager = downloadManager
        setupOrientationObserver()
    }
    
    // MARK: - Internal methods
    func loadVideo(for videoId: String, videoUrl: String) {
        // If the video is already downloaded, set the download state to completed
        if downloadManager.videoExists(for: videoId) {
            downloadState = .completed
        }
        
        // Get the appropriate URL from download manager
        guard let url = downloadManager.getPlaybackURL(for: videoId, fallbackUrl: videoUrl) else {
            // TODO: show error
            return
        }
        
        // Create the player
        let player = AVPlayer(url: url)
        self.player = player
        
        // Start observing player status
        player.publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self else { return }
                
                switch status {
                case .waitingToPlayAtSpecifiedRate:
                    self.isBuffering = true
                case .playing:
                    self.isBuffering = false
                case .paused:
                    if player.currentItem?.isPlaybackLikelyToKeepUp == true {
                        self.isBuffering = false
                    }
                @unknown default:
                    break
                }
            }
            .store(in: &cancellables)
        
        // Play the video
        player.play()
    }
    
    func downloadVideo(from url: URL, with id: String) {
        downloadManager.downloadVideo(id, from: url)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.downloadState = state
            }
            .store(in: &cancellables)
    }
    
    func cleanUp() {
        player?.pause()
        player = nil
        downloadManager.cancelDownload()
        cancellables.removeAll()
    }
    
    // MARK: - Private methods
    private func setupOrientationObserver() {
        NotificationCenter.default
            .publisher(for: UIDevice.orientationDidChangeNotification)
            .sink { [weak self] _ in
                self?.updateFullScreenState()
            }
            .store(in: &cancellables)
        
        // Set initial state based on current orientation
        updateFullScreenState()
    }
    
    private func updateFullScreenState() {
        let orientation = UIDevice.current.orientation
        DispatchQueue.main.async { [weak self] in
            // Only update if orientation is a valid interface orientation
            if orientation.isPortrait || orientation.isLandscape {
                self?.isFullScreen = orientation.isLandscape
            }
        }
    }
}
