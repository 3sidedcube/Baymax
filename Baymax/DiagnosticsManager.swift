//
//  DiagnosticsManager.swift
//  Baymax
//
//  Created by Matthew Cheetham on 09/11/2018.
//  Copyright © 2018 3 SIDED CUBE. All rights reserved.
//

import Foundation

/// Shared singleton responsible for handling registration of providers
public class DiagnosticsManager {
    
    /// A closure called when the app requests to present the diagnostics tools. This should handle bespoke app authenticaiton for the tool
    public typealias AuthenticationRequestClosure = (_ completion: @escaping AuthenticationCompletionClosure) -> Void
    
    /// A closure called by the host app when authentication has completed or failed
    public typealias AuthenticationCompletionClosure = (_ authenticated: Bool) -> Void
    
    /// When the diagnostic tool has been assigned to a window, the authentication closure is stored here until required
    private var authenticationRequestClosure: AuthenticationRequestClosure?
    
    /// A shared instance of the diagnostics manager
    public static let sharedInstance = DiagnosticsManager()
    
    /// An internal record of all registered diagnostic providers
    private var _diagnosticProviders = [DiagnosticsServiceProvider]()
    
    /// The window that should be used to present the diagnostics view when using the `attachTo` method
    private var hostWindow: UIWindow?
    
    /// Handles the gesture recogniser delegate, we have to do this as it must be an obj-c object and this class is not
    private let gestureDelegateHandler = GestureDelegateHandler()
    
    /// Diagnostic providers filtered to remove any blacklisted providers
    var diagnosticProviders: [DiagnosticsServiceProvider] {
        return _diagnosticProviders.filter { (provider) -> Bool in
            return !blacklistedServices.contains(where: { $0 == type(of: provider) })
        }
    }
    
    /// An array of services types that should not be displayed. This is useful as tools in frameworks can register themselves
    private var blacklistedServices = [DiagnosticsServiceProvider.Type]()
    
    /// Registers a diagnostic tool provider to display in the diagnostic list
    ///
    /// - Parameter provider: The provider to register
    public func register(provider: DiagnosticsServiceProvider) {
        _diagnosticProviders.append(provider)
    }
    
    /// Blacklists a diagnostic tool provider and ensures it does not display in the list
    ///
    /// - Parameter provider: The provider to blacklist
    public func blacklist(provider: DiagnosticsServiceProvider.Type) {
        blacklistedServices.append(provider)
    }
    
    /// Attaches the diagnostics view to this window. The gesture recogniser will be attached and optionally hidden behind authentication
    ///
    /// - Parameters:
    ///   - window: The window to attach the gesture recogniser to
    ///   - authenticationHandler: A closure that you should use to handle authentication, if desired
    public func attach(to window: UIWindow, authenticationHandler: AuthenticationRequestClosure? = nil) {
        
        DiagnosticsManager.sharedInstance.register(provider: BaymaxServices())
        
        hostWindow = window
        authenticationRequestClosure = authenticationHandler
        
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture))
        swipeGesture.numberOfTouchesRequired = 4
        swipeGesture.direction = .up
        swipeGesture.delegate = gestureDelegateHandler
        
        window.addGestureRecognizer(swipeGesture)
    }
    
    /// Handles the swipe gesture recogniser on the window, if assigned
    @objc private func handleSwipeGesture() {
        
        guard let authenticationHandler = authenticationRequestClosure else {
            
            presentDiagnosticsView()
            return
        }
        
        authenticationHandler({ [weak self] authenticated in
            
            if authenticated {
                self?.presentDiagnosticsView()
            }
        })
    }
    
    /// Presents the diagnostics view
    private func presentDiagnosticsView() {
        
        guard let viewController = hostWindow?.rootViewController else {
            return
        }
        
        let diagnosticsView = DiagnosticsMenuTableViewController()
        
        let navigationWrappedDiagnosticsView = UINavigationController(rootViewController: diagnosticsView)
        
        viewController.present(navigationWrappedDiagnosticsView, animated: true, completion: nil)
    }
}

fileprivate class GestureDelegateHandler: NSObject, UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
