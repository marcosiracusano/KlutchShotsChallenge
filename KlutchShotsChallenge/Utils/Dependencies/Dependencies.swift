//
//  Dependencies.swift
//  KlutchShotsChallenge
//
//  Created by Marco Siracusano on 29/03/2025.
//

import Foundation
import SwiftUICore

protocol DependenciesProtocol {
    var downloadManager: DownloadManagerProtocol { get }
    var networkingService: NetworkingProtocol { get }
}

final class Dependencies: DependenciesProtocol {
    lazy var downloadManager: DownloadManagerProtocol = {
        DownloadManager()
    }()
    
    lazy var networkingService: NetworkingProtocol = {
        NetworkingService()
    }()
}

extension EnvironmentValues {
    @Entry var dependencies: DependenciesProtocol = Dependencies()
}
