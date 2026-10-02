# Unforgeter backlog

This is the local planning source for **46 planned items**. IDs such as `M0-01` are stable local identifiers; the trailing number preserves the original planning sequence. They are **not GitHub issue numbers**. No remote issue, label, milestone, or project board is represented as created by these files.

The structured counterpart, [backlog.json](backlog.json), includes import-ready titles, bodies, labels, milestone keys, and dependency IDs. Future publishing must resolve GitHub milestone IDs and labels; the local IDs should be retained in issue bodies so references can be mapped after creation.

## First practical gate: physical geofence proof

Keep the established M0–M4 numbering, but execute a minimal proof before building the full Rules UI:

1. Complete the native setup needed from M0-01.
2. Implement the minimum permission and notification path from M2-16 and M2-20.
3. Register one fixed test region using a slice of M2-17 and handle exit using M2-18.
4. Deploy to a **physical iPhone**, begin inside the region, leave it, and observe **“You left the zone.”** using a slice of M2-21.
5. Record radius, location conditions, permission state, device/iOS version, app state, exit time, notification time, misses, and duplicates. Repeat to establish whether the result is useful before polishing the UI.

The proof is currently **unverified**. The developer has **Windows only**. Source editing, documentation, and platform-independent logic can progress on Windows; native iOS building, signing, deployment, and physical testing require an Apple/Xcode environment. A simulator, simulated exit, generated Xcode project, or passing rule-engine test does not satisfy this gate. It is an early slice of the existing backlog, not an additional item or replacement milestone.

## Milestones

| Milestone | Objective | Planned items |
| --- | --- | --- |
| M0 — Project Setup | Repository, architecture and technical foundation. | M0-01–M0-03 |
| M1 — Rules MVP | Create and manage reminder Rules. | M1-04–M1-15 |
| M2 — Geofencing MVP | Make Rules actually trigger from real-world geofence exits. | M2-16–M2-24 |
| M3 — Product Polish | Turn the working prototype into a portfolio/beta-quality application. | M3-25–M3-38 |
| M4 — Beta Release | TestFlight distribution and real-user testing. | M4-39–M4-46 |

## Labels and workflow

Recommended category labels: `feature`, `bug`, `setup`, `architecture`, `UI/UX`, `location`, `geofencing`, `notifications`, `data`, `testing`, `documentation`, `privacy`, `MVP`, `future`.

Priorities: `P0-critical`, `P1-high`, `P2-medium`, `P3-low`. Priority assignments below are proposed planning choices; `P0-critical` marks a feasibility or release gate and does not change the milestone order.

Board: **BACKLOG → READY → IN PROGRESS → REVIEW / TEST → DONE**. All items are planned; unchecked boxes are not completion claims.

The user supplied acceptance criteria for items 1–24. Their meaning is preserved below; additional implementation notes are recommendations. The source supplied only titles for items 25–46, so their concise acceptance criteria are proposed and may be refined.

## Dependency and sprint plan

The source's full-product dependency chain is retained: M0-01 → M0-03 → M1-05 → M1-11 → M2-16 → M2-17 → M2-18 → M2-19 → M2-21 → M2-22. This describes the integrated product; the minimal physical proof above deliberately happens first. Per-item dependencies describe final completion, so prototype slices can precede their full integration dependencies.

After the proof, **Sprint 1 — Rules MVP** is done when a user can create Morning Class at Home, 50 m, Mon–Fri, 06:30–08:30, with Laptop, Charger, and Student ID; save, close, and reopen the app; and still view, edit, enable/disable, and delete it.

**Sprint 2 — Geofencing MVP** is done when physically leaving Home during an active weekday window produces the correct Morning Class notification, and tapping it opens Laptop, Charger, Student ID, and Water. Device behavior and observed delivery delay must be documented instead of assuming a precise boundary or instant delivery.

## M0 — Project Setup

Repository, architecture and technical foundation.

### M0-01 — Initialize iOS application

**Status:** Planned · **Priority:** P0-critical · **Labels:** `setup`, `MVP`

