import AppIntents

@available(iOS 16.0, *)
struct JSXFocusFilter: SetFocusFilterIntent {
    static var title: LocalizedStringResource = "Customize JSX for Focus"
    static var description = IntentDescription(
        "During this Focus, JSX will highlight your upcoming flight and suppress unrelated content."
    )

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "JSX Focus Filter")

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "Show only my flight: \(showOnlyFlight ?? false ? "Yes" : "No")")
    }

    @Parameter(title: "Show Only My Flight", default: false)
    var showOnlyFlight: Bool?

    func perform() async throws -> some IntentResult {
        UserDefaults(suiteName: "group.jsx.jsxAppCopy")?
            .set(showOnlyFlight ?? false, forKey: "jsx_focus_flight_only")
        return .result()
    }
}
