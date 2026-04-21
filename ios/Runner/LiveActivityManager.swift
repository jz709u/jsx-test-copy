import ActivityKit
import Foundation

@available(iOS 16.2, *)
final class LiveActivityManager {
    static let shared = LiveActivityManager()
    private init() {}

    private var activity: Activity<JSXFlightAttributes>?
    private(set) var latestPushToken: String?

    func start(_ args: [String: Any]) throws {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            throw LAError.notEnabled
        }
        guard activity == nil else {
            print("[LA] activity already running, skipping start")
            return
        }

        let attrs = JSXFlightAttributes(
            flightId:         args["flightId"]         as? String ?? "",
            origin:           args["origin"]           as? String ?? "",
            originCity:       args["originCity"]       as? String ?? "",
            destination:      args["destination"]      as? String ?? "",
            destinationCity:  args["destinationCity"]  as? String ?? "",
            departureTime:    args["departureTime"]    as? String ?? "",
            arrivalTime:      args["arrivalTime"]      as? String ?? "",
            confirmationCode: args["confirmationCode"] as? String ?? ""
        )
        let state = contentState(from: args)
        let content = ActivityContent(state: state, staleDate: nil)
        activity = try Activity.request(attributes: attrs, content: content, pushType: .token)
        print("[LA] activity started, id=\(activity?.id ?? "nil"), waiting for push token...")

        Task { [weak self] in
            guard let activity = self?.activity else { return }
            for await tokenData in activity.pushTokenUpdates {
                let hex = tokenData.map { String(format: "%02x", $0) }.joined()
                print("[LA] push token received: \(hex.prefix(16))...")
                self?.latestPushToken = hex
                UserDefaults(suiteName: "group.jsx.jsxAppCopy")?
                    .set(hex, forKey: "jsx_la_push_token")
            }
        }
    }

    func update(_ args: [String: Any]) {
        guard let activity else { return }
        let state = contentState(from: args)
        Task { await activity.update(ActivityContent(state: state, staleDate: nil)) }
    }

    func end() {
        guard let activity else { return }
        Task { await activity.end(nil, dismissalPolicy: .immediate) }
        self.activity = nil
        latestPushToken = nil
        UserDefaults(suiteName: "group.jsx.jsxAppCopy")?
            .removeObject(forKey: "jsx_la_push_token")
    }

    private func contentState(from args: [String: Any]) -> JSXFlightAttributes.ContentState {
        JSXFlightAttributes.ContentState(
            status:           args["status"]           as? String ?? "On Time",
            phase:            args["phase"]            as? String ?? "cruising",
            progress:         args["progress"]         as? Double ?? 0,
            minutesRemaining: args["minutesRemaining"] as? Int    ?? 0,
            altitudeFt:       args["altitudeFt"]       as? Int    ?? 0,
            speedMph:         args["speedMph"]         as? Int    ?? 0
        )
    }

    /// Called when iOS starts a Live Activity via push-to-start.
    /// Stores it and begins listening for its update push token.
    func adoptIfNeeded(_ activity: Activity<JSXFlightAttributes>) {
        guard self.activity == nil else { return }
        self.activity = activity
        print("[LA] adopted push-started activity id=\(activity.id) flightId=\(activity.attributes.flightId)")
        Task { [weak self] in
            for await tokenData in activity.pushTokenUpdates {
                let hex = tokenData.map { String(format: "%02x", $0) }.joined()
                print("[LA] update token for push-started activity: \(hex.prefix(16))...")
                self?.latestPushToken = hex
                UserDefaults(suiteName: "group.jsx.jsxAppCopy")?.set(hex, forKey: "jsx_la_push_token")
                SupabaseUploader.uploadUpdateToken(flightId: activity.attributes.flightId, pushToken: hex)
            }
        }
    }

    enum LAError: Error { case notEnabled }
}