Create the native SwiftUI iOS application and repository foundation.

Acceptance criteria:

- [ ] An Xcode project is created.
- [ ] The SwiftUI application launches.
- [ ] The Git repository is configured.
- [ ] A .gitignore is configured.
- [ ] The basic folder structure exists.
- [ ] The iOS application builds successfully.
- [ ] Initial code is pushed to GitHub.

Implementation notes:

- Current development computer is Windows only. Native iOS build, signing, and device deployment require an Apple/Xcode build environment; generating source on Windows does not satisfy build or launch criteria.
- Perform only the minimal setup needed for the physical geofence proof before investing in polished UI.
- Remote publishing is a separate action; this local backlog does not assert that code has been pushed.

### M0-02 — Define application architecture

**Status:** Planned · **Priority:** P1-high · **Labels:** `architecture`, `documentation`, `MVP`

Define a small, understandable native architecture without unnecessary abstraction.

Acceptance criteria:

- [ ] Models are defined.
- [ ] Views are defined.
- [ ] Services are defined.
- [ ] The persistence layer is defined.
- [ ] The location/geofencing service is defined.
- [ ] The notification service is defined.
- [ ] The architecture is documented.

Implementation notes:

- Keep architecture simple; do not over-engineer.
- Prefer Swift/SwiftUI and native platform services. No backend is required for MVP.

### M0-03 — Define Rule data model

**Status:** Planned · **Priority:** P1-high · **Labels:** `architecture`, `data`, `MVP`

Represent the departure schedule and its checklist as a persistable Rule.

Acceptance criteria:

- [ ] The model has a unique ID.
- [ ] The model has a name.
- [ ] The model has coordinates.
- [ ] The model has a radius.
- [ ] The model has active days.
- [ ] The model has start and end times.
- [ ] The model has checklist items.
- [ ] The model has enabled/disabled state.
- [ ] The model can be persisted.

Implementation notes:

- Optional future fields in the source include locationName, triggerType, notificationMessage, cooldown, lastTriggered, creationDate, and modificationDate. Add them only when the current behavior requires them.

Final completion dependencies: `M0-02`.

## M1 — Rules MVP

Create and manage reminder Rules.

### M1-04 — Build Rules home screen

**Status:** Planned · **Priority:** P1-high · **Labels:** `feature`, `UI/UX`, `MVP`

Give users a clear overview of saved Rules and a route to create one.

Acceptance criteria:

- [ ] Saved Rules are displayed.
- [ ] Each Rule shows its name.
- [ ] Each Rule shows a schedule summary.
- [ ] Each Rule shows its enabled state.
- [ ] An empty state is displayed when no Rules exist.
- [ ] A New Rule button is available.

Final completion dependencies: `M0-03`, `M1-11`.

### M1-05 — Build Create Rule flow

**Status:** Planned · **Priority:** P1-high · **Labels:** `feature`, `UI/UX`, `MVP`

Create a departure Rule through the agreed name, location, radius, schedule, and checklist workflow.

Acceptance criteria:

- [ ] The user can enter a Rule name.
- [ ] The user can select a location.
- [ ] The user can select a radius.
- [ ] The user can select active days.
- [ ] The user can set an active time window.
- [ ] The user can create a checklist.
- [ ] Input is validated.
- [ ] Save and cancel actions are available.

Implementation notes:

- The first trigger type is leaving a location. Arriving is a possible future capability.
- Build the complete flow after the physical geofence proof gate.

Final completion dependencies: `M0-03`, `M1-06`, `M1-07`, `M1-08`, `M1-09`, `M1-10`.

### M1-06 — Implement location selection

**Status:** Planned · **Priority:** P1-high · **Labels:** `feature`, `UI/UX`, `location`, `MVP`

Use MapKit to choose the origin location for a Rule.

Acceptance criteria:

- [ ] A MapKit map is displayed.
- [ ] The user can select a location.
- [ ] The selected point is displayed.
- [ ] The coordinates are stored.
- [ ] The selected location is associated with the Rule.

