import AppIntents
import Foundation

@available(iOS 16.0, *)
struct NextFlightIntent: AppIntent {
    static var title: LocalizedStringResource = "Next JSX Flight"
    static var description = IntentDescription("Get details about your next JSX flight.")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some ReturnsValue<String> & ProvidesDialog {
        let d = UserDefaults(suiteName: "group.com.jsx.jsxappcopy")
        guard d?.bool(forKey: "jsx_has_flight") == true else {
            return .result(
                value: "No upcoming flights",
                dialog: IntentDialog("You have no upcoming JSX flights.")
            )
        }
        let origin = d?.string(forKey: "jsx_origin")         ?? "—"
        let dest   = d?.string(forKey: "jsx_destination")    ?? "—"
        let time   = d?.string(forKey: "jsx_departure_time") ?? "—"
        let status = d?.string(forKey: "jsx_status")         ?? ""
        let away   = d?.string(forKey: "jsx_time_away")      ?? ""
        let code   = d?.string(forKey: "jsx_confirmation")   ?? ""

        var parts = ["\(origin) to \(dest), departing at \(time)."]
        if !away.isEmpty   { parts.append(away + ".") }
        if !status.isEmpty { parts.append("Status: \(status).") }
        if !code.isEmpty   { parts.append("Confirmation: \(code).") }
        let text = parts.joined(separator: " ")
        return .result(value: text, dialog: IntentDialog(stringLiteral: text))
    }
}
