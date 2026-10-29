//
//  LogDetailViewController.swift
//  Baymax
//
//  Created by Simon Mitchell on 01/04/2020.
//  Copyright © 2020 3 SIDED CUBE. All rights reserved.
//

import UIKit

class LogDetailViewController: UIViewController {
    
    let file: LogFile
    
    init(logfile: LogFile) {
        file = logfile
        super.init(nibName: nil, bundle: nil)
        title = file.url.lastPathComponent
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func share(_ sender: UIBarButtonItem) {
        
        guard let shareHandler = LogsTool.shareHandler else {
            shareLogFilesDefault([file], sender: sender)
            return
        }
        
        // If we were told by share handler that it couldn't handle the files, then fallback to default!
        guard shareHandler([file], sender) == false else {
            return
        }
        
        shareLogFilesDefault([file], sender: sender)
    }
    
    private func shareLogFilesDefault(_ logFiles: [LogFile], sender: Any?) {
        let activityViewController = UIActivityViewController(activityItems: logFiles.map({ $0.url }), applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = sender as? UIView ?? view
        activityViewController.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
        
        present(activityViewController, animated: true, completion: nil)
    }
    
    private lazy var textView: UITextView = UITextView()
    
    override func viewDidLoad() {
        
        toolbarItems = [UIBarButtonItem(image: (#imageLiteral(resourceName: "share") as BaymaxImageLiteral).image, style: .plain, target: self, action: #selector(share(_:)))]
        
        super.viewDidLoad()

        textView.frame = view.bounds
        if let text = try? String(contentsOf: file.url) {
            textView.text = text
        } else {
            textView.text = "Failed to load file"
        }
        
        textView.isEditable = false
        view.addSubview(textView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        textView.frame = view.bounds
    }
}
