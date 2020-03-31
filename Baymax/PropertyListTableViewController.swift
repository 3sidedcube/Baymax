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
        
        if ((property?.children) != nil) {
            cell.accessoryType = .disclosureIndicator
            cell.valueLabel?.text = nil
        } else {
            cell.accessoryType = .none
            cell.valueLabel?.text = ValueConverter.string(for: property?.value)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        guard (properties?[indexPath.row].children) != nil else {
            return
        }
        
        let view = PropertyListTableViewController(style: .grouped)
        view.properties = properties?[indexPath.row].children
        navigationController?.show(view, sender: self)
    }
}

struct PropertyListItem {
    
    var key: String?
    var value: Any?
    var children: [PropertyListItem]?
    
    init(with key: String?, value: Any) {
        
        self.key = key
        
        if let childArray = value as? [Any] {
            children = childArray.compactMap({PropertyListItem(with: nil, value: $0)})
        } else if let childDictionary = value as? [String: Any] {
            children = childDictionary.keys.compactMap({PropertyListItem(with: $0, value: childDictionary[$0] as Any)})
        } else {
            self.value = value
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
        
        let view = PropertyListTableViewController(style: .grouped)
        view.properties = dictionary.keys.compactMap({PropertyListItem(with: $0, value: dictionary[$0] as Any)})
        navigationController.show(view, sender: self)
    }
}
