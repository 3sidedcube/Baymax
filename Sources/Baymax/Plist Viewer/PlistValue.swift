//
//  Utilities.swift
//  Baymax
//
//  Created by Matthew Cheetham on 13/11/2018.
//  Copyright © 2018 3 SIDED CUBE. All rights reserved.
//

import Foundation

/// A protocol we will use to conform classes which can be represented in an Info.plist to
protocol PlistValue {
    
    func toString() -> String
}

func plistValueFrom(_ value: Any) -> PlistValue? {
    
    if let string = value as? String {
        return string
    }
    
    if let boolean = value as? Bool {
        return boolean
    }
    
    if let number = value as? NSNumber {
        return number
    }
    
    if let date = value as? Date {
        return date
    }
    
    if let dictionary = value as? Dictionary<AnyHashable, Any> {
        return dictionary.compactMapValues { (value) -> PlistValue? in
            return plistValueFrom(value)
        }
    }
    
    if let array = value as? Array<Any> {
        return array.compactMap { (value) -> PlistValue? in
            return plistValueFrom(value)
        }
    }
    
    return nil
}

extension NSNumber: PlistValue {
    func toString() -> String {
        return stringValue
    }
}

extension Bool: PlistValue {
    func toString() -> String {
        return self ? "true" : "false"
    }
}

extension Date: PlistValue {
    func toString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        return dateFormatter.string(from: self)
    }
}

extension Array: PlistValue {
    func toString() -> String {
        return "Array (\(count))"
    }
}

extension Dictionary: PlistValue {
    func toString() -> String {
        return "Dictionary (\(count))"
    }
}

extension String: PlistValue {
    func toString() -> String {
        return self
    }
}
