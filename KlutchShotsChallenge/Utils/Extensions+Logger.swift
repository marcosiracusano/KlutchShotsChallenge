//
//  Logger.swift
//  KlutchShotsChallenge
//
//  Created by Marco Siracusano on 29/03/2025.
//

import OSLog

extension Logger {
    /// The app's bundle identifier used as a subsystem for all loggers.
    private static let subsystem = Bundle.main.bundleIdentifier!
    
    /// The main logger for general app-wide logging.
    /// Use this logger for default or general purpose logging throughout the app.
    static let main = Logger(subsystem: subsystem, category: "Main")
    
    /// Logger for all networking-related activities.
    /// Use this logger for API calls, data transfers, and other network operations.
    static let networking = Logger(subsystem: subsystem, category: "Networking")

    /// Logger for all download-related activities.
    /// Use this logger for download operations, including progress updates and errors.
    static let download = Logger(subsystem: subsystem, category: "Download")    
}
