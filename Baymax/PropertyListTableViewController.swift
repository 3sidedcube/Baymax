//
//  PropertyListTableViewController.swift
//  Baymax
//
//  Created by Matthew Cheetham on 12/11/2018.
//  Copyright © 2018 3 SIDED CUBE. All rights reserved.
//

import UIKit

class PropertyListTableViewController: UITableViewController {
    
    var properties: [PropertyListItem]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = false
        tableView.register(UINib(nibName: "InformationTableViewCell", bundle: Bundle(for: PropertyListTableViewController.self)), forCellReuseIdentifier: "propertyRow")
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return properties?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "propertyRow", for: indexPath) as! InformationTableViewCell
        
        let property = properties?[indexPath.row]
        
        cell.keyLabel?.text = property?.key
        cell.valueLabel?.text = property?.value?.toString()
        
        if ((property?.children) != nil) {
            
            cell.selectionStyle = .default
            cell.accessoryType = .disclosureIndicator
            
        } else {
            
            cell.selectionStyle = .none
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard (properties?[indexPath.row].children) != nil else {
            return
        }
        
        let nextViewController = PropertyListTableViewController(style: .grouped)
        // Sort by keys!
        nextViewController.properties = properties?[indexPath.row].children?.sorted(by: { (item1, item2) -> Bool in
            switch (item1.key, item2.key) {
            case (.some(let key1), .some(let key2)):
                return key1 < key2
            case (nil, .some(_)):
                return false
            case (.some(_), nil):
                return true
            case (nil, nil):
                return false
            }
        })
        nextViewController.title = properties?[indexPath.row].key
        navigationController?.show(nextViewController, sender: self)
    }
}

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

class PropertyListTool: DiagnosticTool {
    
    var displayName: String {
        return "Property List Viewer"
    }
    
    func launchUI(in navigationController: UINavigationController) {
        
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
