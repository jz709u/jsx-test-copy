import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Helpers

private let gold = Color(red: 0.91, green: 0.72, blue: 0.29)
private let bg   = Color(red: 0.05, green: 0.055, blue: 0.078)

/// Displays a live-updating relative countdown without seconds.
/// Rounds the target date up to the next minute so Text(style: .relative)
/// never has a seconds component to display.
struct RelativeTimeText: View {
    let date: Date
    var font: Font = .system(size: 11, weight: .semibold)

    private var minuteAlignedDate: Date {
        let t = date.timeIntervalSinceReferenceDate
        return Date(timeIntervalSinceReferenceDate: ceil(t / 60) * 60)
    }

    var body: some View {
        Text(minuteAlignedDate, style: .relative)
            .font(font)
    }
}

private extension JSXFlightAttributes.ContentState {
    var statusColor: Color {
        switch status {
        case "On Time":   return .green
        case "Boarding":  return gold
        case "En Route":  return .blue
        case "Delayed":   return .orange
        case "Landing":   return .blue
        case "Landed":    return .green
        default:          return .secondary
        }
    }

    var phaseIcon: String {
        switch phase {
        case "boarding":     return "figure.walk"
        case "en_route":     return "airplane"
        case "landing":      return "airplane.arrival"
        case "landed":       return "checkmark.circle.fill"
        default:             return "airplane.departure"
        }
    }
}

// MARK: - Lock Screen / Banner

struct LALockScreenView: View {
    let attrs: JSXFlightAttributes
    let state: JSXFlightAttributes.ContentState

    var body: some View {
        VStack(spacing: 10) {
            // Header
            HStack {
                Text("JSX")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(gold)
                Spacer()
                Circle().fill(state.statusColor).frame(width: 7, height: 7)
                Text(state.status)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(state.statusColor)
            }

            // Route + progress bar
            HStack(alignment: .center, spacing: 12) {
                VStack(spacing: 2) {
                    Text(attrs.origin)
                        .font(.system(size: 28, weight: .black))
                    Text(attrs.originCity)
                        .font(.system(size: 10)).foregroundStyle(.secondary)
                }

                VStack(spacing: 4) {
                    Image(systemName: state.phaseIcon)
                        .font(.system(size: 16))
                        .foregroundStyle(gold)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.15)).frame(height: 3)
                            Capsule().fill(gold)
                                .frame(width: geo.size.width * state.progress, height: 3)
                        }
                    }
                    .frame(height: 3)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 2) {
                    Text(attrs.destination)
                        .font(.system(size: 28, weight: .black))
                    Text(attrs.destinationCity)
                        .font(.system(size: 10)).foregroundStyle(.secondary)
                }
            }

            // Footer — phase-aware
            phaseFooter
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var phaseFooter: some View {
        switch state.phase {
        case "pre_departure", "boarding":
            HStack {
                Label("Gate \(state.gate)", systemImage: "door.right.hand.open")
                    .font(.system(size: 11, weight: .semibold))
                Spacer()
                Label("Seat \(attrs.seat)", systemImage: "carseat.left")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
                Spacer()
                Text("Departing in ")
                    .font(.system(size: 11, weight: .semibold))
                RelativeTimeText(date: state.departureTime)
            }
        case "en_route", "landing":
            HStack {
                Label("\(state.altitudeFt / 1000)k ft", systemImage: "arrow.up")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
                Spacer()
                Text("Arriving in ")
                    .font(.system(size: 11, weight: .semibold))
                RelativeTimeText(date: state.arrivalTime)
                Spacer()
                Label("\(state.speedMph) mph", systemImage: "speedometer")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
            }
        default: // landed
            HStack {
                Spacer()
                Label("Landed at \(attrs.destinationCity)", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 12, weight: .semibold)).foregroundStyle(.green)
                Spacer()
            }
        }
    }
}

// MARK: - Dynamic Island: Compact

struct LACompactLeading: View {
    let attrs: JSXFlightAttributes
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "airplane")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(gold)
            Text("\(attrs.origin)→\(attrs.destination)")
                .font(.system(size: 12, weight: .bold))
        }
    }
}

struct LACompactTrailing: View {
    let state: JSXFlightAttributes.ContentState
    var body: some View {
        RelativeTimeText(date: state.arrivalTime, font: .system(size: 12, weight: .semibold))
            .foregroundStyle(state.statusColor)
            .lineLimit(1)
    }
}

// MARK: - Dynamic Island: Minimal

struct LAMinimalView: View {
    let state: JSXFlightAttributes.ContentState
    var body: some View {
        Image(systemName: state.phaseIcon)
            .font(.system(size: 12))
            .foregroundStyle(gold)
    }
}

// MARK: - Dynamic Island: Expanded

struct LAExpandedView: View {
    let attrs: JSXFlightAttributes
    let state: JSXFlightAttributes.ContentState

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("JSX \(attrs.confirmationCode)")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(gold)
                Spacer()
                Circle().fill(state.statusColor).frame(width: 7, height: 7)
                Text(state.status)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(state.statusColor)
            }

            HStack(spacing: 12) {
                Text(attrs.origin).font(.system(size: 24, weight: .black))
                Spacer()
                Image(systemName: state.phaseIcon).foregroundStyle(gold)
                Spacer()
                Text(attrs.destination).font(.system(size: 24, weight: .black))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.15)).frame(height: 4)
                    Capsule().fill(gold)
                        .frame(width: geo.size.width * state.progress, height: 4)
                }
            }
            .frame(height: 4)

            // Phase-aware bottom row
            switch state.phase {
            case "pre_departure", "boarding":
                HStack {
                    Text("Gate \(state.gate)").font(.system(size: 11, weight: .semibold))
                    Spacer()
                    Text("Seat \(attrs.seat)").font(.system(size: 11)).foregroundStyle(.secondary)
                    Spacer()
                    RelativeTimeText(date: state.departureTime)
                }
            case "en_route", "landing":
                HStack {
                    Text(state.departureTime, style: .time)
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                    Spacer()
                    RelativeTimeText(date: state.arrivalTime)
                    Spacer()
                    Text(state.arrivalTime, style: .time)
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                }
            default:
                Label("Landed at \(attrs.destinationCity)", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 12, weight: .semibold)).foregroundStyle(.green)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// MARK: - Live Activity Widget

struct JSXFlightLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: JSXFlightAttributes.self) { context in
            LALockScreenView(attrs: context.attributes, state: context.state)
                .activityBackgroundTint(bg)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    LACompactLeading(attrs: context.attributes)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    LACompactTrailing(state: context.state)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    LAExpandedView(attrs: context.attributes, state: context.state)
                }
            } compactLeading: {
                LACompactLeading(attrs: context.attributes)
            } compactTrailing: {
                LACompactTrailing(state: context.state)
            } minimal: {
                LAMinimalView(state: context.state)
            }
        }
    }
}
