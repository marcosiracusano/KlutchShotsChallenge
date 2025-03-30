//
//  KlutchShotsChallengeApp.swift
//  KlutchShotsChallenge
//
//  Created by Marco Siracusano on 27/03/2025.
//

import SwiftUI

@main
struct KlutchShotsChallengeApp: App {

    private let dependencies: DependenciesProtocol
    
    init() {
        self.dependencies = Dependencies()
        
        // Defined limits for the cache
        URLCache.shared = URLCache(
            memoryCapacity: 50 * 1024 * 1024,
            diskCapacity: 100 * 1024 * 1024,
            diskPath: "klutchshots_image_cache"
        )
    }

    var body: some Scene {
        WindowGroup {
            VideoListView(viewModel: .init(networking: dependencies.networkingService))
                .environment(\.dependencies, dependencies)
        }
    }
}
