//
//  KlutchShotsChallengeApp.swift
//  KlutchShotsChallenge
//
//  Created by Marco Siracusano on 27/03/2025.
//

import SwiftUI

@main
struct KlutchShotsChallengeApp: App {

    private let dependencies: DependenciesProtocol = Dependencies()

    var body: some Scene {
        WindowGroup {
            VideoListView(viewModel: .init(networking: dependencies.networkingService))
                .environment(\.dependencies, dependencies)
        }
    }
}
