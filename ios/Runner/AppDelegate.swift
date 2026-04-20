import CoreSpotlight
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {

    private var navigationChannel: FlutterMethodChannel?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        let controller = window?.rootViewController as! FlutterViewController

        // Navigation channel — App Intents / Spotlight write a pending route;
        // Flutter polls this on foreground to navigate without coupling targets.
        navigationChannel = FlutterMethodChannel(
            name: "jsx.app/navigation",
            binaryMessenger: controller.binaryMessenger
        )
        navigationChannel?.setMethodCallHandler { [weak self] call, result in
            guard call.method == "getPendingRoute" else {
                result(FlutterMethodNotImplemented); return
            }
            let d = UserDefaults(suiteName: "group.com.jsx.jsxappcopy")
            let route = d?.string(forKey: "jsx_pending_route")
            d?.removeObject(forKey: "jsx_pending_route")
            result(route)
        }

        // Spotlight indexing channel — Flutter sends booking data to index.
        let spotlightChannel = FlutterMethodChannel(
            name: "jsx.app/spotlight",
            binaryMessenger: controller.binaryMessenger
        )
        spotlightChannel.setMethodCallHandler { call, result in
            switch call.method {
            case "index":
                if let bookings = call.arguments as? [[String: Any]] {
                    SpotlightIndexer.shared.index(bookings)
                }
                result(nil)
            case "deleteAll":
                SpotlightIndexer.shared.deleteAll()
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        // Live Activity channel
        if #available(iOS 16.2, *) {
            let laChannel = FlutterMethodChannel(
                name: "jsx.app/live_activity",
                binaryMessenger: controller.binaryMessenger
            )
            laChannel.setMethodCallHandler { call, result in
                let args = call.arguments as? [String: Any] ?? [:]
                switch call.method {
                case "start":
                    do {
                        try LiveActivityManager.shared.start(args)
                        result(nil)
                    } catch {
                        result(FlutterError(code: "START_FAILED",
                                            message: error.localizedDescription,
                                            details: nil))
                    }
                case "update":
                    LiveActivityManager.shared.update(args)
                    result(nil)
                case "end":
                    LiveActivityManager.shared.end()
                    result(nil)
                default:
                    result(FlutterMethodNotImplemented)
                }
            }
        }

        // Register Siri shortcut phrases
        if #available(iOS 16.4, *) {
            JSXAppShortcuts.updateAppShortcutParameters()
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // Handle Spotlight search result taps
    override func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        if userActivity.activityType == CSSearchableItemActionType,
           let identifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String {
            let code = identifier.replacingOccurrences(of: "jsx.booking.", with: "")
            UserDefaults(suiteName: "group.com.jsx.jsxappcopy")?
                .set("booking/\(code)", forKey: "jsx_pending_route")
        }
        return super.application(application,
                                 continue: userActivity,
                                 restorationHandler: restorationHandler)
    }
}
