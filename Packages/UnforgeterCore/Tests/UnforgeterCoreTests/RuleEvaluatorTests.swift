import Foundation
import XCTest
@testable import UnforgeterCore

final class RuleEvaluatorTests: XCTestCase {
    private var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(_ iso: String) throws -> Date {
        try XCTUnwrap(ISO8601DateFormatter().date(from: iso))
    }

    private func morningClass() throws -> Rule {
        try Rule(
            name: "Morning Class", latitude: 40.0, longitude: -75.0, radiusMeters: 50,
            activeDays: Weekday.weekdays, startMinute: 6 * 60 + 30, endMinute: 8 * 60 + 30,
            checklistItems: ["Laptop", "Charger", "Student ID", "Water bottle"].map {
                try ChecklistItem(text: $0)
            }
        )
    }

    func testBriefMondayMorningExampleTriggers() throws {
        let rule = try morningClass()
        XCTAssertEqual(RuleEvaluator.evaluate(rule, at: try date("2026-09-28T07:15:00Z"), calendar: utc), .trigger)
    }

    func testBriefTuesdayDepartureExampleTriggers() throws {
        let rule = try morningClass()
        XCTAssertTrue(RuleEvaluator.evaluate(rule, at: try date("2026-09-29T07:12:00Z"), calendar: utc).shouldTrigger)
    }

    func testBriefMondayTenAMIsOutsideWindow() throws {
        let rule = try morningClass()
        XCTAssertEqual(RuleEvaluator.evaluate(rule, at: try date("2026-09-28T10:00:00Z"), calendar: utc), .outsideTimeWindow)
    }

    func testBriefAfternoonDepartureDoesNotTrigger() throws {
        let rule = try morningClass()
        XCTAssertFalse(RuleEvaluator.evaluate(rule, at: try date("2026-09-29T14:00:00Z"), calendar: utc).shouldTrigger)
    }

    func testBriefSaturdayIsInactive() throws {
        let rule = try morningClass()
        XCTAssertEqual(RuleEvaluator.evaluate(rule, at: try date("2026-10-03T07:15:00Z"), calendar: utc), .inactiveDay)
    }

    func testDisabledRuleDoesNotTrigger() throws {
        var rule = try morningClass()
        rule.isEnabled = false
        XCTAssertEqual(RuleEvaluator.evaluate(rule, at: try date("2026-09-28T07:15:00Z"), calendar: utc), .disabled)
    }

    func testStartInclusiveEndExclusiveDownToSecond() throws {
        let rule = try morningClass()
        let examples: [(String, Bool)] = [
            ("2026-09-28T06:29:59Z", false),
            ("2026-09-28T06:30:00Z", true),
            ("2026-09-28T08:29:59Z", true),
            ("2026-09-28T08:30:00Z", false)
        ]
        for (timestamp, expected) in examples {
            XCTAssertEqual(RuleEvaluator.evaluate(rule, at: try date(timestamp), calendar: utc).shouldTrigger,
                           expected, timestamp)
        }
    }

    func testOvernightWindowBelongsToItsStartDay() throws {
        var rule = try morningClass()
        rule.activeDays = [.monday]
        rule.startMinute = 22 * 60
        rule.endMinute = 2 * 60
        let examples: [(String, Bool)] = [
            ("2026-09-28T01:00:00Z", false), // Monday's early morning belongs to Sunday.
            ("2026-09-28T21:59:59Z", false),
            ("2026-09-28T22:00:00Z", true),
            ("2026-09-29T00:00:00Z", true),
            ("2026-09-29T01:59:59Z", true),
            ("2026-09-29T02:00:00Z", false),
            ("2026-09-29T22:00:00Z", false)
        ]
        for (timestamp, expected) in examples {
            XCTAssertEqual(RuleEvaluator.evaluate(rule, at: try date(timestamp), calendar: utc).shouldTrigger,
                           expected, timestamp)
        }
    }

    func testOvernightCrossesWeekBoundary() throws {
        var rule = try morningClass()
        rule.activeDays = [.saturday]
        rule.startMinute = 23 * 60
        rule.endMinute = 60
        XCTAssertTrue(RuleEvaluator.evaluate(rule, at: try date("2026-10-04T00:30:00Z"), calendar: utc).shouldTrigger)
    }

