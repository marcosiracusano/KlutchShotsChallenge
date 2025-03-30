//
//  VideoDetailViewModelTests.swift
//  KlutchShotsChallenge
//
//  Created by Marco Siracusano on 30/03/2025.
//

import XCTest
import AVFoundation
import Combine
@testable import KlutchShotsChallenge

final class VideoDetailViewModelTests: XCTestCase {

    private var sut: VideoDetailViewModel!
    private var mockDownloadManager: MockDownloadManager!
    private var cancellables = Set<AnyCancellable>()
    private let testVideoId = "test_video_123"
    private let testVideoUrl = "https://example.com/video.mp4"
    
    override func setUp() {
        super.setUp()
        mockDownloadManager = MockDownloadManager()
        sut = VideoDetailViewModel(downloadManager: mockDownloadManager)
    }
    
    override func tearDown() {
        sut.cleanUp()
        cancellables.removeAll()
        sut = nil
        mockDownloadManager = nil
        super.tearDown()
    }
    
    // MARK: - Video Loading Tests
    func testLoadVideo_CreatesPlayer() {
        // Given
        mockDownloadManager.mockPlaybackURL = URL(string: testVideoUrl)!
        
        // When
        sut.loadVideo(for: testVideoId, videoUrl: testVideoUrl)
        
        // Then
        XCTAssertNotNil(sut.player)
        XCTAssertEqual(mockDownloadManager.lastRequestedVideoId, testVideoId)
        XCTAssertEqual(mockDownloadManager.lastRequestedFallbackUrl, testVideoUrl)
        XCTAssertFalse(sut.isBuffering)
    }
    
