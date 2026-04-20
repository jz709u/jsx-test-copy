import AppIntents

@available(iOS 16.4, *)
struct JSXAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: NextFlightIntent(),
            phrases: [
                "What's my next flight on \(.applicationName)",
                "Next flight on \(.applicationName)",
                "Check my \(.applicationName) flight",
                "\(.applicationName) next flight",
            ],
            shortTitle: "Next Flight",
            systemImageName: "airplane"
        )
        AppShortcut(
            intent: ShowBoardingPassIntent(),
            phrases: [
                "Show my boarding pass on \(.applicationName)",
                "Open \(.applicationName) boarding pass",
                "\(.applicationName) boarding pass",
            ],
            shortTitle: "Boarding Pass",
            systemImageName: "wallet.pass"
        )
        AppShortcut(
            intent: SearchFlightsIntent(),
            phrases: [
                "Search flights on \(.applicationName)",
                "Find \(.applicationName) flights",
                "Book a \(.applicationName) flight",
            ],
            shortTitle: "Search Flights",
            systemImageName: "magnifyingglass"
        )
    }
}