Final completion dependencies: `M0-03`.

### M1-07 — Implement geofence radius selector

**Status:** Planned · **Priority:** P1-high · **Labels:** `feature`, `UI/UX`, `geofencing`, `MVP`

Let users configure and understand the chosen radius.

Acceptance criteria:

- [ ] The user can select a radius.
- [ ] The radius is displayed numerically.
- [ ] A radius circle is displayed on the map.
- [ ] The circle updates dynamically.
- [ ] The radius is saved.

Implementation notes:

- The source suggests 25 m, 50 m, 100 m, and custom choices. These are proposed controls, not guarantees of iOS boundary precision or timely delivery.
- Use physical testing to inform supported choices and product wording.

Final completion dependencies: `M1-06`.

### M1-08 — Implement active-day selector

**Status:** Planned · **Priority:** P1-high · **Labels:** `feature`, `UI/UX`, `data`, `MVP`

Support recurring weekday schedules.

Acceptance criteria:

- [ ] Individual days are selectable.
- [ ] Multiple days are supported.
- [ ] At least one active day is required.
- [ ] The selected days are persisted.

Final completion dependencies: `M0-03`.

### M1-09 — Implement active-time window

**Status:** Planned · **Priority:** P1-high · **Labels:** `feature`, `UI/UX`, `data`, `MVP`

Configure the local time window used by Rule evaluation.

Acceptance criteria:

- [ ] The user can set a start time.
- [ ] The user can set an end time.
- [ ] The times are persisted.
- [ ] The schedule can determine whether the current time is active.

Implementation notes:

- Document and test time-boundary, overnight-window, time-zone, and daylight-saving behavior before claiming support; the source leaves those semantics open.

Final completion dependencies: `M0-03`.

### M1-10 — Implement checklist editor

**Status:** Planned · **Priority:** P1-high · **Labels:** `feature`, `UI/UX`, `data`, `MVP`

Create and maintain a personalized, ordered checklist.

Acceptance criteria:

- [ ] The user can add an item.
- [ ] The user can remove an item.
- [ ] The user can edit an item.
- [ ] The user can reorder items.
- [ ] Empty items are prevented.
- [ ] The checklist is persisted.

Final completion dependencies: `M0-03`.

### M1-11 — Implement local Rule persistence

**Status:** Planned · **Priority:** P1-high · **Labels:** `feature`, `data`, `MVP`

Keep Rules locally across launches without an external server.

Acceptance criteria:

- [ ] Rules survive an app restart.
- [ ] Rules can be retrieved.
- [ ] Rules can be updated.
- [ ] Rules can be deleted.
- [ ] No external server is used.

Implementation notes:

- SwiftData or Core Data remains an implementation choice as appropriate; keep storage behind a small interface.

Final completion dependencies: `M0-03`.

### M1-12 — Implement Rule details screen

**Status:** Planned · **Priority:** P1-high · **Labels:** `feature`, `UI/UX`, `MVP`

Display the Rule name, location, radius, days, time, and checklist together.

Acceptance criteria:

- [ ] The complete Rule is visible.
- [ ] An edit button is available.
- [ ] A delete option is available.
- [ ] An enable/disable control is available.

Final completion dependencies: `M1-04`, `M1-11`.

### M1-13 — Edit existing Rule

**Status:** Planned · **Priority:** P1-high · **Labels:** `feature`, `UI/UX`, `data`, `MVP`

Allow changes to all properties of a saved Rule.

Acceptance criteria:

- [ ] Existing values populate the editor.
- [ ] Every Rule property is editable.
- [ ] Saving updates the Rule.
- [ ] Canceling discards changes.

Implementation notes:

- Changes affecting monitoring must later be reconciled with the monitored regions.

Final completion dependencies: `M1-05`, `M1-11`.

### M1-14 — Enable/disable Rule

**Status:** Planned · **Priority:** P1-high · **Labels:** `feature`, `UI/UX`, `data`, `MVP`

Temporarily suspend a Rule without deleting it.

Acceptance criteria:

