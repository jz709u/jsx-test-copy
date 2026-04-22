import ActivityKit
import Foundation

@available(iOS 16.2, *)
actor LiveActivityManager {
    static let shared = LiveActivityManager()
    
    private var activity: Activity<JSXFlightAttributes>?
    private(set) var latestPushToken: String?
    private var startTokenUpdatesTask: Task<Void, Never>? {
        willSet { startTokenUpdatesTask?.cancel() }
    }
    private var activityUpdatesTask: Task<Void, Never>? {
        willSet { activityUpdatesTask?.cancel() }
    }
    
    private let uploader: SupabaseUploader
    private let userDefaults: UserDefaults
    
    private init(uploader: SupabaseUploader = .init(),
                 userDefaults: UserDefaults = .jsxAppGroup) {
        self.uploader = uploader
        self.userDefaults = userDefaults
    }
    
    func startListeners() {
        
        // Starting Live Activity From a Push Notification
        startTokenUpdatesTask = Task { [uploader] in
            for await tokenData in Activity<JSXFlightAttributes>.pushToStartTokenUpdates {
                guard !Task.isCancelled else { break }
                let hex = tokenData.asHex()
                print("[LA] push-to-start token: \(hex.prefix(16))...")
                await uploader.upsertLAStartToken(hex)
            }
        }
        
        // Getting Live Activity Updates
        activityUpdatesTask = Task {
            for await activity in Activity<JSXFlightAttributes>.activityUpdates {
                guard !Task.isCancelled else { break }
                adoptIfNeeded(activity)
            }
        }
    }

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
            confirmationCode: args["confirmationCode"] as? String ?? "",
            seat:             args["seat"]             as? String ?? ""
        )
        let state = contentState(from: args)
        let content = ActivityContent(state: state, staleDate: nil)
        let _activity = try Activity.request(attributes: attrs,
                                             content: content,
                                             pushType: .token)
        activity = _activity
        print("[LA] activity started, id=\(_activity.id), waiting for push token...")

        Task { [weak self] in
            guard let activity = await self?.activity else { return }
            for await tokenData in activity.pushTokenUpdates {
                let hex = tokenData.asHex()
                print("[LA] push token received: \(hex.prefix(16))...")
                await self?.setLatestToken(hex)
            }
        }

        monitorDismissal(of: activity!, flightId: attrs.flightId)
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
        userDefaults.removeObject(forKey: "jsx_la_push_token")
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

    /// Called when iOS starts a Live Activity via push-to-start.
    /// Stores it and begins listening for its update push token.
    private func adoptIfNeeded(_ activity: Activity<JSXFlightAttributes>) {
        guard self.activity == nil else { return }
        self.activity = activity
        print("[LA] adopted push-started activity id=\(activity.id) flightId=\(activity.attributes.flightId)")
        Task { [weak self] in
            for await tokenData in activity.pushTokenUpdates {
                guard !Task.isCancelled else { break }
                let hex = tokenData.asHex()
                print("[LA] update token for push-started activity: \(hex.prefix(16))...")
                await self?.setLatestToken(hex)
                await self?.uploader.uploadUpdateToken(flightId: activity.attributes.flightId, pushToken: hex)
            }
        }

        monitorDismissal(of: activity, flightId: activity.attributes.flightId)
    }

    private func monitorDismissal(of activity: Activity<JSXFlightAttributes>, flightId: String) {
        Task { [weak self] in
            for await state in activity.activityStateUpdates {
                guard state == .dismissed else { continue }
                print("[LA] activity dismissed by user, cleaning up flightId=\(flightId)")
                await self?.activity = nil
                await self?.setLatestToken(nil)
                await self?.uploader.deleteUpdateToken(flightId: flightId)
                return
            }
        }
    }
    private func setLatestToken(_ token: String?) {
        self.latestPushToken = token
        self.userDefaults.set(token, forKey: "jsx_la_push_token")
    }
    

    enum LAError: Error { case notEnabled }
}
