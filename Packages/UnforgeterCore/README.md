# UnforgeterCore

Foundation-only Swift package for the first native iOS geofence experiment. It contains the rule model, a pure exit-event evaluator, and versioned JSON persistence. It does not request permissions, monitor location, schedule notifications, or require SwiftData.

- Swift tools 5.9, Swift language mode 5; iOS 17 or macOS 13 and later.
- Rules and checklist items have stable UUIDs. Editing text or changing order preserves item identity.
- Times are local wall-clock minutes (`0..<1440`). Start is inclusive and end exclusive. Equal start/end times are invalid. An overnight interval belongs to its starting weekday.
- Pass a calendar with an explicit time zone in tests. The app uses the current local calendar at the exit event. A skipped daylight-saving hour cannot match an event; a repeated hour matches its wall-clock time, with cooldown measured in elapsed seconds.
- `RuleEvaluator.evaluate(_:at:calendar:)` returns a reason and `shouldTrigger`. Only call it for a corresponding region exit. Evaluation has no side effects; the app must update `lastTriggeredAt` after a notification is successfully scheduled and save that rule.
- Coordinates, positive finite radius, schedule, checklist text/IDs, and cooldown are validated on construction, decoding, evaluation, and saving. Core Location's device-specific maximum radius belongs in the iOS adapter.
- `JSONRuleStore` requires serialized access, such as from the main actor. It writes atomically. Missing files load as an empty list; corrupted, inaccessible, or newer-schema files throw. Saving refuses to overwrite a file it cannot successfully load. Recovery or migrations must be explicit.

Run the test suite from this directory on a machine with Swift installed:

```sh
swift test
```

Tests cover the project brief's examples, schedule boundaries, overnight attribution, time zones and daylight-saving transitions, cooldown, validation, checklist identity, persistence round trips, and preservation of malformed files. The initial Windows authoring environment has no Swift toolchain; these tests were written and statically reviewed but were not executed there. A successful macOS CI or local Swift run is required to verify compilation and test results.
