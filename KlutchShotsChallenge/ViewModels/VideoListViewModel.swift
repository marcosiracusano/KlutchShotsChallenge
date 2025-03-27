//
//  VideoListViewModel.swift
//  KlutchShotsChallenge
//
//  Created by Marco Siracusano on 27/03/2025.
//

import Foundation
import Combine

class VideoListViewModel: ObservableObject {
    @Published var videos: [Video] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let networking: NetworkingProtocol
    
    init(networking: NetworkingProtocol = NetworkingService()) {
        self.networking = networking
    }
    
    func fetchVideos() {
        isLoading = true
        Task {
            do {
                let fetchedVideos = try await networking.fetchVideos()
                DispatchQueue.main.async {
                    self.videos = fetchedVideos
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load videos: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
}