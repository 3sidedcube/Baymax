//
//  PropertyListTool.swift
//  Baymax
//
//  Created by Simon Mitchell on 08/04/2020.
//  Copyright © 2020 3 SIDED CUBE. All rights reserved.
//

import Foundation

public class PropertyListTool: DiagnosticTool {
    
    public var displayName: String {
        return "Property List Viewer"
    }
    
    public func launchUI(in navigationController: UINavigationController) {
        
        guard let dictionary = Bundle.main.infoDictionary else {
            return
        }
        let plistDictionary = dictionary.compactMapValues { (value) -> PlistValue? in
            return plistValueFrom(value)
        }
        let view = PropertyListTableViewController(style: .grouped)
        view.properties = plistDictionary.keys.sorted(by: { (key1, key2) -> Bool in
            return key1 < key2
        }).compactMap({
            PropertyListItem(with: $0, value: plistDictionary[$0])
        })
        navigationController.show(view, sender: self)
    }
}
