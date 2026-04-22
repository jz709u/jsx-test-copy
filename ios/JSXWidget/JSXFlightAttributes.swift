import ActivityKit
import Foundation

// Compiled into Runner AND JSXWidget — must be identical in both targets.

struct JSXFlightAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var status: String        // "On Time" | "Delayed" | "Boarding" | "En Route" | "Landing" | "Landed"
        var phase: String         // "pre_departure" | "boarding" | "en_route" | "landing" | "landed"
        var progress: Double      // 0.0 – 1.0
        var departureTime: Date   // can change if delayed — used for relative countdown
        var arrivalTime: Date     // can change if delayed — used for relative countdown
        var gate: String          // can change
        var boardingTime: String  // can change
        var altitudeFt: Int
        var speedMph: Int
    }

    // Truly static — never changes after booking
    var flightId: String
    var origin: String
    var originCity: String
    var destination: String
    var destinationCity: String
    var confirmationCode: String
    var seat: String
}
