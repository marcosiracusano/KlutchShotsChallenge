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
    @Published var isPlayingFromLocalFile = false
    @Published var isShowingDeleteAlert = false
    @Published var downloadState: DownloadState = .notStarted
    @Published var errorMessage: String? = nil
    
    // MARK: - Private properties
    private enum DownloadAction {
        case download, delete
    }
    private let downloadManager: DownloadManagerProtocol
    private var currentVideoId: String?
    private var currentVideoUrl: String?
    private let downloadActionSubject = PassthroughSubject<DownloadAction, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initializer
    init(downloadManager: DownloadManagerProtocol = DownloadManager()) {
        self.downloadManager = downloadManager
        setupOrientationObserver()
        setupDownloadPipeline()
    }
    
    // MARK: - Internal methods
    func loadVideo(for videoId: String, videoUrl: String) {
        guard !videoId.isEmpty, !videoUrl.isEmpty else {
            errorMessage = "Failed to obtain video ID and URL"
            return
        }
        
        currentVideoId = videoId
        currentVideoUrl = videoUrl
        
        // If the video is already downloaded, set the download state to completed
        if downloadManager.videoExists(for: videoId) {
            isPlayingFromLocalFile = true
            downloadState = .completed
        }
        
        // Get the appropriate URL from download manager
        guard let url = downloadManager.getPlaybackURL(for: videoId, fallbackUrl: videoUrl) else {
            errorMessage = "Failed to obtain video URL"
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
    
    func handleDownload() {
        switch downloadState {
        case .notStarted:
            downloadActionSubject.send(.download)
        case .completed:
            isShowingDeleteAlert = true
        default:
            break
        }
        
    }
    
    func deleteDownloadedVideo() {
        downloadActionSubject.send(.delete)
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
    
    private func setupDownloadPipeline() {
        downloadActionSubject
            .receive(on: DispatchQueue.main)
            .compactMap { [weak self] action -> AnyPublisher<DownloadState, Never>? in
                guard let self, let currentVideoId, let currentVideoUrl else { return nil }
                
                switch action {
                case .download:
                    guard let url = URL(string: currentVideoUrl) else { return nil }
                    return downloadManager.downloadVideo(currentVideoId, from: url)
                    
                case .delete:
                    return downloadManager.deleteDownloadedVideo(videoId: currentVideoId)
                }
            }
            .switchToLatest()
            .sink { [weak self] state in
                guard let self, let currentVideoUrl else { return }
                
                downloadState = state
                
                switch state {
                case .completed:
                    // If the file is downloaded, we switch to local playback
                    switchToLocalPlayback()
                    
                case .notStarted:
                    // If the file was deleted, switch to streaming
                    switchToStreamingPlayback(from: currentVideoUrl)
                    
                case .failed(let error, let errorType):
                    // We show an error message and then go back to previous state
                    switch errorType {
                    case .download:
                        errorMessage = "Download failed: \(error)"
                        downloadState = .notStarted
                    case .deletion:
                        errorMessage = "Deletion failed: \(error)"
                        downloadState = .completed
                    }
                    
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }
    
    private func switchToLocalPlayback() {
        guard let player,
              let currentVideoId,
              let localURL = downloadManager.getLocalURL(for: currentVideoId) else {
            return
        }
        
        // Save current playback time and playing state
        let currentTime = player.currentTime()
        let wasPlaying = player.timeControlStatus == .playing
        
        // Create new player item with local URL
        let newPlayerItem = AVPlayerItem(url: localURL)
        
        // Replace the current item
        player.replaceCurrentItem(with: newPlayerItem)
        
        // Seek to the previous position
        player.seek(to: currentTime) { [weak self] success in
            guard let self = self, success, wasPlaying else { return }
            // Resume playback if it was playing
            self.player?.play()
        }
        
        // Update source indicator
        isPlayingFromLocalFile = true
    }
    
    private func switchToStreamingPlayback(from videoUrl: String) {
        guard let player,
              let url = URL(string: videoUrl) else {
            return
        }
        
        // Save current playback time and playing state
        let currentTime = player.currentTime()
        let wasPlaying = player.timeControlStatus == .playing
        
        // Create new player item with streaming URL
        let newPlayerItem = AVPlayerItem(url: url)
        
        // Replace the current item
        player.replaceCurrentItem(with: newPlayerItem)
        
        // Seek to the previous position
        player.seek(to: currentTime) { [weak self] success in
            guard let self = self, success, wasPlaying else { return }
            // Resume playback if it was playing
            self.player?.play()
        }
        
        // Update source indicator
        isPlayingFromLocalFile = false
    }
}
