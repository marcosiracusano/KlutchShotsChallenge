//
//  MockFileManager.swift
//  KlutchShotsChallenge
//
//  Created by Marco Siracusano on 30/03/2025.
//

import Foundation

final class MockFileManager: FileManagerProtocol {
    var mockURLs: [URL] = [URL(fileURLWithPath: "/mock/documents")]
    var fileExistsResult: Bool = false
    var removeItemCalled: Bool = false
    var removeItemShouldThrow: Bool = false
    var moveItemCalled: Bool = false
    var moveItemShouldThrow: Bool = false
    
    var lastPathChecked: String?
    var lastRemovedURL: URL?
    var lastSourceURL: URL?
    var lastDestinationURL: URL?
    
    func urls(for directory: FileManager.SearchPathDirectory, in domainMask: FileManager.SearchPathDomainMask) -> [URL] {
        mockURLs
    }
    
    func fileExists(atPath path: String) -> Bool {
        lastPathChecked = path
        return fileExistsResult
    }
    
    func removeItem(at url: URL) throws {
        removeItemCalled = true
        lastRemovedURL = url
        
        if removeItemShouldThrow {
            throw NSError(domain: "MockFileManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error removing item"])
        }
    }
    
    func moveItem(at srcURL: URL, to dstURL: URL) throws {
        moveItemCalled = true
        lastSourceURL = srcURL
        lastDestinationURL = dstURL
        
        if moveItemShouldThrow {
            throw NSError(domain: "MockFileManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Mock error moving item"])
        }
    }
}
