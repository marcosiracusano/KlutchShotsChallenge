//
//  VideoDetailViewModel.swift
//  KlutchShotsChallenge
//
//  Created by Marco Siracusano on 27/03/2025.
//

import SwiftUI
import AVFoundation
import Combine

enum DownloadState: Equatable {
    case notStarted
    case downloading(progress: Float)
    case completed
    case failed(error: String)
    
    var progress: Float {
        switch self {
        case .downloading(let progress):
            progress
        case .completed:
            1.0
        default:
            0.0
        }
    }
    
    var isDownloading: Bool {
        if case .downloading = self {
            return true
        }
        return false
    }
    
    var hasCompleted: Bool {
        if case .completed = self {
            return true
        }
        return false
    }
}

final class VideoDetailViewModel: ObservableObject {
    @Published var player: AVPlayer?
    @Published var isBuffering = false
    @Published var isFullScreen = false
    @Published var downloadState: DownloadState = .notStarted

    private var cancellables = Set<AnyCancellable>()
    private var downloadCancellable: AnyCancellable?
    
    func loadVideo(from url: URL) {
        // Create the player
        let player = AVPlayer(url: url)
        self.player = player
        
        // Start observing player status
        player.publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                switch status {
                case .waitingToPlayAtSpecifiedRate:
                    self?.isBuffering = true
                case .playing:
                    self?.isBuffering = false
                case .paused:
                    if player.currentItem?.isPlaybackLikelyToKeepUp == true {
                        self?.isBuffering = false
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
    
    func downloadVideo(from url: URL) {
        // Only start download if not already downloading or completed
        guard case .notStarted = downloadState else { return }
        
        // Update state to downloading with 0 progress
        downloadState = .downloading(progress: 0)
        
        // For demo purposes, we'll simulate a download with a timer publisher
        // In a real app, this would use URLSession.downloadTask with progress tracking
        let totalTime = 5.0 // 5 seconds for demo
        
        downloadCancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .scan(0) { count, _ in count + 1 }
            .map { Float($0) * 0.1 / Float(totalTime) }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure = completion {
                    self?.downloadState = .failed(error: "Download failed")
                }
            }, receiveValue: { [weak self] progress in
                if progress >= 1.0 {
                    self?.downloadState = .completed
                    self?.downloadCancellable?.cancel()
                } else {
                    self?.downloadState = .downloading(progress: progress)
                }
            })
    }
    
    func cleanUp() {
        // Stop the player and release resources
        player?.pause()
        player = nil
        
        // Cancel all subscriptions
        cancellables.removeAll()
        downloadCancellable?.cancel()
    }
}
