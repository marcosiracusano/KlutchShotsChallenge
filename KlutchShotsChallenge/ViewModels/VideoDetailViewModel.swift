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
    @Published var player: AVPlayer?
    @Published var isBuffering = false
    @Published var isFullScreen = false
    @Published var downloadState: DownloadState = .notStarted
    
    private var currentVideo: Video?
    private var cancellables = Set<AnyCancellable>()
    private let downloadManager: DownloadManagerProtocol
    
    init(downloadManager: DownloadManagerProtocol = DownloadManager()) {
        self.downloadManager = downloadManager
    }
    
    func loadVideo(_ video: Video) {
        currentVideo = video
        
        // If the video is already downloaded, set the download state to completed
        if downloadManager.videoExists(for: video.id) {
            downloadState = .completed
        }
        
        guard let url = URL(string: video.videoUrl) else {
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
    
    func toggleFullScreen() {
        withAnimation {
            isFullScreen.toggle()
        }
    }
    
    func downloadVideo(from url: URL, with id: String) {
        downloadManager.downloadVideo(from: url, with: id)
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
}
