import ActivityKit
import CoreSpotlight
import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {

    private var navigationChannel: FlutterMethodChannel?
    
    var liveActivityManager: LiveActivityManager = .shared
    var userNotificationCenter: UNUserNotificationCenter = .current()
    var userDefaults: UserDefaults = .jsxAppGroup

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        // Register for remote push notifications
        Task {
            let granted = try await userNotificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            guard granted else { return }
            await MainActor.run { UIApplication.shared.registerForRemoteNotifications() }
        }
        
        // Receive the push-to-start token so the server can start Live Activities
        // without requiring the app to be in the foreground (iOS 17.2+)
        Task { await liveActivityManager.startListeners() }
        
        let controller = window?.rootViewController as! FlutterViewController

        // Navigation channel — App Intents / Spotlight write a pending route;
        // Flutter polls this on foreground to navigate without coupling targets.
        navigationChannel = FlutterMethodChannel(
            name: "jsx.app/navigation",
            binaryMessenger: controller.binaryMessenger
        )
        navigationChannel?.setMethodCallHandler { call, result in
            guard call.method == "getPendingRoute" else {
                result(FlutterMethodNotImplemented)
                return
            }
            let d = UserDefaults(suiteName: "group.jsx.jsxAppCopy")
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
        let laChannel = FlutterMethodChannel(
            name: "jsx.app/live_activity",
            binaryMessenger: controller.binaryMessenger
        )
        laChannel.setMethodCallHandler { call, result in
            let args = call.arguments as? [String: Any] ?? [:]
            switch call.method {
            case "start":
                Task {
                    do {
                        try await LiveActivityManager.shared.start(args)
                        result(nil)
                    } catch {
                        result(
                            FlutterError(
                                code: "START_FAILED",
                                message: error.localizedDescription,
                                details: nil))
                    }
                }
            case "update":
                Task { await LiveActivityManager.shared.update(args) }
                result(nil)
            case "end":
                let flightId = args["flightId"] as? String ?? ""
                Task { await LiveActivityManager.shared.end(flightId: flightId) }
                result(nil)
            case "getActivityPushToken":
                let flightId = args["flightId"] as? String ?? ""
                Task { result(await LiveActivityManager.shared.pushToken(for: flightId)) }
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        // Register Siri shortcut phrases
        JSXAppShortcuts.updateAppShortcutParameters()


        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // Handle Spotlight search result taps
    override func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        if userActivity.activityType == CSSearchableItemActionType,
            let identifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String
        {
            let code = identifier.replacingOccurrences(of: "jsx.booking.", with: "")
            UserDefaults(suiteName: "group.jsx.jsxAppCopy")?
                .set("booking/\(code)", forKey: "jsx_pending_route")
        }
        return super.application(
            application,
            continue: userActivity,
            restorationHandler: restorationHandler)
    }
}
