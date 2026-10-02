# Geofencing validation

Status: **not yet validated on a physical iPhone**. Research checked against Apple sources on 2026-10-02. The developer currently has Windows only. Source review, rule-engine tests, a simulator route, and a “Simulate Exit” button cannot prove the central product promise.

The first experiment is deliberately small: register one region while inside it, physically leave, and observe a local “You left the zone” notification with the phone locked. The current app uses one all-day proof zone and a fixed example checklist; the independently testable Rule model and evaluator are not yet connected to this screen. Build the full Rules interface after this experiment establishes useful behavior.

## What this experiment can establish

Separate three questions:

1. **Code correctness:** Does a received exit submit the expected proof notification and open its example checklist? Later, does the integrated Rule engine select the right checklist?
2. **Delivery feasibility:** Does a physical iPhone receive a real exit callback and present its notification while the app is backgrounded?
3. **Product usefulness:** Is that reminder early enough to turn back on the user's actual routes?

Passing the first question does not answer the other two. Even several successful walks establish evidence for those conditions, not a general reliability guarantee. The planned 25 m and 50 m options remain product hypotheses.

## API choice for this spike

Use `CLLocationManager`, `CLCircularRegion`, and delegate callbacks for the iOS 17 baseline. Keep the location manager alive and initialize the service during app launch, including launches without a visible SwiftUI screen. This is a bounded engineering choice to make the first experiment and its logs easy to inspect; it is not a claim that the older API is more reliable.

