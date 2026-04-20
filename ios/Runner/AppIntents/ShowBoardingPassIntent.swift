import AppIntents

@available(iOS 16.0, *)
struct ShowBoardingPassIntent: AppIntent {
    static var title: LocalizedStringResource = "Show JSX Boarding Pass"
    static var description = IntentDescription("Open your JSX boarding pass.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        UserDefaults(suiteName: "group.com.jsx.jsxappcopy")?
            .set("boarding-pass", forKey: "jsx_pending_route")
        return .result()
    }
}
