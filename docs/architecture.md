# Architecture

Unforgeter begins with a native iOS feasibility experiment and an independently testable Rule core. The first physical gate is a locked iPhone receiving a local notification after a real departure. The complete scheduled-Rules interface follows that evidence.

## Current boundaries

| Component | Responsibility |
| --- | --- |
| [UnforgeterApp / AppDelegate](../Unforgeter/App/UnforgeterApp.swift) | Own and start services during application launch, including a location-event launch without a visible screen. |
| [GeofenceProofView](../Unforgeter/Views/GeofenceProofView.swift) | Permission status/actions, one current-location zone, map preview, monitoring state, and session diagnostics. |
| [GeofenceProofController](../Unforgeter/Services/GeofenceProofController.swift) | Reconcile the saved zone with Core Location, handle entry/state/exit callbacks, suppress duplicate submissions, and expose view state. |
| [NotificationService](../Unforgeter/Services/NotificationService.swift) | Request notification access, submit local alerts, present foreground alerts, and retain a notification tap until its UI handler is ready. |
| [ProofStore](../Unforgeter/Services/ProofStore.swift) | Persist the one proof zone and last successful real-notification submission using atomic JSON writes in Application Support. |
| [TriggeredChecklistView](../Unforgeter/Views/TriggeredChecklistView.swift) | Display the fixed example checklist with completion state scoped to its presentation. |
| [UnforgeterCore](../Packages/UnforgeterCore/README.md) | Rule/checklist models, pure exit evaluation, and versioned JSON persistence; no iOS service calls. |

The iOS proof uses `TestZone`, not a scheduled `Rule`. The core package is prepared separately and is not currently connected to the app target's departure path. This keeps permission and delivery investigation independent from the planned Rule editor.

## Departure path

At startup the controller loads its saved zone, installs delegates, refreshes permission state, and reconciles monitored regions. A single foreground location request places the zone; the app does not run continuous GPS updates. `UIBackgroundModes = location` is deliberately absent for this region-only implementation.

Registration confirmation and inside/outside state are distinct from an actual exit. State queries and entry callbacks update diagnostics without sending a departure alert. A matching exit checks permissions and the proof's five-minute cooldown, then submits a local notification. Only successful submission updates the persisted cooldown. A short background execution task is explicitly ended, including on expiration. Submission success is logged as queued, not as proof that an alert was seen.

Notification payloads identify the proof zone. Tapping a valid notification opens Laptop, Charger, and Keys. A tap referring to a removed zone is rejected. Debug simulation uses a distinct alert and does not alter the real cooldown. Release builds omit the developer control.

The latest 60 diagnostic events remain in memory for the current process only. They are not a persistent movement or notification history. Capture field evidence before terminating the app. The `CORE LOCATION` label identifies a callback source; simulated GPS can produce those callbacks, so only a recorded physical-device departure establishes real movement.

## Rule semantics

Rules use stable UUIDs, coordinates, a positive finite radius, selected weekdays, local start/end minutes, checklist items, enabled state, cooldown, and the last-trigger timestamp. Validation runs when constructing, decoding, evaluating, and saving rules.

- Start is inclusive and end is exclusive: 06:30–08:30 includes 06:30 and excludes 08:30.
- Equal start and end are invalid rather than implicitly meaning all day.
- An overnight interval belongs to its starting weekday. Monday 22:00–Tuesday 02:00 is a Monday schedule, including Tuesday at 01:00.
- Evaluation uses the injected calendar and its time zone; the planned app integration uses the device's current local calendar at callback time. Tests pass explicit calendars.
- Daylight-saving changes follow local wall-clock time. A skipped time has no corresponding event; a repeated hour can match twice. Cooldown uses elapsed seconds to suppress repeated submissions.
- Exact cooldown expiry permits triggering. A last-trigger timestamp in the future suppresses delivery until that timestamp plus cooldown.

`RuleEvaluator` returns a decision and reason without side effects. The future iOS adapter must call it for a matching exit, then update and persist `lastTriggeredAt` only after scheduling succeeds. Core Location does not supply an exact physical crossing time here; integration must describe callback-time schedule evaluation honestly.

## Persistence decision

The proof stores one Codable object in JSON. The core's separate `JSONRuleStore` uses a versioned envelope, validates duplicate identifiers, writes atomically, and refuses to overwrite unreadable, corrupt, or newer-schema data. Its operations require serialized access; it is not a concurrent database.

JSON keeps the first local data path inspectable and the core independent of Apple UI frameworks. SwiftData or Core Data remains an option when the integrated Rules interface justifies it. A future migration must preserve existing data explicitly. No account, backend, or cloud synchronization is part of MVP.

The proof file uses protection until first user authentication. Unusable saved data stops monitoring and is preserved until the user explicitly resets it. This is local persistence, not a backup or encryption guarantee for exported data.

## Platform decisions and limits

Swift/SwiftUI is retained for V1; there is no reason to introduce C/C++ or change platforms to solve the current Windows constraint. The application targets iOS 17 with Swift language mode 5, and the package declares Swift tools 5.9.

The spike uses `CLLocationManager`/`CLCircularRegion` callbacks. Current Apple documentation deprecates these region methods; before release, review the deployment target and the replacement condition-monitoring lifecycle. The choice here bounds the first experiment, not a claim of superior reliability.

Arming requires Always authorization, Precise Location, notification alerts, Background App Refresh, monitoring support, a recent usable fix, and a radius within the device limit. The system limit is 20 monitored regions per app. Future Rules at identical geometry should share registrations. The 200 m default is an experimental starting point; smaller radii, timing, relaunches, power conditions, and usefulness need physical evidence. See the source-linked [validation guide](geofencing-validation.md).

## Next integration

After the first physical proof, add a small Rule list/editor and connect the core store/evaluator to the iOS services. Reconcile monitoring after save, edit, enable/disable, delete, and launch. Route notifications to saved checklist content using stable identifiers. Keep date evaluation independent of Core Location and cover new failure paths with focused tests.

The [backlog](backlog.md) retains the original five milestones and 46 planning items. No broader architecture, server, analytics, or prediction layer is needed for this step.
