//
//  LogFile.swift
//  Baymax
//
//  Created by Simon Mitchell on 01/04/2020.
//  Copyright © 2020 3 SIDED CUBE. All rights reserved.
//

import Foundation

/// A simple representation of a log file
public struct LogFile {
    
    /// The file's url
    public let url: URL
    
    /// The date the file was created
    public let creationDate: Date
    
    /// The size of the file in bytes
    public let fileSize: Int?
}
