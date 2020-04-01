//
//  Log.swift
//  Baymax
//
//  Created by Simon Mitchell on 31/03/2020.
//  Copyright © 2020 3 SIDED CUBE. All rights reserved.
//

import Foundation
import os.log

/// Logs a string to a given instance of `Log`
/// - Parameters:
///   - message: The message to be logged
///   - subsystem: The subsystem of the log (Defaults to Bundle.main.bundleIdentifier)
///   - category: The category of the log
///   - log: The log to append to
///   - type: The type of the log
public func baymax_log(_ message: String, subsystem: String = Bundle.main.bundleIdentifier ?? "", category: String = "Default", log: Log = .shared, type: BaymaxLogType = .default) {
    let constructedMessage = "[\(type.rawValue.uppercased())] | \(subsystem) (\(category)) | \(message)"
    var _log = log
    print(constructedMessage, to: &_log)
}

/// Represents the level/type of a log message
public enum BaymaxLogType: String {
    case `default`
    case info
    case error = "warn"
    case debug
    case fault
}

extension DateFormatter {
    
    static var logFileNameFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "YYYY-MM-DD'T'hh:mm:ssZ"
        return formatter
    }
}

/// A log conforming to `TextOutputStream` that can be used in APIs such as swift's `print(_, to)`
public struct Logger: TextOutputStream {
    
    let formatter = ISO8601DateFormatter()
    
    /// A shared instance of a logger object, initialised with the current time stamp as the file name
    public static let shared = Logger(fileName: "\(DateFormatter.logFileNameFormatter.string(from: Date())).log")
    
    /// The file name that the logger will save to within the logs sub-directory
    public let fileName: String
    
    /// The search path directory the log will save to
    private let searchPathDirectory: FileManager.SearchPathDirectory
    
    /// The domain mask the log will save to
    private let domainMask: FileManager.SearchPathDomainMask
    
    private let fm = FileManager.default
    
    internal var directory: URL? {        
        guard let url = fm.urls(for: searchPathDirectory, in: domainMask).first else { return nil }
        return url.appendingPathComponent("baymax_logs", isDirectory: true)
    }
    
    /// Initialises a new logger object with the given file name in the search path and domain mask provided
    /// - Parameters:
    ///   - fileName: The name to give to the log file
    ///   - searchPathDirectory: The search path directory (defaults to documents directory)
    ///   - domainMask: The domain mask (defaults to user domain mask)
    public init(fileName: String, searchPathDirectory: FileManager.SearchPathDirectory = .documentDirectory, domainMask: FileManager.SearchPathDomainMask = .userDomainMask) {
        
        self.fileName = fileName
        self.searchPathDirectory = searchPathDirectory
        self.domainMask = domainMask
                
        setupDirectory()
    }
    
    private func setupDirectory() {
        // Setup directory for logs to be stored in!
        guard let directory = directory, !fm.fileExists(atPath: directory.path) else { return }
        try? fm.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
    }
    
    public func write(_ string: String) {
        
        guard UserDefaults.standard.baymaxLoggingEnabled else {
            return
        }
                
        var writeString = string
        
        if !writeString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            writeString = "\(formatter.string(from: Date())) \(writeString)"
        }
        
        guard let directory = directory else { return }
        let log = directory.appendingPathComponent(fileName)
        
        if let handle = try? FileHandle(forWritingTo: log) {
            handle.seekToEndOfFile()
            handle.write(writeString.data(using: .utf8)!)
            handle.closeFile()
        } else {
            try? writeString.data(using: .utf8)?.write(to: log)
        }
    }
}
