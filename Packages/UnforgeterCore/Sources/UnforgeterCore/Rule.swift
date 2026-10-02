import Foundation

/// Raw values match Foundation Calendar's weekday component, regardless of firstWeekday.
public enum Weekday: Int, Codable, CaseIterable, Hashable, Sendable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    public static let weekdays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
    public static let everyDay = Set(allCases)
}

public enum RuleValidationError: Error, Equatable, Sendable, LocalizedError {
    case emptyName, emptyLocationName, invalidLatitude, invalidLongitude, invalidRadius
    case noActiveDays, invalidMinute, equalStartAndEnd, emptyChecklist
    case emptyChecklistItem, duplicateChecklistIDs, invalidCooldown, invalidLastTriggeredAt

    public var errorDescription: String? {
        switch self {
        case .emptyName: return "Enter a rule name."
        case .emptyLocationName: return "Enter a location name."
        case .invalidLatitude: return "Latitude must be a finite number between -90 and 90."
        case .invalidLongitude: return "Longitude must be a finite number between -180 and 180."
        case .invalidRadius: return "Radius must be a finite number greater than zero."
        case .noActiveDays: return "Select at least one active day."
        case .invalidMinute: return "Time must be a minute between 00:00 and 23:59."
        case .equalStartAndEnd: return "Start and end times must differ."
        case .emptyChecklist: return "Add at least one checklist item."
        case .emptyChecklistItem: return "Checklist items cannot be blank."
        case .duplicateChecklistIDs: return "Each checklist item must have a unique ID."
        case .invalidCooldown: return "Cooldown must be a finite, nonnegative duration."
        case .invalidLastTriggeredAt: return "The last trigger date is invalid."
        }
    }
}

/// An item's ID survives renaming, reordering, and persistence. Completion belongs to
/// a particular departure checklist, and is deliberately not stored in the rule.
public struct ChecklistItem: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var text: String

    public init(id: UUID = UUID(), text: String) throws {
        self.id = id
        self.text = text
        try validate()
    }

    public func validate() throws {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw RuleValidationError.emptyChecklistItem
        }
    }

    private enum CodingKeys: String, CodingKey { case id, text }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(id: values.decode(UUID.self, forKey: .id),
                      text: values.decode(String.self, forKey: .text))
    }
}

/// Local wall-clock schedule. An overnight window belongs to the day it starts:
/// Monday 22:00–02:00 includes early Tuesday, but not early Monday.
/// Start is inclusive; end is exclusive. Equal times are invalid, not an all-day rule.
public struct Rule: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var locationName: String
    public var latitude: Double
    public var longitude: Double
    public var radiusMeters: Double
    public var activeDays: Set<Weekday>
    public var startMinute: Int
    public var endMinute: Int
    public var checklistItems: [ChecklistItem]
    public var isEnabled: Bool
    public var cooldownSeconds: TimeInterval
    public var lastTriggeredAt: Date?

    public init(
        id: UUID = UUID(),
        name: String,
        locationName: String = "Home",
        latitude: Double,
        longitude: Double,
        radiusMeters: Double = 100,
        activeDays: Set<Weekday>,
        startMinute: Int,
        endMinute: Int,
        checklistItems: [ChecklistItem],
        isEnabled: Bool = true,
        cooldownSeconds: TimeInterval = 300,
        lastTriggeredAt: Date? = nil
    ) throws {
        self.id = id
        self.name = name
        self.locationName = locationName
        self.latitude = latitude
        self.longitude = longitude
        self.radiusMeters = radiusMeters
        self.activeDays = activeDays
        self.startMinute = startMinute
        self.endMinute = endMinute
        self.checklistItems = checklistItems
        self.isEnabled = isEnabled
        self.cooldownSeconds = cooldownSeconds
        self.lastTriggeredAt = lastTriggeredAt
        try validate()
    }

    /// Revalidate after editing mutable fields. The evaluator and store also do this.
    public func validate() throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw RuleValidationError.emptyName
        }
        guard !locationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw RuleValidationError.emptyLocationName
        }
        guard latitude.isFinite, (-90...90).contains(latitude) else {
            throw RuleValidationError.invalidLatitude
        }
        guard longitude.isFinite, (-180...180).contains(longitude) else {
            throw RuleValidationError.invalidLongitude
        }
        // Core Location's device-specific monitoring maximum is enforced by the adapter.
        guard radiusMeters.isFinite, radiusMeters > 0 else {
            throw RuleValidationError.invalidRadius
        }
        guard !activeDays.isEmpty else { throw RuleValidationError.noActiveDays }
        guard (0..<1440).contains(startMinute), (0..<1440).contains(endMinute) else {
            throw RuleValidationError.invalidMinute
        }
        guard startMinute != endMinute else { throw RuleValidationError.equalStartAndEnd }
        guard !checklistItems.isEmpty else { throw RuleValidationError.emptyChecklist }
        for item in checklistItems { try item.validate() }
        guard Set(checklistItems.map(\.id)).count == checklistItems.count else {
            throw RuleValidationError.duplicateChecklistIDs
        }
        guard cooldownSeconds.isFinite, cooldownSeconds >= 0 else {
            throw RuleValidationError.invalidCooldown
        }
        if let lastTriggeredAt, !lastTriggeredAt.timeIntervalSince1970.isFinite {
            throw RuleValidationError.invalidLastTriggeredAt
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, locationName, latitude, longitude, radiusMeters, activeDays
        case startMinute, endMinute, checklistItems, isEnabled, cooldownSeconds, lastTriggeredAt
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            id: values.decode(UUID.self, forKey: .id),
            name: values.decode(String.self, forKey: .name),
            locationName: values.decode(String.self, forKey: .locationName),
            latitude: values.decode(Double.self, forKey: .latitude),
            longitude: values.decode(Double.self, forKey: .longitude),
            radiusMeters: values.decode(Double.self, forKey: .radiusMeters),
            activeDays: values.decode(Set<Weekday>.self, forKey: .activeDays),
            startMinute: values.decode(Int.self, forKey: .startMinute),
            endMinute: values.decode(Int.self, forKey: .endMinute),
            checklistItems: values.decode([ChecklistItem].self, forKey: .checklistItems),
            isEnabled: values.decode(Bool.self, forKey: .isEnabled),
            cooldownSeconds: values.decode(TimeInterval.self, forKey: .cooldownSeconds),
            lastTriggeredAt: values.decodeIfPresent(Date.self, forKey: .lastTriggeredAt)
        )
    }
}
