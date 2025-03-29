//
//  DownloadManager.swift
//  KlutchShotsChallenge
//
//  Created by Marco Siracusano on 28/03/2025.
//

import Foundation
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

/// Protocol defining the download manager's capabilities
protocol DownloadManagerProtocol {
    var currentVideoId: String? { get }
    
    func downloadVideo(_ videoId: String, from url: URL) -> AnyPublisher<DownloadState, Never>
    func videoExists(for videoId: String) -> Bool
    func cancelDownload()
    func getPlaybackURL(for videoId: String, fallbackUrl: String) -> URL?
    func getLocalURL(for videoId: String) -> URL?
}

/// A manager that handles downloading a single video at a time
final class DownloadManager: NSObject, DownloadManagerProtocol {
    // MARK: - Properties
    private var downloadStateSubject = CurrentValueSubject<DownloadState, Never>(.notStarted)
    private var downloadTask: URLSessionDownloadTask?
    private(set) var currentVideoId: String?
    private lazy var downloadSession: URLSession = {
        URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }()
    private(set) var currentDownloadingVideoId: String?
    
    // MARK: - Methods
    func downloadVideo(_ videoId: String, from url: URL) -> AnyPublisher<DownloadState, Never> {
        // Cancel any existing download
        cancelDownload()
        
        currentVideoId = videoId
        
        // Check if the video is already downloaded
        if videoExists(for: videoId) {
            downloadStateSubject.send(.completed)
            return downloadStateSubject.eraseToAnyPublisher()
        }
        
        // Update state to downloading with 0 progress
        downloadStateSubject.send(.downloading(progress: 0))
        
        // Create and start download task
        let task = downloadSession.downloadTask(with: url)
        downloadTask = task
        task.resume()
        
        return downloadStateSubject.eraseToAnyPublisher()
    }
    
    func videoExists(for videoId: String) -> Bool {
        let localURL = getLocalURL(for: videoId)
        return localURL != nil && FileManager.default.fileExists(atPath: localURL?.path ?? "")
    }
    
    func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        currentVideoId = nil
        downloadStateSubject.send(.notStarted)
    }
    
    func getPlaybackURL(for videoId: String, fallbackUrl: String) -> URL? {
        // If local file exists, return local URL
        if videoExists(for: videoId),
           let localURL = getLocalURL(for: videoId) {
            return localURL
        }
        
        // Otherwise return remote URL
        return URL(string: fallbackUrl)
    }
    
    func getLocalURL(for videoId: String) -> URL? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documentsDirectory?.appendingPathComponent("\(videoId).mp4")
    }
}

// MARK: - URLSessionDownloadDelegate
extension DownloadManager: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        // Calculate progress
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        
        // Update the publisher with the new progress
        DispatchQueue.main.async { [weak self] in
            self?.downloadStateSubject.send(.downloading(progress: progress))
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let currentVideoId else { return }
        
        // Get the destination URL
        guard let destinationURL = getLocalURL(for: currentVideoId) else {
            DispatchQueue.main.async { [weak self] in
                self?.downloadStateSubject.send(.failed(error: "Failed to create destination URL"))
            }
            return
        }
        
        // Move the downloaded file to the destination
        do {
            // Remove any existing file at the destination
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            try FileManager.default.moveItem(at: location, to: destinationURL)
            
            DispatchQueue.main.async { [weak self] in
                self?.downloadStateSubject.send(.completed)
                self?.downloadTask = nil
            }
            
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.downloadStateSubject.send(.failed(error: error.localizedDescription))
                self?.downloadTask = nil
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error else { return }
        
        DispatchQueue.main.async { [weak self] in
            self?.downloadStateSubject.send(.failed(error: error.localizedDescription))
            self?.downloadTask = nil
        }
    }
}

