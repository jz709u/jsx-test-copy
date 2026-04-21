import AppIntents

@available(iOS 17.0, *)
struct TrackFlightIntent: AppIntent {
    static var title: LocalizedStringResource = "Track My Flight"
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        UserDefaults(suiteName: "group.jsx.jsxAppCopy")?
            .set("track", forKey: "jsx_pending_route")
        return .result()
    }
}
