//
//  Log.swift
//  Baymax
//
//  Created by Simon Mitchell on 31/03/2020.
//  Copyright © 2020 3 SIDED CUBE. All rights reserved.
//

import Foundation
import os.log

public func baymax_log(_ message: String, subsystem: String = Bundle.main.bundleIdentifier ?? "", category: String = "Default", log: Log = .shared, type: BaymaxLogType = .default) {
    let constructedMessage = "[\(type.rawValue.uppercased())] | \(subsystem) (\(category)) | \(message)"
    var _log = log
    print(constructedMessage, to: &_log)
}

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

public struct Log: TextOutputStream {
    
    let formatter = ISO8601DateFormatter()
    
    public static let shared = Log(fileName: "\(DateFormatter.logFileNameFormatter.string(from: Date())).log")
    
    public let fileName: String
    
    private let searchPathDirectory: FileManager.SearchPathDirectory
    
    private let domainMask: FileManager.SearchPathDomainMask
    
    private let fm = FileManager.default
    
    internal var directory: URL? {        
        guard let url = fm.urls(for: searchPathDirectory, in: domainMask).first else { return nil }
        return url.appendingPathComponent("baymax_logs", isDirectory: true)
    }
    
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
