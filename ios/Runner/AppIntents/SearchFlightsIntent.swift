import AppIntents

@available(iOS 16.0, *)
struct SearchFlightsIntent: AppIntent {
    static var title: LocalizedStringResource = "Search JSX Flights"
    static var description = IntentDescription("Search for available JSX flights.")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "From", description: "Departure airport code, e.g. DAL")
    var from: String?

    @Parameter(title: "To", description: "Arrival airport code, e.g. BUR")
    var to: String?

    func perform() async throws -> some IntentResult {
        var route = "search"
        if let f = from, let t = to {
            route = "search?from=\(f.uppercased())&to=\(t.uppercased())"
        }
        UserDefaults(suiteName: "group.com.jsx.jsxappcopy")?
            .set(route, forKey: "jsx_pending_route")
        return .result()
    }
}
