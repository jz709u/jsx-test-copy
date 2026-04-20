import ActivityKit
import Foundation

// Compiled into Runner AND JSXWidget — must be identical in both targets.

struct JSXFlightAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Updated dynamically
        var status: String
        var phase: String
        var progress: Double      // 0.0 – 1.0
        var minutesRemaining: Int
        var altitudeFt: Int
        var speedMph: Int
    }

    // Set once at creation
    var flightId: String
    var origin: String
    var originCity: String
    var destination: String
    var destinationCity: String
    var departureTime: String
    var arrivalTime: String
    var confirmationCode: String
}