- [ ] The user can toggle the enabled state.
- [ ] The state persists.
- [ ] The disabled state is visually clear.
- [ ] Disabled Rules are excluded from trigger logic.

Final completion dependencies: `M1-11`, `M2-19`.

### M1-15 — Delete Rule

**Status:** Planned · **Priority:** P1-high · **Labels:** `feature`, `data`, `geofencing`, `MVP`

Remove a Rule and its monitoring after user confirmation.

Acceptance criteria:

- [ ] A delete option is available.
- [ ] Deletion asks for confirmation.
- [ ] The persisted Rule is removed.
- [ ] Its associated geofence is removed.

Final completion dependencies: `M1-11`, `M2-17`.

## M2 — Geofencing MVP

Make Rules actually trigger from real-world geofence exits.

### M2-16 — Implement location permission flow

**Status:** Planned · **Priority:** P0-critical · **Labels:** `feature`, `location`, `privacy`, `MVP`

Explain and request the location access needed for departure monitoring.

Acceptance criteria:

- [ ] The app requests appropriate location permission.
- [ ] The reason for the permission is explained.
- [ ] Approval is handled.
- [ ] Denial is handled.
- [ ] Restricted state is handled.
- [ ] The app explains how permission can be restored.

Implementation notes:

- Include the minimum permission path in the physical geofence proof.
- Current iOS authorization behavior and device settings must be verified on an actual iPhone.

Final completion dependencies: `M0-01`.

### M2-17 — Register geofence for enabled Rule

**Status:** Planned · **Priority:** P0-critical · **Labels:** `feature`, `location`, `geofencing`, `MVP`

Reconcile enabled Rule regions with iOS monitoring.

Acceptance criteria:

- [ ] Rule coordinates and radius are converted to a monitored region.
- [ ] Enabled Rules are registered.
- [ ] A unique Rule identifier is used.
- [ ] Duplicate registrations are avoided.
- [ ] Monitoring is removed when a Rule is disabled or deleted.

Implementation notes:

- For the first physical proof, a fixed test region can establish viability before the full persisted Rule integration.
- Handle monitoring availability, platform limits, registration failures, and changed Rule geometry explicitly.

Final completion dependencies: `M0-03`, `M2-16`.

### M2-18 — Detect geofence EXIT event

**Status:** Planned · **Priority:** P0-critical · **Labels:** `feature`, `location`, `geofencing`, `testing`, `MVP`

Prove the highest-risk behavior: a physical iPhone reports leaving a monitored region.

Acceptance criteria:

- [ ] A region exit is detected.
- [ ] The corresponding Rule is identified.
- [ ] Exit handling works while the app is backgrounded/not foregrounded as permitted by iOS.
- [ ] The event is logged for debugging.

Implementation notes:

- Critical technical issue and first practical product gate when paired with M2-21.
- The physical test starts inside the test zone, leaves it by walking or riding as a passenger, and observes the local notification.
- Record observed timing and app/device conditions. A simulator or debug button does not satisfy the physical proof.

Final completion dependencies: `M2-17`.

### M2-19 — Build Rule evaluation engine

**Status:** Planned · **Priority:** P1-high · **Labels:** `feature`, `architecture`, `testing`, `MVP`

Evaluate the enabled state, active day, and time window independently from iOS services.

Acceptance criteria:

- [ ] The engine checks whether the Rule is enabled.
- [ ] The engine checks the active day.
- [ ] The engine checks the active time.
- [ ] The engine returns trigger/no-trigger.
- [ ] The engine has unit tests.

Implementation notes:

- Required source examples: Monday 07:15 true; Monday 10:00 false; Saturday 07:15 false; disabled Rule false for Morning Class, Mon–Fri 06:30–08:30.
- Inject time/calendar inputs so tests do not depend on the current date or live device location.

Final completion dependencies: `M0-03`.

### M2-20 — Implement notification permissions

**Status:** Planned · **Priority:** P0-critical · **Labels:** `feature`, `notifications`, `privacy`, `MVP`