    func testMidnightCanBeAnExclusiveEnd() throws {
        var rule = try morningClass()
        rule.activeDays = [.monday]
        rule.startMinute = 23 * 60
        rule.endMinute = 0
        XCTAssertTrue(RuleEvaluator.evaluate(rule, at: try date("2026-09-28T23:59:59Z"), calendar: utc).shouldTrigger)
        XCTAssertFalse(RuleEvaluator.evaluate(rule, at: try date("2026-09-29T00:00:00Z"), calendar: utc).shouldTrigger)
    }

    func testCooldownSuppressesDuplicatesUntilExactExpiry() throws {
        var rule = try morningClass()
        rule.lastTriggeredAt = try date("2026-09-28T07:00:00Z")
        rule.cooldownSeconds = 300
        let expiry = try date("2026-09-28T07:05:00Z")
        XCTAssertEqual(RuleEvaluator.evaluate(rule, at: try date("2026-09-28T07:04:59Z"), calendar: utc), .cooldown(until: expiry))
        XCTAssertEqual(RuleEvaluator.evaluate(rule, at: expiry, calendar: utc), .trigger)
    }

    func testClockMovingBackwardDoesNotBypassCooldown() throws {
        var rule = try morningClass()
        rule.lastTriggeredAt = try date("2026-09-28T07:10:00Z")
        let expiry = try date("2026-09-28T07:15:00Z")
        XCTAssertEqual(RuleEvaluator.evaluate(rule, at: try date("2026-09-28T07:00:00Z"), calendar: utc), .cooldown(until: expiry))
    }

    func testZeroCooldownAllowsSameTimestamp() throws {
        var rule = try morningClass()
        let now = try date("2026-09-28T07:00:00Z")
        rule.lastTriggeredAt = now
        rule.cooldownSeconds = 0
        XCTAssertEqual(RuleEvaluator.evaluate(rule, at: now, calendar: utc), .trigger)
    }

    func testScheduleUsesSuppliedLocalTimeZone() throws {
        let rule = try morningClass()
        var newYork = utc
        newYork.timeZone = try XCTUnwrap(TimeZone(identifier: "America/New_York"))
        let instant = try date("2026-09-28T11:15:00Z") // 07:15 in New York.
        XCTAssertEqual(RuleEvaluator.evaluate(rule, at: instant, calendar: newYork), .trigger)
        XCTAssertEqual(RuleEvaluator.evaluate(rule, at: instant, calendar: utc), .outsideTimeWindow)
    }

    func testFallBackRepeatedHourUsesWallClockAndAbsoluteCooldown() throws {
        var rule = try morningClass()
        rule.activeDays = [.sunday]
        rule.startMinute = 60
        rule.endMinute = 2 * 60
        rule.cooldownSeconds = 90 * 60
        var newYork = utc
        newYork.timeZone = try XCTUnwrap(TimeZone(identifier: "America/New_York"))
        let firstOneThirty = try date("2026-11-01T05:30:00Z")
        let secondOneThirty = try date("2026-11-01T06:30:00Z")
        XCTAssertTrue(RuleEvaluator.evaluate(rule, at: firstOneThirty, calendar: newYork).shouldTrigger)
        XCTAssertTrue(RuleEvaluator.evaluate(rule, at: secondOneThirty, calendar: newYork).shouldTrigger)
        rule.lastTriggeredAt = firstOneThirty
        XCTAssertEqual(RuleEvaluator.evaluate(rule, at: secondOneThirty, calendar: newYork),
                       .cooldown(until: firstOneThirty.addingTimeInterval(90 * 60)))
    }

    func testSpringForwardOvernightStillUsesPreviousCalendarDay() throws {
        var rule = try morningClass()
        rule.activeDays = [.saturday]
        rule.startMinute = 22 * 60
        rule.endMinute = 4 * 60
        var newYork = utc
        newYork.timeZone = try XCTUnwrap(TimeZone(identifier: "America/New_York"))
        // The clock has jumped from 01:59:59 to 03:00:00. This is Sunday 03:30 EDT.
        XCTAssertTrue(RuleEvaluator.evaluate(rule, at: try date("2026-03-08T07:30:00Z"), calendar: newYork).shouldTrigger)
    }

    func testMutatedInvalidRuleFailsClosed() throws {
        var rule = try morningClass()
        rule.startMinute = rule.endMinute
        XCTAssertEqual(RuleEvaluator.evaluate(rule, at: try date("2026-09-28T07:15:00Z"), calendar: utc), .invalidRule)
    }
}
