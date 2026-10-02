import Foundation
import XCTest
@testable import UnforgeterCore

final class RuleAndPersistenceTests: XCTestCase {
    private func rule() throws -> Rule {
        try Rule(
            name: "Morning Class", latitude: 40, longitude: -75, radiusMeters: 50,
            activeDays: Weekday.weekdays, startMinute: 390, endMinute: 510,
            checklistItems: [try ChecklistItem(text: "Laptop"), try ChecklistItem(text: "Charger")]
        )
    }

    private func withStore(_ test: (JSONRuleStore) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try test(JSONRuleStore(fileURL: directory.appendingPathComponent("rules.json")))
    }

    func testValidationRejectsInvalidEdits() throws {
        let examples: [(RuleValidationError, (inout Rule) -> Void)] = [
            (.emptyName, { $0.name = " \n" }),
            (.emptyLocationName, { $0.locationName = "\t" }),
            (.invalidLatitude, { $0.latitude = 91 }),
            (.invalidLatitude, { $0.latitude = .nan }),
            (.invalidLongitude, { $0.longitude = -181 }),
            (.invalidLongitude, { $0.longitude = .infinity }),
            (.invalidRadius, { $0.radiusMeters = 0 }),
            (.invalidRadius, { $0.radiusMeters = -1 }),
            (.invalidRadius, { $0.radiusMeters = .infinity }),
            (.noActiveDays, { $0.activeDays = [] }),
            (.invalidMinute, { $0.startMinute = -1 }),
            (.invalidMinute, { $0.endMinute = 1440 }),
            (.equalStartAndEnd, { $0.endMinute = $0.startMinute }),
            (.emptyChecklist, { $0.checklistItems = [] }),
            (.emptyChecklistItem, { $0.checklistItems[0].text = " " }),
            (.duplicateChecklistIDs, { $0.checklistItems.append($0.checklistItems[0]) }),
            (.invalidCooldown, { $0.cooldownSeconds = -1 }),
            (.invalidCooldown, { $0.cooldownSeconds = .nan }),
            (.invalidLastTriggeredAt, { $0.lastTriggeredAt = Date(timeIntervalSince1970: .infinity) })
        ]
        for (expected, mutate) in examples {
            var candidate = try rule()
            mutate(&candidate)
            XCTAssertThrowsError(try candidate.validate()) { error in
                XCTAssertEqual(error as? RuleValidationError, expected)
            }
        }
    }

    func testCoordinateEdgesAreValid() throws {
        var candidate = try rule()
        candidate.latitude = -90
        candidate.longitude = 180
        XCTAssertNoThrow(try candidate.validate())
        candidate.latitude = 90
        candidate.longitude = -180
        XCTAssertNoThrow(try candidate.validate())
    }

    func testChecklistIDSurvivesRenameAndReorder() throws {
        var candidate = try rule()
        let firstID = candidate.checklistItems[0].id
        candidate.checklistItems[0].text = "Work laptop"
        candidate.checklistItems.reverse()
        XCTAssertEqual(candidate.checklistItems[1].id, firstID)
        XCTAssertEqual(candidate.checklistItems[1].text, "Work laptop")
    }

    func testBlankChecklistCannotBeConstructed() {
        XCTAssertThrowsError(try ChecklistItem(text: "\n\t "))
    }

    func testRuleConstructorValidates() {
        XCTAssertThrowsError(try Rule(
            name: "Test", latitude: 100, longitude: 0, activeDays: [.monday],
            startMinute: 0, endMinute: 60, checklistItems: [try ChecklistItem(text: "Keys")]
        ))
    }

    func testMissingFileLoadsEmpty() throws {
        try withStore { store in XCTAssertEqual(try store.load(), []) }
    }

    func testJSONRoundTripPreservesIDsOrderAndTriggerDate() throws {
        try withStore { store in
            var expected = try rule()
            expected.lastTriggeredAt = Date(timeIntervalSince1970: 1_790_600_000.125)
            expected.checklistItems.reverse()
            try store.save([expected])
            let reloaded = try JSONRuleStore(fileURL: store.fileURL).load()
            XCTAssertEqual(reloaded, [expected])
        }
    }

    func testStorePersistsUpdateAndDeletion() throws {
        try withStore { store in
            var candidate = try rule()
            try store.save([candidate])
            candidate.name = "Updated rule"
            candidate.isEnabled = false
            try store.save([candidate])
            XCTAssertEqual(try store.load(), [candidate])
            try store.save([])
            XCTAssertEqual(try store.load(), [])
        }
    }

    func testSaveCreatesParentDirectory() throws {
        try withStore { original in
            let nested = JSONRuleStore(fileURL: original.fileURL.deletingLastPathComponent()
                .appendingPathComponent("nested", isDirectory: true).appendingPathComponent("rules.json"))
            let expected = try rule()
            try nested.save([expected])
            XCTAssertEqual(try nested.load(), [expected])
        }
    }

    func testCorruptFileIsReportedAndNeverOverwritten() throws {
        try withStore { store in
            let original = Data("{broken-json".utf8)
            try original.write(to: store.fileURL)
            XCTAssertThrowsError(try store.load())
            XCTAssertThrowsError(try store.save([]))
            XCTAssertEqual(try Data(contentsOf: store.fileURL), original)
        }
    }

    func testNewerSchemaIsReportedAndNeverOverwritten() throws {
        try withStore { store in
            let original = Data("{\"schemaVersion\":99,\"futureData\":true}".utf8)
            try original.write(to: store.fileURL)
            XCTAssertThrowsError(try store.load()) { error in
                XCTAssertEqual(error as? RuleStoreError, .unsupportedSchemaVersion(99))
            }
            XCTAssertThrowsError(try store.save([]))
            XCTAssertEqual(try Data(contentsOf: store.fileURL), original)
        }
    }

    func testInvalidDecodedRuleIsRejectedAndPreserved() throws {
        try withStore { store in
            try store.save([rule()])
            var root = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: store.fileURL)) as? [String: Any])
            var rules = try XCTUnwrap(root["rules"] as? [[String: Any]])
            rules[0]["radiusMeters"] = -1
            root["rules"] = rules
            let original = try JSONSerialization.data(withJSONObject: root)
            try original.write(to: store.fileURL)
            XCTAssertThrowsError(try store.load()) { error in
                XCTAssertEqual(error as? RuleValidationError, .invalidRadius)
            }
            XCTAssertThrowsError(try store.save([]))
            XCTAssertEqual(try Data(contentsOf: store.fileURL), original)
        }
    }

    func testDuplicateRuleIDsAreRejectedWithoutReplacingSavedData() throws {
        try withStore { store in
            let candidate = try rule()
            try store.save([candidate])
            let original = try Data(contentsOf: store.fileURL)
            XCTAssertThrowsError(try store.save([candidate, candidate])) { error in
                XCTAssertEqual(error as? RuleStoreError, .duplicateRuleIDs)
            }
            XCTAssertEqual(try Data(contentsOf: store.fileURL), original)
        }
    }

    func testDirectoryAtFilePathIsAnErrorInsteadOfEmptyState() throws {
        try withStore { store in
            try FileManager.default.createDirectory(at: store.fileURL, withIntermediateDirectories: true)
            XCTAssertThrowsError(try store.load())
            XCTAssertThrowsError(try store.save([]))
        }
    }
}
