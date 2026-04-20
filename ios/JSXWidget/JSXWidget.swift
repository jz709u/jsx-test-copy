import WidgetKit
import SwiftUI

// MARK: - Data Model

struct FlightEntry: TimelineEntry {
    let date: Date
    let hasFlight: Bool
    let origin: String
    let destination: String
    let route: String
    let departureTime: String
    let status: String
    let confirmationCode: String
    let timeAway: String
    let minutesAway: Int

    static var placeholder: FlightEntry {
        FlightEntry(
            date: Date(),
            hasFlight: true,
            origin: "DAL",
            destination: "BUR",
            route: "DAL→BUR",
            departureTime: "7:30 AM",
            status: "On Time",
            confirmationCode: "JSX4K8P",
            timeAway: "2h 15m away",
            minutesAway: 135
        )
    }

    static var empty: FlightEntry {
        FlightEntry(
            date: Date(),
            hasFlight: false,
            origin: "—",
            destination: "—",
            route: "—",
            departureTime: "No upcoming flights",
            status: "",
            confirmationCode: "",
            timeAway: "",
            minutesAway: 0
        )
    }
}

// MARK: - Timeline Provider

struct FlightProvider: TimelineProvider {
    private let appGroup = "group.com.jsx.jsxappcopy"

    func placeholder(in context: Context) -> FlightEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (FlightEntry) -> Void) {
        completion(context.isPreview ? .placeholder : load())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FlightEntry>) -> Void) {
        let entry = load()
        // Refresh every 5 minutes so the countdown stays accurate.
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func load() -> FlightEntry {
        let d = UserDefaults(suiteName: appGroup)
        let hasFlight = d?.bool(forKey: "jsx_has_flight") ?? false
        guard hasFlight else { return .empty }

        return FlightEntry(
            date: Date(),
            hasFlight: true,
            origin:          d?.string(forKey: "jsx_origin")         ?? "—",
            destination:     d?.string(forKey: "jsx_destination")    ?? "—",
            route:           d?.string(forKey: "jsx_route")          ?? "—",
            departureTime:   d?.string(forKey: "jsx_departure_time") ?? "—",
            status:          d?.string(forKey: "jsx_status")         ?? "",
            confirmationCode: d?.string(forKey: "jsx_confirmation")  ?? "",
            timeAway:        d?.string(forKey: "jsx_time_away")      ?? "",
            minutesAway:     d?.integer(forKey: "jsx_minutes_away")  ?? 0
        )
    }
}

// MARK: - Lock Screen: Rectangular (primary)

struct RectangularView: View {
    var entry: FlightEntry

    var statusColor: Color {
        switch entry.status {
        case "On Time": return .green
        case "Boarding": return .yellow
        case "Delayed":  return .orange
        default:         return .secondary
        }
    }

    var body: some View {
        if entry.hasFlight {
            VStack(alignment: .leading, spacing: 3) {
                // Row 1: brand + status
                HStack(spacing: 4) {
                    Text("JSX")
                        .font(.system(size: 10, weight: .black))
                        .widgetAccentable()
                    Spacer()
                    if !entry.status.isEmpty {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 5, height: 5)
                        Text(entry.status)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(statusColor)
                    }
                }

                // Row 2: route
                HStack(spacing: 6) {
                    Text(entry.origin)
                        .font(.system(size: 18, weight: .black))
                        .widgetAccentable()
                    Image(systemName: "airplane")
                        .font(.system(size: 10))
                    Text(entry.destination)
                        .font(.system(size: 18, weight: .black))
                        .widgetAccentable()
                }

                // Row 3: time + countdown
                HStack {
                    Text(entry.departureTime)
                        .font(.system(size: 11, weight: .medium))
                    if !entry.timeAway.isEmpty {
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text(entry.timeAway)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }

                // Row 4: confirmation + track button
                HStack {
                    if !entry.confirmationCode.isEmpty {
                        Text(entry.confirmationCode)
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if #available(iOS 17.0, *) {
                        Button(intent: TrackFlightIntent()) {
                            Label("Track", systemImage: "location.circle.fill")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.yellow)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(alignment: .leading, spacing: 4) {
                Text("JSX")
                    .font(.system(size: 10, weight: .black))
                    .widgetAccentable()
                Image(systemName: "airplane")
                    .font(.system(size: 22))
                    .widgetAccentable()
                Text("No upcoming flights")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Lock Screen: Circular

struct CircularView: View {
    var entry: FlightEntry

    var body: some View {
        if entry.hasFlight {
            VStack(spacing: 1) {
                Image(systemName: "airplane")
                    .font(.system(size: 14, weight: .semibold))
                    .widgetAccentable()
                if entry.minutesAway < 60 {
                    Text("\(entry.minutesAway)")
                        .font(.system(size: 16, weight: .black))
                        .widgetAccentable()
                    Text("min")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                } else {
                    let h = entry.minutesAway / 60
                    Text("\(h)h")
                        .font(.system(size: 16, weight: .black))
                        .widgetAccentable()
                    Text("away")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            Image(systemName: "airplane.departure")
                .font(.system(size: 22))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Lock Screen: Inline (single line above the clock)

struct InlineView: View {
    var entry: FlightEntry

    var body: some View {
        if entry.hasFlight {
            Label {
                Text("\(entry.route) · \(entry.departureTime)")
            } icon: {
                Image(systemName: "airplane")
            }
        } else {
            Label("No flights", systemImage: "airplane")
        }
    }
}

// MARK: - Widget Entry View (router)

struct JSXWidgetEntryView: View {
    var entry: FlightEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryRectangular:
            RectangularView(entry: entry)
        case .accessoryCircular:
            CircularView(entry: entry)
        case .accessoryInline:
            InlineView(entry: entry)
        default:
            RectangularView(entry: entry)
        }
    }
}

// MARK: - Compatibility helpers

private struct ContainerBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.containerBackground(.fill.tertiary, for: .widget)
        } else {
            content
        }
    }
}

// MARK: - Widget Definition

struct JSXWidget: Widget {
    let kind: String = "JSXWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FlightProvider()) { entry in
            JSXWidgetEntryView(entry: entry)
                .modifier(ContainerBackgroundModifier())
        }
        .configurationDisplayName("Next JSX Flight")
        .description("Your upcoming JSX flight on the lock screen.")
        .supportedFamilies([
            .accessoryRectangular,
            .accessoryCircular,
            .accessoryInline,
        ])
    }
}

