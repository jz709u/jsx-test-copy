import ActivityKit
import CoreSpotlight
import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {

    private var navigationChannel: FlutterMethodChannel?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        // Register for remote push notifications
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            granted, _ in
            if granted {
                DispatchQueue.main.async { UIApplication.shared.registerForRemoteNotifications() }
            }
        }
        
        // Receive the push-to-start token so the server can start Live Activities
        // without requiring the app to be in the foreground (iOS 17.2+)
        Task {
            for await tokenData in Activity<JSXFlightAttributes>.pushToStartTokenUpdates {
                let hex = tokenData.map { String(format: "%02x", $0) }.joined()
                print("[LA] push-to-start token: \(hex.prefix(16))...")
                SupabaseUploader.upsertLAStartToken(hex)
            }
        }
        Task {
            for await activity in Activity<JSXFlightAttributes>.activityUpdates {
                LiveActivityManager.shared.adoptIfNeeded(activity)
            }
        }
        
        let controller = window?.rootViewController as! FlutterViewController

        // Navigation channel — App Intents / Spotlight write a pending route;
        // Flutter polls this on foreground to navigate without coupling targets.
        navigationChannel = FlutterMethodChannel(
            name: "jsx.app/navigation",
            binaryMessenger: controller.binaryMessenger
        )
        navigationChannel?.setMethodCallHandler { [weak self] call, result in
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
                do {
                    try LiveActivityManager.shared.start(args)
                    result(nil)
                } catch {
                    result(
                        FlutterError(
                            code: "START_FAILED",
                            message: error.localizedDescription,
                            details: nil))
                }
            case "update":
                LiveActivityManager.shared.update(args)
                result(nil)
            case "end":
                LiveActivityManager.shared.end()
                result(nil)
            case "getActivityPushToken":
                result(LiveActivityManager.shared.latestPushToken)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        // Register Siri shortcut phrases
        JSXAppShortcuts.updateAppShortcutParameters()


        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // Upload device token to Supabase so backend can send silent pushes
    override func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let hex = deviceToken.map { String(format: "%02x", $0) }.joined()
        print("[Push] device token: \(hex.prefix(16))...")
        SupabaseUploader.upsertDeviceToken(hex)
    }

    private static func fmtLocalTime(_ iso: String?) -> String {
        guard let iso, let date = ISO8601DateFormatter().date(from: iso) else { return "" }
        let fmt = DateFormatter()
        fmt.dateFormat = "h:mm a"
        fmt.locale = Locale(identifier: "en_US")
        return fmt.string(from: date)  // uses device local timezone by default
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
