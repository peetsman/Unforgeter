# Unforgeter working agreement

Read README.md, docs/product-brief.md, docs/architecture.md, and docs/backlog.md before substantial changes. The supplied brief records settled decisions; do not ask the user to repeat them.

- iOS first: Swift, SwiftUI, Core Location, MapKit, UserNotifications; local persistence and no backend for MVP.
- First gate: a physical iPhone receives a local notification after a genuine geofence exit. A simulation, successful build, or passing unit test does not prove this gate.
- Keep the first implementation small. Accounts, AI, social features, cloud sync, watches, and tracking accessories are outside MVP.
- The current development host is Windows with no Mac access. Never claim an iOS build, simulator run, or physical-device test passed without evidence.
- Independently test schedule logic and persistence in Packages/UnforgeterCore. Use an injected Calendar and date for deterministic time tests.
- Keep personal coordinates, signing material, credentials, and unredacted device logs out of Git.
- Preserve the existing GitHub repository and history. Use codex/ branches for changes. Source planning numbers in the backlog are not assumed GitHub issue numbers.
- Record technical decisions and verification limitations. Prefer a small implementation over speculative abstractions.
- Keep GitHub issue labels sparse: one simple category per issue by default, never more than two. The user prefers this over multiple topic, priority, and MVP badges.
