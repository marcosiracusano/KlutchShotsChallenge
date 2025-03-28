//
//  VideoDetailViewModel.swift
//  KlutchShotsChallenge
//
//  Created by Marco Siracusano on 27/03/2025.
//

import Foundation
import AVFoundation
import Combine

final class VideoDetailViewModel: ObservableObject {
    @Published var player: AVPlayer?
    @Published var isBuffering = false
    
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    
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
        
        // Add periodic time observer to track playback
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] _ in
            // This could be used to track playback progress if needed
        }
        
        // Play the video
        player.play()
    }
    
    func cleanUp() {
        // Remove time observer
        if let timeObserver, let player {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        
        // Stop the player and release resources
        player?.pause()
        player = nil
        
        // Cancel all subscriptions
        cancellables.removeAll()
    }
}
