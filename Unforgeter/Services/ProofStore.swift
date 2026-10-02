import Foundation

/// Stores one proof zone, not a movement history. Errors are surfaced to the user.
struct ProofStore {
    private let url: URL

    init() {
        url = URL.applicationSupportDirectory
            .appending(path: "Unforgeter", directoryHint: .isDirectory)
            .appending(path: "proof-state.json")
    }

    func load() throws -> ProofState {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return ProofState()
        }
        let state = try JSONDecoder().decode(ProofState.self, from: Data(contentsOf: url))
        guard state.zone?.isValid != false else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return state
    }

    func save(_ state: ProofState) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try JSONEncoder().encode(state).write(
            to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]
        )
    }
}
