//
//  VideoListViewModel.swift
//  KlutchShotsChallenge
//
//  Created by Marco Siracusano on 27/03/2025.
//

import Foundation
import Combine

final class VideoListViewModel: ObservableObject {
    @Published var videos: [Video] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let networking: NetworkingProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(networking: NetworkingProtocol = NetworkingService()) {
        self.networking = networking
    }
    
    func fetchVideos() {
        isLoading = true
        errorMessage = nil
        
        Future<[Video], Error> { [weak self] promise in
            guard let self else { return }
            
            Task {
                do {
                    let videos = try await self.networking.fetchVideos()
                    promise(.success(videos))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.errorMessage = "Failed to load videos: \(error.localizedDescription)"
                }
            },
            receiveValue: { [weak self] fetchedVideos in
                self?.videos = fetchedVideos
            }
        )
        .store(in: &cancellables)
    }
}
