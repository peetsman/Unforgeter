import Foundation

public enum RuleEvaluation: Equatable, Sendable {
    case trigger
    case disabled
    case inactiveDay
    case outsideTimeWindow
    case cooldown(until: Date)
    case invalidRule

    public var shouldTrigger: Bool { self == .trigger }
}

/// Pure decision logic for a known rule's EXIT event. This does not register regions,
/// deliver notifications, or mutate lastTriggeredAt. The caller records that timestamp
/// after successfully scheduling a notification and persists the updated rule.
public enum RuleEvaluator {
    public static func evaluate(
        _ rule: Rule,
        at date: Date,
        calendar: Calendar = .current
    ) -> RuleEvaluation {
        do {
            try rule.validate()
        } catch {
            return .invalidRule
        }
        guard date.timeIntervalSince1970.isFinite else {
            return .invalidRule
        }
        guard rule.isEnabled else { return .disabled }

        let components = calendar.dateComponents([.hour, .minute], from: date)
        guard let hour = components.hour, let minute = components.minute else {
            return .invalidRule
        }
        let wallClockMinute = hour * 60 + minute
        let overnight = rule.startMinute > rule.endMinute
        let scheduleDate: Date
        if overnight && wallClockMinute < rule.endMinute {
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: date) else {
                return .invalidRule
            }
            scheduleDate = previousDay
        } else {
            scheduleDate = date
        }

        guard let day = Weekday(rawValue: calendar.component(.weekday, from: scheduleDate)),
              rule.activeDays.contains(day) else { return .inactiveDay }

        let insideWindow = overnight
            ? wallClockMinute >= rule.startMinute || wallClockMinute < rule.endMinute
            : wallClockMinute >= rule.startMinute && wallClockMinute < rule.endMinute
        guard insideWindow else { return .outsideTimeWindow }

        if let lastTriggeredAt = rule.lastTriggeredAt {
            let nextAllowed = lastTriggeredAt.addingTimeInterval(rule.cooldownSeconds)
            // A future last-trigger timestamp (e.g. a clock adjustment) also suppresses
            // delivery until that timestamp plus cooldown. Exact cooldown expiry allows it.
            guard date >= nextAllowed else { return .cooldown(until: nextAllowed) }
        }
        return .trigger
    }
}
