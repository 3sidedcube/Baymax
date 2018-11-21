//
//  Utilities.swift
//  Baymax
//
//  Created by Matthew Cheetham on 13/11/2018.
//  Copyright © 2018 3 SIDED CUBE. All rights reserved.
//

import Foundation

class ValueConverter {
    
    class func string(for obscureValue: Any?) -> String? {
        
        if let stringValue = obscureValue as? String {
            return stringValue
        }
        
        if let boolValue = obscureValue as? Bool {
            return boolValue == true ? "True" : "False"
        }
        
        if let numberValue = obscureValue as? NSNumber {
            return numberValue.stringValue
        }
        
        return nil
    }
}
