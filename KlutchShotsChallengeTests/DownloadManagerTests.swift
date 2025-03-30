//
//  DownloadManagerTests.swift
//  KlutchShotsChallenge
//
//  Created by Marco Siracusano on 30/03/2025.
//

import XCTest
import Combine
@testable import KlutchShotsChallenge

final class DownloadManagerTests: XCTestCase {
    
    private var sut: DownloadManager!
    private var mockFileManager: MockFileManager!
    private var cancellables = Set<AnyCancellable>()
    
    override func setUp() {
        super.setUp()
        mockFileManager = MockFileManager()
        sut = DownloadManager(fileManager: mockFileManager)
    }
    
    override func tearDown() {
        sut = nil
        mockFileManager = nil
        cancellables.removeAll()
        super.tearDown()
    }
    
    // MARK: - videoExists Tests
    func testVideoExists_WhenFileExists_ReturnsTrue() {
        // Given
        let videoId = "test_video_123"
        mockFileManager.fileExistsResult = true
        
        // When
        let result = sut.videoExists(for: videoId)
        
        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(mockFileManager.lastPathChecked?.hasSuffix("\(videoId).mp4"), true)
    }
    
    func testVideoExists_WhenFileDoesNotExist_ReturnsFalse() {
        // Given
        let videoId = "test_video_123"
        mockFileManager.fileExistsResult = false
        
        // When
        let result = sut.videoExists(for: videoId)
        
        // Then
        XCTAssertFalse(result)
        XCTAssertEqual(mockFileManager.lastPathChecked?.hasSuffix("\(videoId).mp4"), true)
    }
    
    // MARK: - getLocalURL Tests
    func testGetLocalURL_ReturnsCorrectURL() {
        // Given
        let videoId = "test_video_123"
        
        // When
        let url = sut.getLocalURL(for: videoId)
        
        // Then
        XCTAssertEqual(url?.path, "/mock/documents/\(videoId).mp4")
    }
    
    func testGetLocalURL_WhenNoDocumentsDirectory_ReturnsNil() {
        // Given
        let videoId = "test_video_123"
        mockFileManager.mockURLs = []
        
        // When
        let url = sut.getLocalURL(for: videoId)
        
        // Then
        XCTAssertNil(url)
    }
    
    // MARK: - deleteDownloadedVideo Tests
    func testDeleteDownloadedVideo_WhenFileExists_DeletesAndReturnsNotStarted() {
        // Given
        let videoId = "test_video_123"
        let expectation = XCTestExpectation(description: "Delete video expectation")
        mockFileManager.fileExistsResult = true
        
        var resultState: DownloadState?
        
        // When
        sut.deleteDownloadedVideo(videoId: videoId)
            .sink { state in
                resultState = state
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(resultState, .notStarted)
        XCTAssertTrue(mockFileManager.removeItemCalled)
        XCTAssertEqual(mockFileManager.lastRemovedURL?.path.hasSuffix("\(videoId).mp4"), true)
    }
    
    func testDeleteDownloadedVideo_WhenFileDoesNotExist_ReturnsFailed() {
        // Given
        let videoId = "test_video_123"
        let expectation = XCTestExpectation(description: "Delete non-existent video expectation")
        mockFileManager.fileExistsResult = false
        
        var resultState: DownloadState?
        
        // When
        sut.deleteDownloadedVideo(videoId: videoId)
            .sink { state in
                resultState = state
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        
        if case .failed(_, let type) = resultState {
            XCTAssertEqual(type, .deletion)
        } else {
            XCTFail("Expected .failed state but got \(String(describing: resultState))")
        }
        XCTAssertFalse(mockFileManager.removeItemCalled)
    }
    
    func testDeleteDownloadedVideo_WhenRemoveItemThrows_ReturnsFailed() {
        // Given
        let videoId = "test_video_123"
        let expectation = XCTestExpectation(description: "Delete video with error expectation")
        mockFileManager.fileExistsResult = true
        mockFileManager.removeItemShouldThrow = true
        
        var resultState: DownloadState?
        
        // When
        sut.deleteDownloadedVideo(videoId: videoId)
            .sink { state in
                resultState = state
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        
        if case .failed(_, let type) = resultState {
            XCTAssertEqual(type, .deletion)
        } else {
            XCTFail("Expected .failed state but got \(String(describing: resultState))")
        }
        XCTAssertTrue(mockFileManager.removeItemCalled)
    }
    
    // MARK: - getPlaybackURL Tests
    func testGetPlaybackURL_WhenLocalFileExists_ReturnsLocalURL() {
        // Given
        let videoId = "test_video_123"
        let fallbackUrl = "https://example.com/video.mp4"
        mockFileManager.fileExistsResult = true
        
        // When
        let url = sut.getPlaybackURL(for: videoId, fallbackUrl: fallbackUrl)
        
        // Then
        XCTAssertEqual(url?.path, "/mock/documents/\(videoId).mp4")
    }
    
    func testGetPlaybackURL_WhenLocalFileDoesNotExist_ReturnsFallbackURL() {
        // Given
        let videoId = "test_video_123"
        let fallbackUrl = "https://example.com/video.mp4"
        mockFileManager.fileExistsResult = false
        
        // When
        let url = sut.getPlaybackURL(for: videoId, fallbackUrl: fallbackUrl)
        
        // Then
        XCTAssertEqual(url?.absoluteString, fallbackUrl)
    }
    
    // MARK: - downloadVideo Tests
    func testDownloadVideo_WhenVideoAlreadyExists_ReturnsCompletedState() {
        // Given
        let videoId = "test_video_123"
        let url = URL(string: "https://example.com/video.mp4")!
        let expectation = XCTestExpectation(description: "Download existing video expectation")
        mockFileManager.fileExistsResult = true
        
        var resultState: DownloadState?
        
        // When
        sut.downloadVideo(videoId, from: url)
            .sink { state in
                resultState = state
                if state == .completed {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(resultState, .completed)
    }
    
    func testCancelDownload_ResetsStateAndVideoId() {
        // Given
        let videoId = "test_video_123"
        let url = URL(string: "https://example.com/video.mp4")!
        mockFileManager.fileExistsResult = false
        
        let downloadExpectation = XCTestExpectation(description: "Start download expectation")
        let cancelExpectation = XCTestExpectation(description: "Cancel download expectation")
        
        var states: [DownloadState] = []
        
        sut.downloadVideo(videoId, from: url)
            .sink { state in
                states.append(state)
                if state.isDownloading {
                    downloadExpectation.fulfill()
                }
                if case .notStarted = state, states.count > 1 {
                    cancelExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        wait(for: [downloadExpectation], timeout: 1.0)
        sut.cancelDownload()
        
        // Then
        wait(for: [cancelExpectation], timeout: 1.0)
        
        XCTAssertEqual(states.first?.isDownloading, true)
        XCTAssertEqual(states.last, .notStarted)
        XCTAssertNil(sut.currentVideoId)
    }
}
