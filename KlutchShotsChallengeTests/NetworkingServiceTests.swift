//
//  NetworkingServiceTests.swift
//  KlutchShotsChallenge
//
//  Created by Marco Siracusano on 30/03/2025.
//

import XCTest
@testable import KlutchShotsChallenge

final class NetworkingServiceTests: XCTestCase {
    
    private var mockURLSession: MockURLSession!
    private var sut: NetworkingService!
    
    private let validVideosJSON = """
    [
        {
            "id": "1",
            "title": "Example Video",
            "thumbnailUrl": "https://example.com/thumbnail1.jpg",
            "duration": "10:00",
            "uploadTime": "2021-01-01",
            "views": "1000",
            "author": "John Doe",
            "videoUrl": "http://example.com/video1.mp4",
            "description": "This is an example video",
            "subscriber": "1000",
            "isLive": false
        },
        {
            "id": "2",
            "title": "Another Video",
            "thumbnailUrl": "https://example.com/thumbnail2.jpg",
            "duration": "05:30",
            "uploadTime": "2021-02-15",
            "views": "2500",
            "author": "Jane Smith",
            "videoUrl": "http://example.com/video2.mp4",
            "description": "This is another example video",
            "subscriber": "2000",
            "isLive": true
        }
    ]
    """.data(using: .utf8)!
    
    private let invalidJSON = """
    [
        {
            "id": "1",
            "title": 123,
            "wrongField": "This will cause a decoding error"
        }
    ]
    """.data(using: .utf8)!
    
    override func setUp() {
        super.setUp()
        mockURLSession = MockURLSession()
        sut = NetworkingService(session: mockURLSession)
    }
    
    override func tearDown() {
        mockURLSession = nil
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Success Case
    func testFetchVideos_WhenResponseSuccessful_ReturnsVideos() async throws {
        // Given
        guard let url = URL(string: Constants.apiUrl) else {
            XCTFail("Invalid API URL in Constants")
            return
        }
        
        mockURLSession.mockSuccessResponse(with: validVideosJSON, url: url)
        
        // When
        let videos = try await sut.fetchVideos()
        
        // Then
        XCTAssertEqual(videos.count, 2)
        XCTAssertEqual(videos[0].id, "1")
        XCTAssertEqual(videos[0].title, "Example Video")
        XCTAssertEqual(videos[1].id, "2")
        XCTAssertEqual(videos[1].title, "Another Video")
    }
    
    // MARK: - Error Cases
    func testFetchVideos_WhenInvalidURL_ThrowsInvalidURLError() async {
        // Create a custom NetworkingService with an invalid URL for testing
        let invalidURLService = NetworkingService(
            session: mockURLSession,
            apiUrl: "htt p://invalid url"
        )
        
        // When/Then
        do {
            _ = try await invalidURLService.fetchVideos()
            XCTFail("Expected invalid URL error but got success")
            
        } catch {
            XCTAssertTrue(error is NetworkError, "Expected NetworkError but got \(type(of: error))")
            if let networkError = error as? NetworkError {
                switch networkError {
                case .invalidURL:
                    // Test passed
                    break
                default:
                    XCTFail("Expected .invalidURL but got \(networkError)")
                }
            }
        }
    }
    
    func testFetchVideos_WhenServerError_ThrowsServerError() async {
        // Given
        guard let url = URL(string: Constants.apiUrl) else {
            XCTFail("Invalid API URL in Constants")
            return
        }
        
        mockURLSession.mockHTTPResponse(url: url, statusCode: 500)
        
        // When/Then
        do {
            _ = try await sut.fetchVideos()
            XCTFail("Expected server error but got success")
            
        } catch {
            XCTAssertTrue(error is NetworkError, "Expected NetworkError but got \(type(of: error))")
            if let networkError = error as? NetworkError {
                switch networkError {
                case .serverError(let statusCode):
                    XCTAssertEqual(statusCode, 500)
                default:
                    XCTFail("Expected .serverError but got \(networkError)")
                }
            }
        }
    }
    
    func testFetchVideos_WhenDecodingError_ThrowsDecodingError() async {
        // Given
        guard let url = URL(string: Constants.apiUrl) else {
            XCTFail("Invalid API URL in Constants")
            return
        }
        
        mockURLSession.mockSuccessResponse(with: invalidJSON, url: url)
        
        // When/Then
        do {
            _ = try await sut.fetchVideos()
            XCTFail("Expected decoding error but got success")
        } catch {
            XCTAssertTrue(error is NetworkError, "Expected NetworkError but got \(type(of: error))")
            if let networkError = error as? NetworkError {
                switch networkError {
                case .decodingError:
                    // Test passed
                    break
                default:
                    XCTFail("Expected .decodingError but got \(networkError)")
                }
            }
        }
    }
    
    func testFetchVideos_WhenNetworkError_ThrowsUnknownError() async {
        // Given
        let networkError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        mockURLSession.mockFailureResponse(with: networkError)
        
        // When/Then
        do {
            _ = try await sut.fetchVideos()
            XCTFail("Expected network error but got success")
        } catch {
            XCTAssertTrue(error is NetworkError, "Expected NetworkError but got \(type(of: error))")
            if let networkError = error as? NetworkError {
                switch networkError {
                case .unknownError:
                    // Test passed
                    break
                default:
                    XCTFail("Expected .unknownError but got \(networkError)")
                }
            }
        }
    }
}
