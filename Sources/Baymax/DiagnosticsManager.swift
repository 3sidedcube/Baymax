//
//  DiagnosticsManager.swift
//  Baymax
//
//  Created by Matthew Cheetham on 09/11/2018.
//  Copyright © 2018 3 SIDED CUBE. All rights reserved.
//

import UIKit

extension UIWindow {
    
    /// Returns the window's currently visible view controller
    var visibleViewController: UIViewController? {
        var top = self.rootViewController
        while true {
            if let presented = top?.presentedViewController {
                top = presented
            } else if let nav = top as? UINavigationController {
                top = nav.visibleViewController
            } else if let tab = top as? UITabBarController {
                top = tab.selectedViewController
            } else {
                break
            }
        }
        return top
    }
}

/// Shared singleton responsible for handling registration of providers
public class DiagnosticsManager {
    
    /// A closure called when the app requests to present the diagnostics tools. This should handle bespoke app authenticaiton for the tool
    public typealias AuthenticationRequestClosure = (_ completion: @escaping AuthenticationCompletionClosure) -> Void
    
    /// A closure called by the host app when authentication has completed or failed
    public typealias AuthenticationCompletionClosure = (_ authenticated: Bool) -> Void
    
    /// When the diagnostic tool has been assigned to a window, the authentication closure is stored here until required
    private var authenticationRequestClosure: AuthenticationRequestClosure?
    
    /// A shared instance of the diagnostics manager
    public static let shared = DiagnosticsManager()
    
    /// An internal record of all registered diagnostic providers
    private var _diagnosticProviders = [DiagnosticsServiceProvider]()
    
    /// The window that should be used to present the diagnostics view when using the `attachTo` method
    private var hostWindow: UIWindow?
    
    /// Handles the gesture recogniser delegate, we have to do this as it must be an obj-c object and this class is not
    private let gestureDelegateHandler = GestureDelegateHandler()

