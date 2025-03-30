//
//  VideoListViewModelTests.swift
//  KlutchShotsChallenge
//
//  Created by Marco Siracusano on 30/03/2025.
//

import XCTest
import Combine
@testable import KlutchShotsChallenge

final class VideoListViewModelTests: XCTestCase {
    
    private var sut: VideoListViewModel!
    private var mockNetworkingService: MockNetworkingService!
    private var cancellables = Set<AnyCancellable>()
    
    override func setUp() {
        super.setUp()
        mockNetworkingService = MockNetworkingService()
        sut = VideoListViewModel(networking: mockNetworkingService)
    }
    
    override func tearDown() {
        cancellables.removeAll()
        sut = nil
        mockNetworkingService = nil
        super.tearDown()
    }
    
    // MARK: - Successful Data Loading
    func testFetchVideos_WhenSuccessful_UpdatesVideosCollection() {
        // Given
        let mockVideos = [
            Video.example,
            Video(
                id: "2",
                title: "Another Example",
                thumbnailUrl: "https://example.com/image.jpg",
                duration: "5:30",
                uploadTime: "2022-02-15",
                views: "500",
                author: "Jane Smith",
                videoUrl: "https://example.com/video2.mp4",
                description: "Another test video",
                subscriber: "200",
                isLive: true
            )
        ]
        
        mockNetworkingService.mockResult = .success(mockVideos)
        
        let expectation = expectation(description: "Videos loaded")
        
        // When
        sut.$videos
            .dropFirst() // Skip initial nil
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)
        
        sut.fetchVideos()
        
        // Then
        waitForExpectations(timeout: 1.0)
        
        XCTAssertEqual(sut.videos.count, 2)
        XCTAssertEqual(sut.videos[0].id, "1")
        XCTAssertEqual(sut.videos[1].id, "2")
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }
    
    // MARK: - Loading State
    func testFetchVideos_SetsLoadingState() {
        // Given
        mockNetworkingService.mockDelay = 0.5
        mockNetworkingService.mockResult = .success([Video.example])
        
        // When
        sut.fetchVideos()
        
        // Then
        XCTAssertTrue(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }
    
    func testFetchVideos_ResetsErrorMessage() {
        // Given
        sut.errorMessage = "Previous error"
        mockNetworkingService.mockResult = .success([Video.example])
        
        // When
        sut.fetchVideos()
        
        // Then
        XCTAssertNil(sut.errorMessage)
    }
    
    // MARK: - Error Handling
    func testFetchVideos_WhenInvalidURL_SetsAppropriateErrorMessage() {
        // Given
        mockNetworkingService.mockResult = .failure(NetworkError.invalidURL)
        let expectation = expectation(description: "Error message set")
        
        // When
        sut.$errorMessage
            .dropFirst() // Skip initial nil
            .first { $0 != nil }
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)
        
        sut.fetchVideos()
        
        // Then
        waitForExpectations(timeout: 1.0)
        
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage?.contains("Invalid API URL") ?? false)
    }
    
    func testFetchVideos_WhenServerError_SetsAppropriateErrorMessage() {
        // Given
        mockNetworkingService.mockResult = .failure(NetworkError.serverError(statusCode: 503))
        let expectation = expectation(description: "Error message set")
        
        // When
        sut.$errorMessage
            .dropFirst() // Skip initial nil
            .first { $0 != nil }
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)
        
        sut.fetchVideos()
        
        // Then
        waitForExpectations(timeout: 1.0)
        
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage?.contains("Server error 503") ?? false)
    }
    
    func testFetchVideos_WhenDecodingError_SetsAppropriateErrorMessage() {
        // Given
        let decodingError = NSError(domain: "DecodingError", code: 1)
        mockNetworkingService.mockResult = .failure(NetworkError.decodingError(decodingError))
        let expectation = expectation(description: "Error message set")
        
        // When
        sut.$errorMessage
            .dropFirst() // Skip initial nil
            .first { $0 != nil }
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)
        
        sut.fetchVideos()
        
        // Then
        waitForExpectations(timeout: 1.0)
        
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage?.contains("Failed to process the server response") ?? false)
    }
    
    func testFetchVideos_WhenUnknownError_SetsAppropriateErrorMessage() {
        // Given
        let unknownError = NSError(domain: "UnknownError", code: 999)
        mockNetworkingService.mockResult = .failure(NetworkError.unknownError(unknownError))
        let expectation = expectation(description: "Error message set")
        
        // When
        sut.$errorMessage
            .dropFirst() // Skip initial nil
            .first { $0 != nil }
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)
        
        sut.fetchVideos()
        
        // Then
        waitForExpectations(timeout: 1.0)
        
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage?.contains("An unexpected error occurred") ?? false)
    }
    
    func testFetchVideos_WhenGenericError_SetsGenericErrorMessage() {
        // Given
        let genericError = NSError(domain: "TestError", code: 123, userInfo: [NSLocalizedDescriptionKey: "Something went wrong"])
        mockNetworkingService.mockResult = .failure(genericError)
        let expectation = expectation(description: "Error message set")
        
        // When
        sut.$errorMessage
            .dropFirst() // Skip initial nil
            .first { $0 != nil }
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)
        
        sut.fetchVideos()
        
        // Then
        waitForExpectations(timeout: 1.0)
        
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage?.contains("Failed to load videos") ?? false)
        XCTAssertTrue(sut.errorMessage?.contains("Something went wrong") ?? false)
    }
}
