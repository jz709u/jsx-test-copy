import Foundation

/// Lightweight URLSession uploader so native Swift code can write to Supabase
/// without going through the Flutter method channel.
class SupabaseUploader {
    private static let baseURL = "https://cuqnanupwutqdbhntykp.supabase.co/rest/v1"
    private static let anonKey =
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN1cW5hbnVwd3V0cWRiaG50eWtwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3MTE4ODUsImV4cCI6MjA5MjI4Nzg4NX0.JVNGZVzxB2wj_yvZygQ8nKaKE9ft_Is1i0sy815i_Dk"
    private static let devUserId = "a0000000-0000-0000-0000-000000000001"
    
    private let urlSession: URLSession
    
    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    /// Upsert the push-to-start token so the server can remotely start Live Activities.
    func upsertLAStartToken(_ token: String) async {
        await request(
            method: "POST",
            path: "/device_tokens",
            body: ["user_id": Self.devUserId, "la_start_token": token, "updated_at": Self.iso8601Now()],
            prefer: "resolution=merge-duplicates"
        )
    }
    
    /// Delete the Live Activity row when the user dismisses the widget.
    func deleteUpdateToken(flightId: String) async {
        await request(
            method: "DELETE",
            path: "/live_activities?flight_id=eq.\(flightId)",
            body: [:],
            prefer: "return=minimal"
        )
    }

    /// Upload the Live Activity update token for a specific flight.
    func uploadUpdateToken(flightId: String, pushToken: String) async {
        await request(
            method: "POST",
            path: "/live_activities",
            body: ["flight_id": flightId, "push_token": pushToken],
            prefer: "resolution=merge-duplicates"
        )
    }

    @discardableResult
    private func request(method: String, path: String, body: [String: String], prefer: String) async -> Bool {
        guard let url = URL(string: Self.baseURL + path) else { return false }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("Bearer \(Self.anonKey)", forHTTPHeaderField: "Authorization")
        req.setValue(Self.anonKey, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(prefer, forHTTPHeaderField: "Prefer")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        var success = false
        
        do {
            let (data, response) = try await urlSession.data(for: req)
            if let http = response as? HTTPURLResponse {
                let body = String(data: data, encoding: .utf8) ?? ""
                if http.statusCode >= 300 {
                    print("[Supabase] \(method) \(path) HTTP \(http.statusCode): \(body)")
                } else {
                    print("[Supabase] \(method) \(path) → \(http.statusCode)")
                    success = true
                }
            }
        } catch {
            print("[Supabase] \(method) \(path) error: \(error)")
        }
        return success
    }

    private static func iso8601Now() -> String {
        ISO8601DateFormatter().string(from: Date())
    }
}
