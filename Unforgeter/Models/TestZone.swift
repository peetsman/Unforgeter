import Foundation

/// Deliberately separate from scheduled Rules: the first spike listens all day.
struct TestZone: Codable, Equatable {
    let id: UUID
    let latitude: Double
    let longitude: Double
    let radiusMeters: Double

    init(latitude: Double, longitude: Double, radiusMeters: Double) {
        self.id = UUID()
        self.latitude = latitude
        self.longitude = longitude
        self.radiusMeters = radiusMeters
    }

    var regionIdentifier: String { "unforgeter.proof.\(id.uuidString)" }

    var isValid: Bool {
        latitude.isFinite && longitude.isFinite && radiusMeters.isFinite
            && (-90...90).contains(latitude) && (-180...180).contains(longitude)
            && (25...1_000).contains(radiusMeters)
    }
}

struct ProofState: Codable {
    var zone: TestZone?
    var lastRealNotificationAt: Date?
}

struct DiagnosticEvent: Identifiable {
    let id = UUID()
    let date = Date()
    let message: String
}

struct ChecklistPresentation: Identifiable {
    let id = UUID()
    let zoneID: String
    let isSimulation: Bool
}
