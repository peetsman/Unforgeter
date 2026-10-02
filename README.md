# Unforgeter

**Remember before you’re too far to turn back.**

Unforgeter is an iOS reminder app for recurring routines: leaving a chosen location during an active day/time window should open the right essentials checklist. Its proposed differentiation combines departure, schedule, and routine-specific items; location reminders already exist.

**Current state: the technical prototype builds and launches in an iPhone simulator; all 31 Rule tests pass.** Development happens on Windows, with native verification on GitHub's Mac runner. Physical geofence behavior remains unverified. See the [passing CI run](https://github.com/peetsman/Unforgeter/actions/runs/37032116531) and [verification status](docs/status.md).

## What is implemented

- A SwiftUI proof screen for one saved test zone, active every day at every time.
- Staged location permissions, notification permission/status, a current-location fix, and a MapKit radius preview.
- Core Location registration and exit handling, a persisted five-minute cooldown, and local notification submission.
- A notification tap opens a fixed sample checklist: Laptop, Charger, Keys. Checkmarks reset for each presentation.
- A session log and a Debug-only simulated notification, clearly separated from Core Location callbacks. A callback alone does not prove physical movement: simulated GPS can generate callbacks too.
- A separate [UnforgeterCore package](Packages/UnforgeterCore/README.md) containing validated Rules, pure schedule evaluation, JSON persistence, and 31 authored test methods.

The Rule package is **not yet wired into the iOS proof**. Custom Rule creation, editing, schedules, and personalized checklists remain the next product work after the physical feasibility test. There are no accounts, backend, cloud synchronization, AI, or accessory integrations.

[View the actual simulator launch screen](docs/images/simulator-launch.png). This is a technical test screen, not the finished Rules interface.

## Development setup

The app targets **iOS 17+**, using SwiftUI, Core Location, MapKit, and UserNotifications. The core package uses **Swift tools 5.9 / Swift language mode 5**. No third-party app dependencies are required.

On Windows, edit source and run repository metadata checks with Python 3:

```sh
python scripts/validate_repository.py
```

These checks verify file references and planning metadata, not Swift compilation. A Swift installation can run the core package independently, but native iOS building, signing, and device installation require Apple's macOS/Xcode toolchain. Check [Apple's Xcode compatibility table](https://developer.apple.com/xcode/system-requirements) against the intended Mac and iPhone.

Visual Studio's Remote iOS Simulator also uses a connected Mac; it is not a Windows-only route for running this SwiftUI project. [Microsoft: remote iOS simulation and Pair to Mac](https://learn.microsoft.com/en-us/dotnet/maui/deployment/)

### First run on a Mac

1. Open **[Unforgeter.xcodeproj](Unforgeter.xcodeproj)** directly in Xcode. The project and shared `Unforgeter` scheme are checked in; project generation is not required.
2. In Xcode's account settings, sign in with your Apple Account. In the app target's Signing & Capabilities settings, select your team, retain automatic signing, and use your own unique bundle identifier.
3. Pair the iPhone, follow its trust and Developer Mode prompts, and select it as the run destination. Build and run, then record the actual result.
4. Allow location while using the app, request the Always upgrade, enable Precise Location and notification alerts, and verify Background App Refresh is available.
5. Use the current location while inside the intended zone. Start with the **200 m experimental radius**, arm the zone, and wait for an inside-state confirmation.
6. Run without the debugger or simulated location, lock the phone, and physically walk beyond the region. Record the real callback and observed notification separately. Follow the [physical validation procedure](docs/geofencing-validation.md).

A Personal Team supports personal on-device testing without paid enrollment, with seven-day provisioning limits. Distribution and TestFlight are later milestones. [Apple: Personal Team and membership](https://developer.apple.com/support/compare-memberships/), [Apple: running on a device](https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices)

The radius is a requested region, not a precise trigger distance. iOS may report departure after a buffer or delay. Neither the 200 m starting point nor the 25/50 m experimental options guarantee useful timing. A successful simulated notification does not prove background geofencing.

## Verification commands

From the repository root, with Swift available:

```sh
swift test --package-path Packages/UnforgeterCore
```

On a Mac with Xcode and the iOS Simulator platform installed:

```sh
xcodebuild -project Unforgeter.xcodeproj -scheme Unforgeter \
  -configuration Debug -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/Debug CODE_SIGNING_ALLOWED=NO build
```

The [CI workflow](.github/workflows/ios.yml) uses `macos-15`, runs metadata checks and core tests, and builds Debug and Release for a generic iOS Simulator. Debug uses ad hoc signing for simulator installation; no Apple account credentials are required in CI. The launch smoke test checks that the app remains running after five seconds and saves a screenshot artifact. That check covers basic launch, not permission flows, checklist navigation, or physical departures. Executed results are recorded in [status](docs/status.md).

## Project planning

The [product brief](docs/product-brief.md) preserves the supplied decisions. The [backlog](docs/backlog.md) and [structured backlog](docs/backlog.json) contain 46 planned items across five milestones:

| Milestone | Focus |
| --- | --- |
| M0 — Project Setup | Repository, architecture, and technical foundation |
| M1 — Rules MVP | Create, persist, and manage Rules |
| M2 — Geofencing MVP | Real departures, Rule evaluation, and checklists |
| M3 — Product Polish | Accessibility, onboarding, and portfolio quality |
| M4 — Beta Release | Signing, TestFlight, and real-world feedback |

Preview the GitHub synchronization plan locally:

```sh
python scripts/sync_github_backlog.py
```

To publish the prepared backlog with authorized GitHub credentials:

```sh
python scripts/sync_github_backlog.py --apply
```

All 46 issues are [published on GitHub](https://github.com/peetsman/Unforgeter/issues), with one simple category label per issue. The [publication map](docs/github-backlog-map.json) records actual issue numbers. The apply mode creates only missing resources, preserves existing content, and avoids duplicates; it does not create a project board.

See [architecture](docs/architecture.md), [geofencing validation](docs/geofencing-validation.md), and [current status](docs/status.md) before extending the app. Keep real coordinates, signing material, and unredacted device logs out of Git.
