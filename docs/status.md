# Project status

Snapshot: 2026-10-02. **Source and verification tooling are prepared; native execution and physical geofencing remain unverified.** The current development host is Windows and the developer has no Mac access.

## Prepared locally

- Checked-in Xcode project and shared scheme for the iOS 17 SwiftUI proof.
- One saved, always-active test zone; permission flow; current-location placement; radius map; exit notification; and fixed example checklist.
- A persisted five-minute proof cooldown, explicit stopped/error states, and Debug-only simulation.
- A separate Rule model/evaluator/JSON store with 31 authored XCTest methods. Scheduled Rules are not connected to the proof app.
- Product context, architecture, physical test procedure, and 46 planned backlog items across M0–M4.
- Python repository checks and an idempotent GitHub backlog synchronization script.
- A prepared `macos-15` CI workflow for metadata checks, core tests, unsigned Debug/Release simulator builds, and a simulator launch smoke test with screenshot evidence.

## Verification record

| Check | Current evidence |
| --- | --- |
| Python repository metadata validation | Passed on Windows, 2026-10-02: every app source/project reference, shared scheme target, permission text, and 46-item/five-milestone planning structure checked. Project regeneration is deterministic. |
| Swift package compilation and 31 tests | Authored and reviewed; not executed in the initial Windows environment. |
| Xcode project/native Swift compilation | Not verified. |
| Simulator launch | Smoke script prepared; execution and screenshot pending. It checks process survival, not interaction flows. |
| Signing and physical-iPhone installation | Not verified. |
| Real foreground and locked-background exit | Not verified. |
| Notification tap/checklist on a device | Not verified. |
| Actual radius, delay, missed events, duplicates, battery behavior | No measured results. |
| CI execution | Workflow prepared; no passing run recorded here. |
| GitHub backlog publication | Local plan/script prepared; no remote resource creation established by this document. |

Update a row only with an actual command result, CI run, or device record. A generated project or static source review does not establish build success. Passing core tests or simulation does not establish physical geofence reliability.

## Immediate next steps

1. Publish the branch and inspect the macOS CI build/test/launch results.
2. Obtain access to a compatible Mac/Xcode environment and run `swift test --package-path Packages/UnforgeterCore` plus the native build command in the [README](../README.md).
3. Open `Unforgeter.xcodeproj`, configure the owner's signing team and unique bundle identifier, and install on the iPhone.
4. Follow the [physical validation procedure](geofencing-validation.md): confirm inside, lock the phone, physically leave, and record callback and observed alert times. Start at 200 m without assuming delivery at that distance.
5. Review whether real reminders arrive early enough on the intended route, retaining misses and duplicates. Then build the full Rules interface and connect its evaluator/persistence.

The first technical gate is an observed notification from a genuine physical departure. Multiple trials and broader supported-device testing are needed before making reliability claims. The 25/50 m options, exact timing, and “soon enough to turn back” value remain hypotheses until measured.

## Scope preserved

The project remains iOS first and local first, using Swift/SwiftUI and native Apple services. The brief's five milestones and 46 planning items are retained. No milestone is declared complete merely because its foundation exists; M0 still includes a successful build and source publication, and the full Rule-aware M2 criteria exceed this proof.

Visual Studio's Remote iOS Simulator still uses a Mac host, so it does not remove the current native-testing dependency. The Windows host can continue source, documentation, and portable logic work while the physical-device path is arranged. [Microsoft documentation](https://learn.microsoft.com/en-us/dotnet/maui/deployment/)
