//
//  LogDetailViewController.swift
//  Baymax
//
//  Created by Simon Mitchell on 01/04/2020.
//  Copyright © 2020 3 SIDED CUBE. All rights reserved.
//

import UIKit

class LogDetailViewController: UIViewController {
    
    let file: LogFile?
    
    init(logfile: LogFile) {
        file = logfile
        super.init(nibName: nil, bundle: nil)
        title = file?.url.lastPathComponent
    }
    
    required init?(coder: NSCoder) {
        file = nil
        super.init(coder: coder)
    }
    
    @objc func share(_ sender: UIBarButtonItem) {
        guard let file = file else { return }
        let activityViewController = UIActivityViewController(activityItems: [file.url], applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = sender
        present(activityViewController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        
        toolbarItems = [UIBarButtonItem(image: (#imageLiteral(resourceName: "share") as BaymaxImageLiteral).image, style: .plain, target: self, action: #selector(share(_:)))]
        
        super.viewDidLoad()

        let textView = UITextView(frame: view.bounds)
        if let file = file, let text = try? String(contentsOf: file.url) {
            textView.text = text
        } else {
            textView.text = "Failed to load file"
        }
        
        view.addSubview(textView)
    }
}