    /// The swipe gesture that opens Baymax. One instance, moved between windows, so attaching repeatedly never stacks gestures.
    private lazy var swipeGesture: UISwipeGestureRecognizer = {
        let gesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture))

        #if targetEnvironment(simulator)
        gesture.numberOfTouchesRequired = 2
        #else
        gesture.numberOfTouchesRequired = UIDevice.current.userInterfaceIdiom == .pad ? 3 : 4
        #endif

        gesture.direction = .up
        gesture.delegate = gestureDelegateHandler
        return gesture
    }()

    /// Whether `AppInfoServices` and `BaymaxServices` have been registered by `attach(to:)`
    private var hasRegisteredBaymaxServices = false

    /// Whether Baymax has been attached to a window
    public var isAttached: Bool {
        return hostWindow != nil
    }

    /// Whether this is a Live build. On a real device, a Live build lists only `.open` providers.
    ///
    /// `true` unless the app says otherwise, so an app that never sets it is treated as Live. Set it from the app's
    /// own environment, e.g. `DiagnosticsManager.shared.isLive = Environment.current == .live`.
    public var isLive = true

    /// Whether the app is running on the Simulator, where every provider is listed even in a Live build
    let isSimulator: Bool

    /// Whether passing the authentication handler given to `attach(to:)` also lists `.locked` providers in a Live build,
    /// as a non-Live build would. `false` unless the app opts in, e.g. an app gated by a staff-only Storm login:
    /// `DiagnosticsManager.shared.authenticationUnlocksLockedProviders = true`.
    ///
    /// - Important: Only opt in when the handler is a real staff login. Anyone who passes it sees every tool,
    ///   UserDefaults editing included, on the phone they're holding.
    public var authenticationUnlocksLockedProviders = false

    /// Whether the menu now open was reached by passing the authentication handler, with
    /// `authenticationUnlocksLockedProviders` on. Set on every presentation, so it never carries over to one that
    /// skipped authentication.
    private(set) var isUnlocked = false

    /// Whether `.locked` providers, and the app-supplied values in App & device info, are shown
    var showsLockedProviders: Bool {
        return !isLive || isSimulator || isUnlocked
    }

    /// Whether the entry controls are switched on (Simulator only; see `handleShake()`)
    let entryVisibility: EntryVisibility

    /// Internal so tests can use a fresh instance; apps use `shared`.
    init(entryVisibility: EntryVisibility = EntryVisibility(), isSimulator: Bool = DiagnosticsManager.runsOnSimulator) {
        self.entryVisibility = entryVisibility
        self.isSimulator = isSimulator
    }

    /// Whether this build runs on the Simulator
    static let runsOnSimulator: Bool = {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }()

    /// Switches the entry controls on or off. Called on a shake on the Simulator; ignored while Baymax isn't attached.
    func handleShake() {
        guard isAttached else { return }
        entryVisibility.toggle()
    }
    
    /// Diagnostic providers filtered to remove any hidden providers, and locked ones in a Live build on a device
    var diagnosticProviders: [DiagnosticsServiceProvider] {
        return _diagnosticProviders.filter { (provider) -> Bool in
            // Remove any tools from the service that are hidden, this also needs to be filtered out on display!
            let tools = availableTools(for: provider)
            // Only show the service if it's tools aren't all hidden!
            return !tools.isEmpty
                && !hiddenServices.contains(where: { $0 == type(of: provider) })
                && (showsLockedProviders || provider.access == .open)
        }
    }
    
    internal func availableTools(for serviceProvider: DiagnosticsServiceProvider) -> [DiagnosticTool] {
        return serviceProvider.diagnosticTools.filter({ (tool) -> Bool in
            !hiddenTools.contains(where: { $0 == type(of: tool) })
        })
    }
    
    /// An array of services types that should not be displayed. This is useful as tools in frameworks can register themselves
    private var hiddenServices = [DiagnosticsServiceProvider.Type]()
    
    /// An array of diagnostic tools that should not be displayed. This is useful if you only want to allow certain tools within a service.
    private var hiddenTools = [DiagnosticTool.Type]()
    
    /// Registers a diagnostic tool provider to display in the diagnostic list
    ///
    /// - Parameter provider: The provider to register
    public func register(provider: DiagnosticsServiceProvider) {
        _diagnosticProviders.append(provider)
    }
    
    /// Hides a diagnostic tool provider and ensures it does not display in the list
    ///
    /// - Parameter provider: The provider to hide
    public func hide(provider: DiagnosticsServiceProvider.Type) {
        hiddenServices.append(provider)
    }
    
    /// Hides an individual diagnostics tool and ensures it does not display in the list
    ///
    /// - Parameter tool: The tool to hide
    public func hide(tool: DiagnosticTool.Type) {
        hiddenTools.append(tool)
    }
    
    /// Attaches the diagnostics view to this window. The gesture recogniser will be attached and optionally hidden behind authentication
    ///
    /// Safe to call more than once: the built-in providers are registered once, and the gesture moves to `window`
    /// rather than being added again. Each call replaces the authentication handler.
    ///
    /// - Parameters:
    ///   - window: The window to attach the gesture recogniser to
    ///   - authenticationHandler: A closure that you should use to handle authentication, if desired
    public func attach(to window: UIWindow, authenticationHandler: AuthenticationRequestClosure? = nil) {

        if !hasRegisteredBaymaxServices {
            register(provider: AppInfoServices())
            register(provider: BaymaxServices())
            hasRegisteredBaymaxServices = true
        }

        authenticationRequestClosure = authenticationHandler

        guard hostWindow !== window else { return }

        let wasAttached = isAttached
        hostWindow?.removeGestureRecognizer(swipeGesture)
        hostWindow = window
        window.addGestureRecognizer(swipeGesture)

        if !wasAttached {
            NotificationCenter.default.post(name: Self.attachmentDidChangeNotification, object: self)
        }
    }

    /// Posted (with the manager as `object`) when `isAttached` changes, so entry controls can show themselves.
    static let attachmentDidChangeNotification = Notification.Name("BaymaxAttachmentDidChange")

    /// Opens Baymax, running the authentication handler first if one was given to `attach(to:)`.
    /// Shared by the swipe gesture and the entry controls. Does nothing if Baymax isn't attached.
    func requestPresentation() {

        guard isAttached else { return }

        guard let authenticationHandler = authenticationRequestClosure else {
            presentDiagnosticsView()
            return
        }

        authenticationHandler({ [weak self] authenticated in
            guard authenticated, let self else { return }
            self.present(unlocked: self.authenticationUnlocksLockedProviders)
        })
    }

    /// Handles the swipe gesture recogniser on the window, if assigned
    @objc private func handleSwipeGesture() {
        requestPresentation()
    }

    /// Presents the diagnostics view. Skips the authentication handler, so it never unlocks `.locked` providers;
    /// the swipe gesture and entry controls go through the handler.
    public func presentDiagnosticsView() {
        present(unlocked: false)
    }

    /// Presents the diagnostics view, listing `.locked` providers in a Live build only if `unlocked`.
    private func present(unlocked: Bool) {

        guard let viewController = hostWindow?.visibleViewController else {
            return
        }

        isUnlocked = unlocked

        let diagnosticsView = DiagnosticsMenuTableViewController(manager: self)
        
        let navigationWrappedDiagnosticsView = UINavigationController(rootViewController: diagnosticsView)
        
        viewController.present(navigationWrappedDiagnosticsView, animated: true, completion: nil)
    }
}

fileprivate class GestureDelegateHandler: NSObject, UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