Request and explain local-notification authorization.

Acceptance criteria:

- [ ] The app requests notification authorization.
- [ ] Allowed state is handled.
- [ ] Denied state is handled.
- [ ] The necessity of notifications is explained.

Implementation notes:

- Include this in the first physical geofence proof.

Final completion dependencies: `M0-01`.

### M2-21 — Trigger Unforgeter notification

**Status:** Planned · **Priority:** P0-critical · **Labels:** `feature`, `notifications`, `geofencing`, `MVP`

Send the matching reminder after a valid departure and route the notification tap to its checklist.

Acceptance criteria:

- [ ] A notification is sent after a valid exit.
- [ ] The correct Rule is displayed.
- [ ] The notification works when the application is not foregrounded as supported.
- [ ] Tapping the notification opens the corresponding checklist.

Implementation notes:

- The initial proof uses the message “You left the zone.” The final Rule-aware implementation completes all criteria above.
- No claim of instant, exact-distance, or guaranteed notification delivery should be made from simulated results.

Final completion dependencies: `M2-18`, `M2-19`, `M2-20`, `M2-22`, `M2-23`.

### M2-22 — Build triggered checklist screen

**Status:** Planned · **Priority:** P1-high · **Labels:** `feature`, `UI/UX`, `notifications`, `MVP`

Show the checklist associated with the departure notification.

Acceptance criteria:

- [ ] The correct checklist is displayed.
- [ ] Checklist items are checkable.
- [ ] An “I've got everything” button is available.
- [ ] Appropriate checklist reset behavior is defined and implemented.

Implementation notes:

- Document whether completion applies to the current reminder session; avoid silently deleting the saved checklist.

Final completion dependencies: `M1-11`.

### M2-23 — Prevent duplicate notifications

**Status:** Planned · **Priority:** P1-high · **Labels:** `feature`, `geofencing`, `notifications`, `testing`, `MVP`

Suppress repeated boundary events while allowing later legitimate departures.

Acceptance criteria:

- [ ] A cooldown policy is defined.
- [ ] The last trigger is recorded.
- [ ] Duplicate exits during the cooldown are ignored.
- [ ] Future legitimate departures are permitted.

Implementation notes:

- The source identifies GPS/geofence uncertainty near the boundary as the reason for protection.
- Define clock-change, restart, and independent-Rule behavior and cover the chosen policy with meaningful tests.

Final completion dependencies: `M0-03`, `M2-19`.

### M2-24 — Add developer geofence testing tools

**Status:** Planned · **Priority:** P1-high · **Labels:** `setup`, `testing`, `geofencing`, `notifications`, `MVP`

Make exit, evaluation, and notification paths inspectable during development.

Acceptance criteria:

- [ ] A simulated exit is available.
- [ ] Rule evaluation can be tested.
- [ ] A test notification can be sent.
- [ ] Debug functionality is excluded or disabled in production.

Implementation notes:

- Use debug controls to isolate components; they supplement physical geofence testing.

Final completion dependencies: `M2-19`, `M2-20`.

## M3 — Product Polish

Turn the working prototype into a portfolio/beta-quality application.

### M3-25 — Design Unforgeter app icon

**Status:** Planned · **Priority:** P2-medium · **Labels:** `UI/UX`

Create a recognizable app icon suited to the Unforgeter name and purpose.

Acceptance criteria (proposed):

- [ ] An original icon design is selected.
- [ ] Required app icon assets are added and checked at small sizes.

### M3-26 — Create onboarding experience

**Status:** Planned · **Priority:** P2-medium · **Labels:** `feature`, `UI/UX`, `privacy`

Introduce departure Rules and explain required permissions.

Acceptance criteria (proposed):

- [ ] Onboarding explains location, schedule, checklist, and the departure trigger.
- [ ] Permission rationale matches actual behavior and the flow can be completed without trapping denied users.

### M3-27 — Improve empty states

**Status:** Planned · **Priority:** P2-medium · **Labels:** `UI/UX`

Help users recover from empty or unavailable states.

