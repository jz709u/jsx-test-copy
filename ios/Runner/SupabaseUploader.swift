import Foundation

/// Lightweight URLSession uploader so native Swift code can write to Supabase
/// without going through the Flutter method channel.
enum SupabaseUploader {
    private static let baseURL = "https://cuqnanupwutqdbhntykp.supabase.co/rest/v1"
    private static let anonKey =
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN1cW5hbnVwd3V0cWRiaG50eWtwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3MTE4ODUsImV4cCI6MjA5MjI4Nzg4NX0.JVNGZVzxB2wj_yvZygQ8nKaKE9ft_Is1i0sy815i_Dk"
    private static let devUserId = "a0000000-0000-0000-0000-000000000001"

    /// Upsert the APNs device token so the backend can send silent pushes.
    static func upsertDeviceToken(_ token: String) {
        request(
            method: "POST",
            path: "/device_tokens",
            body: ["user_id": devUserId, "token": token, "updated_at": iso8601Now()],
            prefer: "resolution=merge-duplicates"
        )
    }

    /// PATCH the push-to-start token onto the existing device_tokens row.
    /// Retries for up to 10s because the row may not exist yet when this fires.
    static func upsertLAStartToken(_ token: String) {
        Task {
            for attempt in 0..<5 {
                if attempt > 0 { try? await Task.sleep(nanoseconds: 2_000_000_000) }
                let updated = request(
                    method: "PATCH",
                    path: "/device_tokens?user_id=eq.\(devUserId)",
                    body: ["la_start_token": token, "updated_at": iso8601Now()],
                    prefer: "return=representation"
                )
                if updated { return }
            }
            print("[Supabase] la_start_token: gave up after 5 attempts")
        }
    }

    /// Delete the Live Activity row when the user dismisses the widget.
    static func deleteUpdateToken(flightId: String) {
        request(method: "DELETE",
                path: "/live_activities?flight_id=eq.\(flightId)",
                body: [:],
                prefer: "return=minimal")
    }

    /// Upload the Live Activity update token for a specific flight.
    static func uploadUpdateToken(flightId: String, pushToken: String) {
        request(
            method: "POST",
            path: "/live_activities",
            body: ["flight_id": flightId, "push_token": pushToken],
            prefer: "resolution=merge-duplicates"
        )
    }

    /// Poll for the Live Activity push token and upload it once it arrives.
    @available(iOS 16.2, *)
    static func uploadLiveActivityToken(for flightId: String) {
        Task {
            for _ in 0..<60 {
                try? await Task.sleep(nanoseconds: 500_000_000)
                guard let token = LiveActivityManager.shared.latestPushToken else { continue }
                uploadUpdateToken(flightId: flightId, pushToken: token)
                print("[LA] background: live activity token uploaded")
                return
            }
            print("[LA] background: live activity token never arrived")
        }
    }

    @discardableResult
    private static func request(method: String, path: String, body: [String: String], prefer: String) -> Bool {
        guard let url = URL(string: baseURL + path) else { return false }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(prefer, forHTTPHeaderField: "Prefer")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        var success = false
        let sem = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: req) { data, resp, err in
            if let err {
                print("[Supabase] \(method) \(path) error: \(err)")
            } else if let http = resp as? HTTPURLResponse {
                let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                if http.statusCode >= 300 {
                    print("[Supabase] \(method) \(path) HTTP \(http.statusCode): \(body)")
                } else {
                    print("[Supabase] \(method) \(path) → \(http.statusCode)")
                    success = true
                }
            }
            sem.signal()
        }.resume()
        sem.wait()
        return success
    }

    private static func iso8601Now() -> String {
        ISO8601DateFormatter().string(from: Date())
    }
}
