//
//  MockURLSession.swift
//  KlutchShotsChallenge
//
//  Created by Marco Siracusano on 30/03/2025.
//

import Foundation

class MockURLSession: URLSessionProtocol {
    var dataToReturn: Data?
    var responseToReturn: URLResponse?
    var errorToThrow: Error?
    
    func data(from url: URL) async throws -> (Data, URLResponse) {
        if let error = errorToThrow {
            throw error
        }
        
        guard let data = dataToReturn, let response = responseToReturn else {
            throw NSError(domain: "MockURLSession", code: -999, userInfo: [NSLocalizedDescriptionKey: "Mock not configured properly"])
        }
        
        return (data, response)
    }
    
    func mockSuccessResponse(with data: Data, statusCode: Int = 200, url: URL) {
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        
        dataToReturn = data
        responseToReturn = response
        errorToThrow = nil
    }
    
    func mockFailureResponse(with error: Error) {
        errorToThrow = error
        dataToReturn = nil
        responseToReturn = nil
    }
    
    func mockHTTPResponse(url: URL, statusCode: Int, data: Data = Data()) {
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        
        dataToReturn = data
        responseToReturn = response
        errorToThrow = nil
    }
}