Acceptance criteria (proposed):

- [ ] The empty Rules list gives a clear create action.
- [ ] Missing permission or unavailable data states explain the next useful step.

### M3-28 — Add accessibility support

**Status:** Planned · **Priority:** P1-high · **Labels:** `UI/UX`, `testing`

Make core Rule and checklist tasks accessible.

Acceptance criteria (proposed):

- [ ] Core flows are checked with VoiceOver and Dynamic Type.
- [ ] Controls have meaningful labels, adequate contrast, and usable touch targets.

### M3-29 — Add dark mode

**Status:** Planned · **Priority:** P2-medium · **Labels:** `UI/UX`, `testing`

Make the interface readable in both appearance modes.

Acceptance criteria (proposed):

- [ ] Core screens support light and dark appearance.
- [ ] Text, map overlays, and controls remain legible in both modes.

### M3-30 — Add Rule duplication

**Status:** Planned · **Priority:** P2-medium · **Labels:** `feature`, `data`

Use an existing Rule as a starting point for another routine.

Acceptance criteria (proposed):

- [ ] Duplicating creates a distinct ID and editable copy.
- [ ] The original Rule remains unchanged and monitoring registration remains consistent.

### M3-31 — Add notification/history functionality

**Status:** Planned · **Priority:** P3-low · **Labels:** `feature`, `notifications`, `data`, `privacy`

Provide a small local history of reminder activity.

Acceptance criteria (proposed):

- [ ] The history scope and local retention policy are defined.
- [ ] Relevant reminder events can be viewed and cleared without adding remote analytics.

### M3-32 — Add human-readable location naming

**Status:** Planned · **Priority:** P2-medium · **Labels:** `feature`, `location`, `UI/UX`

Show names such as Home alongside the underlying location.

Acceptance criteria (proposed):

- [ ] A location name can be supplied and persisted.
- [ ] Names appear consistently without replacing the stored coordinates.

### M3-33 — Add preset Rule templates

**Status:** Planned · **Priority:** P3-low · **Labels:** `feature`, `UI/UX`

Offer editable starting points for common routines.

Acceptance criteria (proposed):

- [ ] Selected templates prefill useful example fields.
- [ ] Users can review all values before saving a Rule.

### M3-34 — Add automated UI tests

**Status:** Planned · **Priority:** P2-medium · **Labels:** `testing`

Cover the highest-value user flows with native UI automation.

Acceptance criteria (proposed):

- [ ] Tests cover creating, editing, and deleting a Rule.
- [ ] Tests exercise opening the checklist and run in an available Xcode environment.

### M3-35 — Expand unit-test suite

**Status:** Planned · **Priority:** P1-high · **Labels:** `testing`

Cover remaining meaningful edge cases in Rule logic and persistence.

Acceptance criteria (proposed):

- [ ] The suite covers schedule boundaries, chosen time-zone policy, and cooldown behavior.
- [ ] Persistence and state transitions have focused regression coverage.

### M3-36 — Add privacy information screen

**Status:** Planned · **Priority:** P1-high · **Labels:** `feature`, `privacy`, `documentation`

Explain why location and notification access is used and where data remains.

Acceptance criteria (proposed):

- [ ] The screen accurately explains permissions and local data handling.
- [ ] It explains relevant settings and data deletion without claiming unimplemented protections.

### M3-37 — Create README screenshots/demo GIF

**Status:** Planned · **Priority:** P2-medium · **Labels:** `documentation`

Show the implemented product in the portfolio README.

Acceptance criteria (proposed):

- [ ] Screenshots and a short demo reflect an actual running build.
- [ ] Media includes useful descriptions and contains no unintended personal location data.

### M3-38 — Document architecture and technical decisions

**Status:** Planned · **Priority:** P2-medium · **Labels:** `architecture`, `documentation`

Keep the architecture and rationale aligned with the shipped implementation.

Acceptance criteria (proposed):

- [ ] Documentation describes Rule evaluation, persistence, geofencing, and notifications.
- [ ] Major decisions and platform limitations are recorded with verification status.

