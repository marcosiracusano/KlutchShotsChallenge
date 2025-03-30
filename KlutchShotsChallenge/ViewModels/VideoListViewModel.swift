//
//  VideoListViewModel.swift
//  KlutchShotsChallenge
//
//  Created by Marco Siracusano on 27/03/2025.
//

import Foundation
import Combine
import OSLog

final class VideoListViewModel: ObservableObject {
    @Published var videos: [Video] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let networking: NetworkingProtocol
    private let log: Logger = .main
    private var cancellables = Set<AnyCancellable>()
    
    init(networking: NetworkingProtocol) {
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
            guard let self else { return }
                isLoading = false
                
                if case .failure(let error) = completion {
                    if let networkError = error as? NetworkError {
                        switch networkError {
                        case .invalidURL:
                            errorMessage = "Invalid API URL. Please contact support."
                        case .serverError(let statusCode):
                            errorMessage = "Server error \(statusCode). Please try again later."
                        case .decodingError:
                            errorMessage = "Failed to process the server response. Please try again."
                        case .unknownError:
                            errorMessage = "An unexpected error occurred. Please try again."
                        }
                    } else {
                        errorMessage = "Failed to load videos: \(error.localizedDescription)"
                    }
                    
                    log.notice("Video fetch operation failed, UI error message set")
                }
            },
            receiveValue: { [weak self] fetchedVideos in
                self?.log.info("Received \(fetchedVideos.count) videos")
                self?.videos = fetchedVideos
            }
        )
        .store(in: &cancellables)
    }
}
