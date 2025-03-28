//
//  Video.swift
//  KlutchShotsChallenge
//
//  Created by Marco Siracusano on 27/03/2025.
//

import Foundation

struct Video: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let thumbnailUrl: String
    let duration: String
    let uploadTime: String
    let views: String
    let author: String
    let videoUrl: String
    let description: String
    let subscriber: String
    let isLive: Bool
}

extension Video {
    static let example = Video(
        id: "1",
        title: "Example Video",
        thumbnailUrl: "https://via.placeholder.com/150",
        duration: "10:00",
        uploadTime: "2021-01-01",
        views: "1000",
        author: "John Doe",
        videoUrl: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
        description: "This is an example video",
        subscriber: "1000",
        isLive: false
    )
}
