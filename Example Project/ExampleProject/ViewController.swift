//
//  ViewController.swift
//  BaymaxText
//
//  Created by Simon Mitchell on 31/03/2020.
//  Copyright © 2020 3 Sided Cube. All rights reserved.
//

import UIKit
import Baymax

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func triggerBaymax(_ sender: Any) {
        DiagnosticsManager.shared.presentDiagnosticsView()
    }
}

