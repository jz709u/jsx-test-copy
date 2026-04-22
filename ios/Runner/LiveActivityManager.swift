import ActivityKit
import Foundation

@available(iOS 16.2, *)
actor LiveActivityManager {
    static let shared = LiveActivityManager()

    private let uploader: SupabaseUploader
    private let userDefaults: UserDefaults

    private var activities:   [String: Activity<JSXFlightAttributes>] = [:]  // keyed by flightId
    private var pushTokens:   [String: String] = [:]                         // keyed by flightId

    private var startTokenUpdatesTask: Task<Void, Never>? { willSet { startTokenUpdatesTask?.cancel() } }
    private var activityUpdatesTask:   Task<Void, Never>? { willSet { activityUpdatesTask?.cancel() } }

    init(uploader: SupabaseUploader = .init(),
         userDefaults: UserDefaults = .jsxAppGroup) {
        self.uploader = uploader
        self.userDefaults = userDefaults
    }

    // MARK: - Listeners

    func startListeners() {
        startTokenUpdatesTask = Task { [uploader] in
            for await tokenData in Activity<JSXFlightAttributes>.pushToStartTokenUpdates {
                guard !Task.isCancelled else { break }
                let hex = tokenData.asHex()
                print("[LA] push-to-start token: \(hex)...")
                await uploader.upsertLAStartToken(hex)
            }
        }

        activityUpdatesTask = Task {
            for await activity in Activity<JSXFlightAttributes>.activityUpdates {
                guard !Task.isCancelled else { break }
                adoptIfNeeded(activity)
            }
        }

        restoreActivities()
    }

    // MARK: - Start

    func start(_ args: [String: Any]) async throws {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { throw LAError.notEnabled }

        let flightId = args["flightId"] as? String ?? ""

        if let existing = activities[flightId] {
            let state = contentState(from: args)
            await existing.update(ActivityContent(state: state, staleDate: nil))
            return
        }

        let attrs = createFlightAttributes(
            args,
            flightId: flightId
        )
        let content = ActivityContent(
            state: contentState(from: args),
            staleDate: nil
        )
        let activity = try Activity.request(
            attributes: attrs,
            content: content,
            pushType: .token
        )
        register(activity, flightId: flightId)
        print("[LA] started flightId=\(flightId) id=\(activity.id)")
    }

    // MARK: - Update

    func update(_ args: [String: Any]) {
        let flightId = args["flightId"] as? String ?? ""
        guard let activity = activities[flightId] else { return }
        let state = contentState(from: args)
        Task { await activity.update(ActivityContent(state: state, staleDate: nil)) }
    }

    // MARK: - End

    func end(flightId: String) {
        guard let activity = activities[flightId] else { return }
        Task { await activity.end(nil, dismissalPolicy: .immediate) }
        cleanup(flightId: flightId)
    }

    // MARK: - Push token

    func pushToken(for flightId: String) -> String? {
        pushTokens[flightId]
    }

    // MARK: - Private

    private func restoreActivities() {
        for activity in Activity<JSXFlightAttributes>.activities {
            let flightId = activity.attributes.flightId
            guard activities[flightId] == nil else { continue }
            activities[flightId] = activity
            print("[LA] restored flightId=\(flightId) id=\(activity.id)")
            observeTokens(for: activity, flightId: flightId)
            monitorDismissal(of: activity, flightId: flightId)
        }
    }

    private func adoptIfNeeded(_ activity: Activity<JSXFlightAttributes>) {
        let flightId = activity.attributes.flightId
        guard activities[flightId] == nil else { return }
        register(activity, flightId: flightId)
        print("[LA] adopted push-started flightId=\(flightId) id=\(activity.id)")
    }

    private func register(_ activity: Activity<JSXFlightAttributes>, flightId: String) {
        activities[flightId] = activity
        observeTokens(for: activity, flightId: flightId)
        monitorDismissal(of: activity, flightId: flightId)
    }

    private func observeTokens(for activity: Activity<JSXFlightAttributes>, flightId: String) {
        Task { [uploader] in
            for await tokenData in activity.pushTokenUpdates {
                let hex = tokenData.asHex()
                print("[LA] update token flightId=\(flightId): \(hex)...")
                self.pushTokens[flightId] = hex
                await uploader.uploadUpdateToken(flightId: flightId, pushToken: hex)
            }
        }
    }

    private func monitorDismissal(of activity: Activity<JSXFlightAttributes>, flightId: String) {
        Task { [uploader] in
            for await state in activity.activityStateUpdates {
                guard state == .dismissed else { continue }
                print("[LA] dismissed flightId=\(flightId)")
                self.cleanup(flightId: flightId)
                await uploader.deleteUpdateToken(flightId: flightId)
                return
            }
        }
    }
    
    private func createFlightAttributes(_ args: [String: Any], flightId: String) -> JSXFlightAttributes {
        return .init(flightId:         flightId,
                     origin:           args["origin"]           as? String ?? "",
                     originCity:       args["originCity"]       as? String ?? "",
                     destination:      args["destination"]      as? String ?? "",
                     destinationCity:  args["destinationCity"]  as? String ?? "",
                     confirmationCode: args["confirmationCode"] as? String ?? "",
                     seat:             args["seat"]             as? String ?? "")
    }

    private func cleanup(flightId: String) {
        activities.removeValue(forKey: flightId)
        pushTokens.removeValue(forKey: flightId)
    }

    private func contentState(from args: [String: Any]) -> JSXFlightAttributes.ContentState {
        JSXFlightAttributes.ContentState(
            status:        args["status"]        as? String ?? "On Time",
            phase:         args["phase"]         as? String ?? "pre_departure",
            progress:      args["progress"]      as? Double ?? 0,
            departureTime: date(from: args, key: "departureTime"),
            arrivalTime:   date(from: args, key: "arrivalTime"),
            gate:          args["gate"]          as? String ?? "",
            boardingTime:  args["boardingTime"]  as? String ?? "",
            altitudeFt:    args["altitudeFt"]    as? Int    ?? 0,
            speedMph:      args["speedMph"]      as? Int    ?? 0
        )
    }

    private func date(from args: [String: Any], key: String) -> Date {
        if let ts = args[key] as? Double { return Date(timeIntervalSince1970: ts) }
        if let s = args[key] as? String, let d = ISO8601DateFormatter().date(from: s) { return d }
        return Date()
    }

    enum LAError: Error { case notEnabled }
}
