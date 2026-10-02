import Foundation

public enum RuleStoreError: Error, Equatable, Sendable, LocalizedError {
    case unsupportedSchemaVersion(Int)
    case duplicateRuleIDs

    public var errorDescription: String? {
        switch self {
        case .unsupportedSchemaVersion(let version):
            return "Rule file version \(version) is not supported. The file was preserved."
        case .duplicateRuleIDs:
            return "The rule file contains duplicate rule IDs."
        }
    }
}

/// A small local store intended for serialized use (for example, on the main actor).
/// All read, validation, and write errors propagate. Only a missing file means no rules.
/// Atomic writes replace a previously readable file; corrupt or newer files are preserved.
/// This is not a cross-process database or a concurrent read-modify-write transaction.
public struct JSONRuleStore: Sendable {
    public let fileURL: URL

    public init(fileURL: URL) { self.fileURL = fileURL }

    public func load() throws -> [Rule] {
        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            let cocoaError = error as NSError
            if cocoaError.domain == NSCocoaErrorDomain,
               cocoaError.code == NSFileReadNoSuchFileError {
                return []
            }
            throw error
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        // Read the version before the rules so newer schemas fail with a useful error.
        let header = try decoder.decode(Header.self, from: data)
        guard header.schemaVersion == 1 else {
            throw RuleStoreError.unsupportedSchemaVersion(header.schemaVersion)
        }
        let envelope = try decoder.decode(Envelope.self, from: data)
        try Self.validate(envelope.rules)
        return envelope.rules
    }

    public func save(_ rules: [Rule]) throws {
        try Self.validate(rules)
        // Avoid replacing unreadable, corrupted, or newer data with an in-memory default.
        _ = try load()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(Envelope(schemaVersion: 1, rules: rules))
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try data.write(to: fileURL, options: .atomic)
    }

    private static func validate(_ rules: [Rule]) throws {
        for rule in rules { try rule.validate() }
        guard Set(rules.map(\.id)).count == rules.count else {
            throw RuleStoreError.duplicateRuleIDs
        }
    }

    private struct Header: Decodable { let schemaVersion: Int }
    private struct Envelope: Codable {
        let schemaVersion: Int
        let rules: [Rule]
    }
}
