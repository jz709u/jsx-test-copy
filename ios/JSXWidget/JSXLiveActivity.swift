import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Helpers

private extension JSXFlightAttributes.ContentState {
    var statusColor: Color {
        switch status {
        case "On Time":  return .green
        case "Boarding": return Color(red: 1, green: 0.84, blue: 0.29)
        case "Delayed":  return .orange
        default:         return .secondary
        }
    }

    var phaseIcon: String {
        switch phase {
        case "climbing":   return "airplane.departure"
        case "descending": return "airplane.arrival"
        case "landed":     return "checkmark.circle.fill"
        default:           return "airplane"
        }
    }
}

// MARK: - Lock Screen / Banner view

struct LALockScreenView: View {
    let attrs: JSXFlightAttributes
    let state: JSXFlightAttributes.ContentState

    var body: some View {
        VStack(spacing: 10) {
            // Header row
            HStack {
                Text("JSX")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(Color(red: 0.91, green: 0.72, blue: 0.29))
                Spacer()
                Circle()
                    .fill(state.statusColor)
                    .frame(width: 7, height: 7)
                Text(state.status)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(state.statusColor)
            }

            // Route + progress
            HStack(alignment: .center, spacing: 12) {
                VStack(spacing: 2) {
                    Text(attrs.origin)
                        .font(.system(size: 28, weight: .black))
                    Text(attrs.originCity)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 4) {
                    Image(systemName: state.phaseIcon)
                        .font(.system(size: 16))
                        .foregroundStyle(Color(red: 0.91, green: 0.72, blue: 0.29))
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.15))
                                .frame(height: 3)
                            Capsule()
                                .fill(Color(red: 0.91, green: 0.72, blue: 0.29))
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
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }

            // Footer row
            HStack {
                Label("\(state.altitudeFt / 1000)k ft", systemImage: "arrow.up")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Spacer()
                if state.minutesRemaining > 0 {
                    Text("\(state.minutesRemaining) min remaining")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                } else {
                    Text(attrs.arrivalTime)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Label("\(state.speedMph) mph", systemImage: "speedometer")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Dynamic Island: Compact

struct LACompactLeading: View {
    let attrs: JSXFlightAttributes

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "airplane")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(red: 0.91, green: 0.72, blue: 0.29))
            Text("\(attrs.origin)→\(attrs.destination)")
                .font(.system(size: 12, weight: .bold))
        }
    }
}

struct LACompactTrailing: View {
    let state: JSXFlightAttributes.ContentState

    var body: some View {
        Text(state.minutesRemaining > 0 ? "\(state.minutesRemaining)m" : "Arr")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(state.statusColor)
    }
}

// MARK: - Dynamic Island: Minimal

struct LAMinimalView: View {
    let state: JSXFlightAttributes.ContentState

    var body: some View {
        Image(systemName: state.phaseIcon)
            .font(.system(size: 12))
            .foregroundStyle(Color(red: 0.91, green: 0.72, blue: 0.29))
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
                    .foregroundStyle(Color(red: 0.91, green: 0.72, blue: 0.29))
                Spacer()
                Circle()
                    .fill(state.statusColor)
                    .frame(width: 7, height: 7)
                Text(state.status)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(state.statusColor)
            }

            HStack(spacing: 12) {
                Text(attrs.origin)
                    .font(.system(size: 24, weight: .black))
                Spacer()
                Image(systemName: state.phaseIcon)
                    .foregroundStyle(Color(red: 0.91, green: 0.72, blue: 0.29))
                Spacer()
                Text(attrs.destination)
                    .font(.system(size: 24, weight: .black))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 4)
                    Capsule()
                        .fill(Color(red: 0.91, green: 0.72, blue: 0.29))
                        .frame(width: geo.size.width * state.progress, height: 4)
                }
            }
            .frame(height: 4)

            HStack {
                Text(attrs.departureTime)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Spacer()
                if state.minutesRemaining > 0 {
                    Text("\(state.minutesRemaining) min left")
                        .font(.system(size: 11, weight: .semibold))
                }
                Spacer()
                Text(attrs.arrivalTime)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
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
                .activityBackgroundTint(Color(red: 0.05, green: 0.055, blue: 0.078))
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