    func testLoadVideo_WithEmptyParameters_SetsErrorMessage() {
        // When
        sut.loadVideo(for: "", videoUrl: "")
        
        // Then
        XCTAssertNil(sut.player)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage?.contains("Failed to obtain video ID") ?? false)
    }
    
    func testLoadVideo_WhenVideoExists_SetsPlayingFromLocalFile() {
        // Given
        mockDownloadManager.mockVideoExists = true
        mockDownloadManager.mockPlaybackURL = URL(fileURLWithPath: "/mock/documents/\(testVideoId).mp4")
        
        // When
        sut.loadVideo(for: testVideoId, videoUrl: testVideoUrl)
        
        // Then
        XCTAssertTrue(sut.isPlayingFromLocalFile)
        XCTAssertEqual(sut.downloadState, .completed)
    }
    
    func testLoadVideo_WhenVideoDoesNotExist_SetsPlayingFromStream() {
        // Given
        mockDownloadManager.mockVideoExists = false
        mockDownloadManager.mockPlaybackURL = URL(string: testVideoUrl)
        
        // When
        sut.loadVideo(for: testVideoId, videoUrl: testVideoUrl)
        
        // Then
        XCTAssertFalse(sut.isPlayingFromLocalFile)
        XCTAssertEqual(sut.downloadState, .notStarted)
    }
    
    func testLoadVideo_WhenPlaybackURLIsNil_SetsErrorMessage() {
        // Given
        mockDownloadManager.mockPlaybackURL = nil
        
        // When
        sut.loadVideo(for: testVideoId, videoUrl: testVideoUrl)
        
        // Then
        XCTAssertNil(sut.player)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage?.contains("Failed to obtain video URL") ?? false)
    }
    
    // MARK: - Download Handling Tests
    func testHandleDownload_WhenNotStarted_StartsDownload() {
        // Given
        let expectation = self.expectation(description: "Download started")
        mockDownloadManager.mockVideoExists = false
        mockDownloadManager.mockPlaybackURL = URL(string: testVideoUrl)
        mockDownloadManager.onDownloadVideoCalled = { videoId in
            XCTAssertEqual(videoId, self.testVideoId)
            expectation.fulfill()
        }
        sut.loadVideo(for: testVideoId, videoUrl: testVideoUrl)
        
        // When
        sut.handleDownload()
        
        // Then
        waitForExpectations(timeout: 1.0)
        mockDownloadManager.simulateStateUpdate(.downloading(progress: 0))
        XCTAssertTrue(mockDownloadManager.downloadVideoCalled)
        XCTAssertEqual(mockDownloadManager.lastDownloadedVideoId, testVideoId)
    }
    
    func testHandleDownload_WhenCompleted_ShowsDeleteAlert() {
        // Given
        mockDownloadManager.mockVideoExists = true
        mockDownloadManager.mockPlaybackURL = URL(fileURLWithPath: "/mock/documents/\(testVideoId).mp4")
        sut.loadVideo(for: testVideoId, videoUrl: testVideoUrl)
        
        // When
        sut.handleDownload()
        
        // Then
        XCTAssertTrue(sut.isShowingDeleteAlert)
    }
    
    func testDeleteDownloadedVideo_CallsDeleteOnDownloadManager() {
        // Given
        let expectation = self.expectation(description: "Video deleted")
        mockDownloadManager.mockVideoExists = true
        mockDownloadManager.mockPlaybackURL = URL(fileURLWithPath: "/mock/documents/\(testVideoId).mp4")
        mockDownloadManager.onDeleteDownloadedVideoCalled = { videoId in
            XCTAssertEqual(videoId, self.testVideoId)
            expectation.fulfill()
        }
        sut.loadVideo(for: testVideoId, videoUrl: testVideoUrl)
        
        
        // When
        sut.deleteDownloadedVideo()
        
        // Then
        waitForExpectations(timeout: 1.0)
        mockDownloadManager.simulateStateUpdate(.notStarted)
        XCTAssertTrue(mockDownloadManager.deleteDownloadedVideoCalled)
    }
    
    // MARK: - Download State Handling Tests
    func testDownloadStateHandling_WhenCompleted_SwitchesToLocalPlayback() {
        // Given
        let expectation = self.expectation(description: "Download completed")
        mockDownloadManager.mockVideoExists = false
        mockDownloadManager.mockPlaybackURL = URL(string: testVideoUrl)!
        mockDownloadManager.mockLocalURL = URL(fileURLWithPath: "/mock/documents/\(testVideoId).mp4")
        sut.loadVideo(for: testVideoId, videoUrl: testVideoUrl)
        
        // Observe isPlayingFromLocalFile changes
        sut.$isPlayingFromLocalFile
            .dropFirst() // Skip initial value
            .sink { isPlayingFromLocalFile in
                if isPlayingFromLocalFile {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        sut.handleDownload()
        
        // Simulate download completion
        mockDownloadManager.simulateStateUpdate(.completed)
        
        // Then
        waitForExpectations(timeout: 1.0)
        XCTAssertTrue(sut.isPlayingFromLocalFile)
        XCTAssertEqual(sut.downloadState, .completed)
    }
    
    func testDownloadStateHandling_WhenDeleted_SwitchesToStreamingPlayback() {
        // Given
        let expectation = self.expectation(description: "Video deleted")
        mockDownloadManager.mockVideoExists = true
        mockDownloadManager.mockPlaybackURL = URL(fileURLWithPath: "/mock/documents/\(testVideoId).mp4")
        sut.loadVideo(for: testVideoId, videoUrl: testVideoUrl)
        
        // Ensure we're starting from local playback
        XCTAssertTrue(sut.isPlayingFromLocalFile)
        
        // Observe isPlayingFromLocalFile changes
        sut.$isPlayingFromLocalFile
            .dropFirst() // Skip initial value
            .sink { isPlayingFromLocalFile in
                if !isPlayingFromLocalFile {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        sut.deleteDownloadedVideo()
        
        // Simulate delete completion
        mockDownloadManager.simulateStateUpdate(.notStarted)
        
        // Then
        waitForExpectations(timeout: 1.0)
        XCTAssertFalse(sut.isPlayingFromLocalFile)
        XCTAssertEqual(sut.downloadState, .notStarted)
    }
    
    func testDownloadStateHandling_WhenDownloadFails_SetsErrorMessage() {
        // Given
        let expectation = self.expectation(description: "Download failed")
        mockDownloadManager.mockVideoExists = false
        mockDownloadManager.mockPlaybackURL = URL(string: testVideoUrl)!
        sut.loadVideo(for: testVideoId, videoUrl: testVideoUrl)
        
        // Observe error message changes
        sut.$errorMessage
            .dropFirst()
            .first { $0 != nil }
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)
        
        // When
        sut.handleDownload()
        
        // Simulate download failure
        mockDownloadManager.simulateStateUpdate(.failed(error: "Network connection lost", type: .download))
        
        // Then
        waitForExpectations(timeout: 1.0)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage?.contains("Download failed") ?? false)
        XCTAssertEqual(sut.downloadState, .notStarted)
    }
    
    func testDownloadStateHandling_WhenDeletionFails_SetsErrorMessage() {
        // Given
        let expectation = self.expectation(description: "Deletion failed")
        mockDownloadManager.mockVideoExists = true
        mockDownloadManager.mockPlaybackURL = URL(fileURLWithPath: "/mock/documents/\(testVideoId).mp4")
        sut.loadVideo(for: testVideoId, videoUrl: testVideoUrl)
        
        // Observe error message changes
        sut.$errorMessage
            .dropFirst()
            .first { $0 != nil }
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)
        
        // When
        sut.deleteDownloadedVideo()
        
        // Simulate delete failure
        mockDownloadManager.simulateStateUpdate(.failed(error: "Permission denied", type: .deletion))
        
        // Then
        waitForExpectations(timeout: 1.0)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage?.contains("Deletion failed") ?? false)
        XCTAssertEqual(sut.downloadState, .completed)
    }
    
    // MARK: - Cleanup Test
    func testCleanUp_ClearsPlayerAndCancelsDownload() {
        // Given
        mockDownloadManager.mockPlaybackURL = URL(string: testVideoUrl)
        sut.loadVideo(for: testVideoId, videoUrl: testVideoUrl)
        XCTAssertNotNil(sut.player)
        
        // When
        sut.cleanUp()
        
        // Then
        XCTAssertNil(sut.player)
        XCTAssertTrue(mockDownloadManager.cancelDownloadCalled)
    }
}
