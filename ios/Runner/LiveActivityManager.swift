import ActivityKit
import Foundation

@available(iOS 16.2, *)
final class LiveActivityManager {
    static let shared = LiveActivityManager()
    private init() {}

    private var activity: Activity<JSXFlightAttributes>?

    func start(_ args: [String: Any]) throws {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            throw LAError.notEnabled
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

        let state = JSXFlightAttributes.ContentState(
            status:           args["status"]           as? String ?? "On Time",
            phase:            args["phase"]            as? String ?? "cruising",
            progress:         args["progress"]         as? Double ?? 0,
            minutesRemaining: args["minutesRemaining"] as? Int    ?? 0,
            altitudeFt:       args["altitudeFt"]       as? Int    ?? 0,
            speedMph:         args["speedMph"]         as? Int    ?? 0
        )

        let content = ActivityContent(state: state, staleDate: nil)
        activity = try Activity.request(attributes: attrs, content: content)
    }

    func update(_ args: [String: Any]) {
        guard let activity else { return }
        let state = JSXFlightAttributes.ContentState(
            status:           args["status"]           as? String ?? "On Time",
            phase:            args["phase"]            as? String ?? "cruising",
            progress:         args["progress"]         as? Double ?? 0,
            minutesRemaining: args["minutesRemaining"] as? Int    ?? 0,
            altitudeFt:       args["altitudeFt"]       as? Int    ?? 0,
            speedMph:         args["speedMph"]         as? Int    ?? 0
        )
        Task { await activity.update(ActivityContent(state: state, staleDate: nil)) }
    }

    func end() {
        guard let activity else { return }
        Task { await activity.end(nil, dismissalPolicy: .immediate) }
        self.activity = nil
    }

    enum LAError: Error { case notEnabled }
}