The current Apple reference marks `startMonitoring(for:)` as deprecated. Its documented callbacks, shared monitored-region set, 20-region limit, and error callback remain relevant to this implementation. Revisit the replacement API before committing to a release SDK. Multiple rules with identical centers and radii should eventually share a monitored region rather than each consuming one. [Apple: startMonitoring(for:)](https://developer.apple.com/documentation/corelocation/cllocationmanager/startmonitoring(for:))

`CLMonitor` is another route, available for the iOS 17 generation, but it requires continued event iteration and recreation of the same named monitor after a background launch. Its lifecycle must be treated as part of the implementation. Newer authorization sessions add an additional concern: Apple explains that modern event APIs need an ongoing session established while in use to deliver outside that state. Switching APIs alone does not establish reliability. [Apple: monitoring geographic regions](https://developer.apple.com/documentation/corelocation/monitoring-the-user-s-proximity-to-geographic-regions), [Apple: What's new in location authorization](https://developer.apple.com/videos/play/wwdc2024/10212/)

For the callback implementation:

- Persist the test region definition, identifier, and cooldown locally. The current on-screen event history lasts only for the running process; capture it before terminating the app. A persisted, bounded log without coordinates is a follow-up improvement for relaunch investigations.
- Check monitoring support and report registration failures. Treat a submitted registration separately from the `didStartMonitoringFor` confirmation.
- Request region state after registration. An initial outside state is not a departure; start the field test from a confirmed inside state.
- On an exit, record the callback time, then submit the local notification promptly. Avoid network work in this path.
- Restore the service at launch and reconcile saved configuration with the system's monitored regions. Avoid restarting an unchanged registration on every foreground transition.
- Remove monitoring when the test is stopped; ignore callbacks whose identifier is no longer active.

Apple's archived region guide explains that registration while already inside does not itself generate entry, and that boundary transitions involve a system-controlled cushion. Its old timing and distance examples are useful historical context, **not present-day delivery promises**. [Apple: archived region-monitoring guide](https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/LocationAwarenessPG/RegionMonitoring/RegionMonitoring.html)

## Permissions and platform limits

Ask for When In Use when the person chooses their test location, then explain why the departure feature needs Always and request that upgrade through an explicit action. Include both `NSLocationWhenInUseUsageDescription` and `NSLocationAlwaysAndWhenInUseUsageDescription`. Read the resulting status rather than assuming the request succeeded. Apple permits the separate Always request after When In Use only once; subsequent recovery may require Settings. Always enables system launch for region events; When In Use does not provide that launch behavior. [Apple: requesting location authorization](https://developer.apple.com/documentation/corelocation/requesting-authorization-to-use-location-services)

Check `accuracyAuthorization` too. Reduced accuracy prevents region-monitoring events; setting `desiredAccuracy` cannot override that permission. Explain the need for Precise Location and allow the user to restore it in Settings. [Apple: accuracyAuthorization](https://developer.apple.com/documentation/corelocation/cllocationmanager/accuracyauthorization), [Apple: What's new in location](https://developer.apple.com/videos/play/wwdc2020/10660/)

Check notification authorization and alert settings before the experiment. Authorization to submit a notification does not establish that a banner or sound was perceived. Foreground presentation needs the notification-center delegate, and device presentation settings must be recorded. Log notification submission success separately from the tester's observed delivery. [Apple: asking notification permission](https://developer.apple.com/documentation/usernotifications/asking-permission-to-use-notifications), [Apple: scheduling a local notification](https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app)

Do not enable continuous background location updates for this region-only spike. An Apple engineer confirms that `UIBackgroundModes = location` is for continuous standard location updates and is unnecessary for region monitoring. The test needs no location push service or remote-notification server. [Apple engineering: background mode and region monitoring](https://developer.apple.com/forums/thread/818370)

Background App Refresh is a separate setting. Apple’s archived guidance says disabling it prevents region-event wakeups. Record it as a prerequisite and verify the actual supported iOS version rather than silently assuming availability. [Apple: archived location guide](https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/LocationAwarenessPG/CoreLocation/CoreLocation.html)

Do not state categorically that force-quitting disables geofencing. An Apple engineer's March 2026 response says region monitoring can relaunch a force-quit app and discusses relaunch throttling and environment-dependent practical radii. The answer describes roughly 100–500 m or more in some settings, not a universal minimum. Treat force-quit behavior as its own physical-device experiment. [Apple engineering: region monitoring after force-quit](https://developer.apple.com/forums/thread/818908)

## Getting from Windows to the iPhone test

Windows remains useful for editing Swift source, documentation, and portable logic. This native SwiftUI/Core Location app needs a macOS build environment with Xcode before it can be built, signed, and installed on the iPhone. Access to a compatible Mac through a school lab, an existing machine, or a collaborator is the first dependency; a cloud build alone does not perform the physical walk test. Check the intended Mac and iPhone OS against Apple's current compatibility table before arranging access. [Apple: Xcode system requirements](https://developer.apple.com/xcode/system-requirements)

On that Mac:

1. Open the project in an Xcode version that supports the phone's iOS version and the project's deployment target.
2. Sign into Xcode with the owner's Apple Account, choose the Personal Team, enable automatic signing, and select a unique bundle identifier.
3. Pair the iPhone and follow the device's trust and Developer Mode prompts. Select it as the run destination and build/run.
4. Record the actual compiler, SDK, device model, iOS version, and build revision. Address build errors before marking the scaffold buildable.
5. For field measurements, run the installed app without an attached debugger. Disable simulated location in the scheme.

Personal on-device testing is available without paid enrollment, with provisioning that expires after seven days and requires reprovisioning/reinstallation. That is sufficient to start this experiment. [Apple: membership and Personal Team limits](https://developer.apple.com/support/compare-memberships/)

Apple documents automatic signing, physical run destinations, and running without the debugger; its simulator does not reproduce every physical-device feature. Developer Mode is required for locally installed development builds. [Apple: run on simulated or physical devices](https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices), [Apple: enable Developer Mode](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device)

## Physical-device procedure

Use a walking route first. If testing a driving route later, a passenger records observations; do not interact with the phone while driving.

1. Record permissions, Precise Location, Background App Refresh, notification alert settings, Focus/Scheduled Summary, Low Power Mode, Wi-Fi/cellular availability, and whether a debugger is attached.
2. Stand inside the intended zone. Capture a fresh usable location fix and record its reported horizontal accuracy. Start at a 200 m requested radius as an experimental baseline, not a claimed minimum.
3. Register the zone and wait for registration and an inside-state confirmation. If state stays unknown or outside, resolve that before counting a departure trial.
4. Lock the phone, put it away, and walk well beyond the displayed circle. Record the approximate boundary-crossing time independently. The circle represents the requested geometry, not a detection guarantee.
5. Record when the notification is first observed, the approximate distance already traveled, and whether turning back still feels practical. Inspect and capture the current session's callback/submission logs afterward, before terminating the app.
6. If nothing arrives, retain the failed trial, settings, elapsed observation period, and route. Do not label it successful because a later simulation works.
7. Return clearly inside, wait for confirmed re-entry, and repeat. The proof app deliberately suppresses real alerts for five minutes after its last successful submission; wait beyond that cooldown for a second expected alert. Allow time between tests so rapid oscillation does not become the only scenario measured.

For each trial, keep callback delay and notification observation delay separate. A local event log timestamp is not the physical crossing time. Avoid collecting a continuous route or publishing private home coordinates for this experiment.

## Acceptance matrix

All rows are **pending** until a tester records a result and attaches evidence.

| Test | Setup/action | Required observation |
| --- | --- | --- |
| Clean build/install | Real iPhone; supported Xcode; recorded revision | Build succeeds, app opens, permission copy appears correctly. |
| Foreground real departure | Registered inside; walk beyond zone with app open | Real exit log and expected local alert; no simulated event counted. |
| Locked background departure | Launch normally without debugger; lock; walk outside | Exit and notification occur without reopening the app. Record time and distance. |
| Repeated departure | Return, confirm inside, then leave again | A second legitimate departure is observed; record missed and duplicate alerts. |
| Stable inside | Remain inside through a routine preparation period | No departure alert; any false exit is a failure to investigate. |
| Initial outside | Register while known outside | State query alone does not send “You left the zone.” |
| Stop monitoring | Stop, then cross former boundary | No new departure notification from the stopped test. |
| Relaunch/reconciliation | Leave app, reopen; inspect saved/system region | Configuration persists and there is one intended registration. |
| System termination | Observe or reproduce system termination separately | If a region launch occurs, initialization restores the handler and notification path. Do not equate a debugger Stop with all OS termination cases. |
| User force-quit | Arm inside; swipe away; depart after normal dwell | Record actual relaunch/delivery behavior separately; repeat after manual reopening. |
| Reboot | Reboot; test before and after first unlock/reopen | Record restoration behavior; do not promise monitoring before first unlock. |
| Location denied/restricted | Remove permission or use restricted state | Clear unavailable state; no claim that the test is armed successfully. |
| When In Use only | Decline Always upgrade | UI explains that background-launch validation requirements are unmet. |
| Precise Location off | Change to reduced accuracy | UI identifies the unmet prerequisite; no precision/reliability claim. |
| Notifications denied | Disable notifications | UI identifies blocked notification delivery and does not report “delivered.” |
| Background App Refresh off | Disable globally or for app | UI exposes the limitation; record actual behavior and recovery after restoring. |
| Focus/Summary/alert settings | Repeat with altered presentation settings | Distinguish real callback and successful submission from visible alert timing. |
| Radius comparison | Separate 25, 50, 100, 200, and 500 m trials where supported | Record requested radius versus observed departure distance and false/missed alerts; no assumed precision. |
| Environment variation | Indoor start/outdoor route; open area; relevant daily route | Record conditions and usefulness separately for each environment. |
| Power/network variation | Repeat with Low Power Mode and degraded connectivity | Record delay or non-delivery; avoid extrapolating a normal-condition pass. |

The matrix contains both the initial feasibility gate and follow-up edge cases. Prioritize clean install, foreground, locked background, repeated departure, and stopped monitoring first. A release claim requires broader results across supported iOS/device combinations.

## Evidence record and decision

Use one record per attempt:

```text
Date / tester / build revision:
iPhone model / iOS / Xcode and SDK:
Case / real movement or simulation:
Requested radius / environment (omit private coordinates):
Location authorization / precision / Background App Refresh:
Notification settings / Focus / power / connectivity:
Registration confirmed / initial state / time:
Approximate physical crossing time:
Exit callback time / notification submission time and error:
Observed alert time / approximate distance from origin:
Duplicates / missed alert / observation period:
Was turning back still practical? Why?
Evidence reference (log or redacted recording):
Result / follow-up:
```

The first physical-device demonstration is complete only when the locked-background row has a genuine exit and observed notification. Before expanding the polished UI, collect several independent departures on the intended everyday route and review whether they arrived usefully early. Preserve failures in the denominator. Agree a measurable product target from that evidence; do not invent a reliability percentage from a handful of successes.

Pending evidence: Xcode build, signing/install, every physical-device row, measured latency/distance, battery behavior, supported-OS behavior, and user judgment of whether the reminder arrives soon enough. Until these exist, the correct status is **prototype prepared; core behavior unproven**.
