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
        post(
            path: "/device_tokens",
            body: ["user_id": devUserId, "token": token, "updated_at": iso8601Now()],
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
                post(
                    path: "/live_activities",
                    body: ["flight_id": flightId, "push_token": token],
                    prefer: "resolution=merge-duplicates"
                )
                print("[LA] background: live activity token uploaded")
                return
            }
            print("[LA] background: live activity token never arrived")
        }
    }

    private static func post(path: String, body: [String: String], prefer: String) {
        guard let url = URL(string: baseURL + path) else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(prefer, forHTTPHeaderField: "Prefer")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: req) { _, _, err in
            if let err { print("[Supabase] upload error: \(err)") }
        }.resume()
    }

    private static func iso8601Now() -> String {
        ISO8601DateFormatter().string(from: Date())
    }
}
