//
//  CachedAsyncImage.swift
//  KlutchShotsChallenge
//
//  Created by Marco Siracusano on 29/03/2025.
//

import SwiftUI
import OSLog

struct CachedAsyncImage: View {
    private let url: URL?
    @State private var image: Image? = nil
    @State private var isLoading = false
    @State private var hasError = false
    
    private let log: Logger = .networking
    
    init(url: URL?) {
        self.url = url
    }
    
    var body: some View {
        if let image {
            image.resizable().scaledToFit()
        } else if hasError {
            // Display error image
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.gray)
                .font(.largeTitle)
        } else {
            ProgressView()
                .task {
                    await loadImage()
                }
        }
    }
    
    private func loadImage() async {
        guard let url, !isLoading else { return }
        
        isLoading = true
        
        // Check if the image is already cached
        let request = URLRequest(url: url)
        if let cachedResponse = URLCache.shared.cachedResponse(for: request),
           let cachedImage = UIImage(data: cachedResponse.data) {
            await MainActor.run {
                image = Image(uiImage: cachedImage)
                isLoading = false
            }
            return
        }
        
        // Fetch the image from the network
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Cache the image
            let cachedData = CachedURLResponse(response: response, data: data)
            URLCache.shared.storeCachedResponse(cachedData, for: request)
            
            if let uiImage = UIImage(data: data) {
                await MainActor.run {
                    image = Image(uiImage: uiImage)
                    isLoading = false
                }
            } else {
                log.error("Failed to create image from data for URL: \(url)")
                await MainActor.run {
                    hasError = true
                    isLoading = false
                }
            }
        } catch {
            // Log the error and show error image
            log.error("Failed to load image from \(url): \(error.localizedDescription)")
            
            await MainActor.run {
                hasError = true
                isLoading = false
            }
        }
    }
}
