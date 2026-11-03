//
//  PropertyListItem.swift
//  Baymax
//
//  Created by Simon Mitchell on 08/04/2020.
//  Copyright © 2020 3 SIDED CUBE. All rights reserved.
//

import Foundation

struct PropertyListItem {
    
    var key: String?
    
    var value: PlistValue?
    
    var children: [PropertyListItem]?
    
    init(with key: String?, value: PlistValue?) {
        
        self.key = key
        self.value = value
        
        guard let value = value else { return }
        
        // There are compiler warnings here... but they don't actually fail like the warnings say!
        if let childArray = value as? [PlistValue] {
            children = childArray.enumerated().compactMap({ PropertyListItem(with: "Element \($0.offset)", value: $0.element) })
        } else if let childDictionary = value as? [AnyHashable: PlistValue] {
            children = childDictionary.keys.compactMap({ PropertyListItem(with: "\($0)", value: childDictionary[$0]) })
        }
    }
}