## M4 — Beta Release

TestFlight distribution and real-user testing.

### M4-39 — Configure application signing

**Status:** Planned · **Priority:** P1-high · **Labels:** `setup`

Prepare the Apple signing configuration needed for beta distribution.

Acceptance criteria (proposed):

- [ ] The intended bundle identifier and development team are configured.
- [ ] A build can be signed in an authorized Apple/Xcode environment without committing credentials.

### M4-40 — Configure TestFlight build

**Status:** Planned · **Priority:** P1-high · **Labels:** `setup`, `testing`

Prepare and distribute a testable iOS beta through TestFlight.

Acceptance criteria (proposed):

- [ ] A signed archive is uploaded and processed successfully.
- [ ] An authorized tester can install the intended build through TestFlight.

Implementation notes:

- Requires the necessary Apple account, signing, and distribution access.

Final completion dependencies: `M4-39`.

### M4-41 — Recruit beta testers

**Status:** Planned · **Priority:** P2-medium · **Labels:** `testing`

Find a small group matching the initial student and professional audience.

Acceptance criteria (proposed):

- [ ] A target tester group and recruitment message are prepared.
- [ ] Invited testers receive installation and feedback instructions.

Implementation notes:

- External outreach is a future execution task, not performed by this local backlog.

### M4-42 — Create beta feedback process

**Status:** Planned · **Priority:** P1-high · **Labels:** `testing`, `documentation`

Make reports reproducible and useful without unnecessary personal data.

Acceptance criteria (proposed):

- [ ] A feedback route and minimal reporting fields are available.
- [ ] Reports capture build, iOS version, expected behavior, observed behavior, and relevant permission/app state.

### M4-43 — Conduct real-world geofence reliability testing

**Status:** Planned · **Priority:** P0-critical · **Labels:** `testing`, `geofencing`, `location`

Evaluate departure usefulness across actual iPhone usage conditions.

Acceptance criteria (proposed):

- [ ] A physical test matrix covers representative radii, schedules, permissions, and supported app states.
- [ ] Results record notification delay, missed events, duplicates, and device conditions.
- [ ] Findings inform supported behavior and release readiness.

Implementation notes:

- This broader beta study follows, and does not replace, the earlier minimal physical proof gate.

Final completion dependencies: `M4-40`, `M2-21`.

### M4-44 — Analyze beta feedback

**Status:** Planned · **Priority:** P1-high · **Labels:** `testing`, `documentation`

Turn reported experiences into reproducible findings and product decisions.

Acceptance criteria (proposed):

- [ ] Feedback is grouped by recurring usability and reliability themes.
- [ ] Actionable findings are linked to reproducible bug or improvement work.

Final completion dependencies: `M4-42`, `M4-43`.

### M4-45 — Prioritize V1 release bugs

**Status:** Planned · **Priority:** P1-high · **Labels:** `bug`, `testing`

Choose and resolve the issues that block a useful first release.

Acceptance criteria (proposed):

- [ ] Release-blocking issues are explicitly prioritized.
- [ ] Fixes receive targeted verification and remaining limitations are documented.

Final completion dependencies: `M4-44`.

### M4-46 — Prepare App Store listing

**Status:** Planned · **Priority:** P2-medium · **Labels:** `documentation`, `privacy`

Prepare accurate product, screenshot, and privacy materials for a possible public release.

Acceptance criteria (proposed):

- [ ] Draft listing copy and screenshots match the actual app.
- [ ] Required privacy and support information is prepared and checked against implemented behavior.
- [ ] Submission readiness is reviewed separately from drafting.

Implementation notes:

- Preparing a listing does not mean the app has been submitted, accepted, or published.

Final completion dependencies: `M4-45`.

## Future roadmap boundary

The supplied source lists **snooze reminder** and **multiple locations** under potential V1.1, then ends with the incomplete text **“- Rule”**. No completion of that fragment is assumed, and no additional roadmap items are invented here. The `future` label is available for later planning; these incomplete future notes do not add to the 46-item count.
