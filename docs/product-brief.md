# Unforgeter product brief

> **Remember before you’re too far to turn back.**

This document preserves the user's established project context below. It is the product source of truth, not a report that the proposed application or GitHub backlog already exists.

## Current development constraint

The developer currently has **Windows only** and uses an iPhone. Swift/SwiftUI remains the preferred iOS V1 direction; lack of a Mac does not change the product into a web or cross-platform application. Native building, signing, and physical-device validation still need access to an Apple/Xcode environment. Work prepared on Windows must be labeled according to what has actually been verified.

## Execution clarification

Later user preference (2026-10-02): keep issue labels sparse—one simple category by default, at most two. This supersedes the source's multi-label recommendations below. Milestones still organize the phases.

The milestone names and M0–M4 numbering remain as proposed. The first practical gate is the critical physical-iPhone test described in source section 14: register a test region, physically leave it, and observe a local “You left the zone.” notification. Complete that minimal feasibility slice before investing in the complete polished Rules UI. The source's later critical-path and sprint descriptions apply to the integrated MVP after that proof.

A configured 25 m or 50 m radius is a product input, not a guarantee of precise or immediate iOS detection. Real-world reliability and delay must be measured. Product positioning describes the intended value; it is not evidence that the app has met it.

The [local backlog](backlog.md) translates all 46 proposed items into stable planning IDs. References such as “ISSUE #1” and “#18” in the preserved source are **source planning numbers**; the separate [publication map](github-backlog-map.json) records their actual GitHub issue numbers after creation.

The supplied source ends partway through the V1.1 roadmap at **“- Rule”**. That fragment is preserved without guessing its continuation. Decisions left open by the source, such as overnight schedule semantics and persistence implementation, remain engineering choices to document and test.

## Established project context

The following is the supplied context, with section headings formatted for readability. Its proposed future actions remain proposals until implemented and verified.

I want you to act as my product-development and software-engineering partner for a side project called UNFORGETER.

Please treat everything below as the established project context. Do not make me re-explain decisions already documented here. Help me progressively design, build, test, document, and eventually publish the application.

### 1. PROJECT OVERVIEW

PROJECT NAME:
Unforgeter

TAGLINE:
“Remember before you’re too far to turn back.”

PROJECT TYPE:
Initially an iOS mobile application and personal portfolio project, with the possibility of eventually becoming a publicly released product.

CORE PROBLEM:
People frequently leave home, their dorm, work, or another location and only realize several minutes later that they forgot something important:

- Laptop
- Charger
- Student ID
- Wallet
- Keys
- Water bottle
- Gym equipment
- Work badge
- Travel documents
- Etc.

The problem is not necessarily that users don't know what they need.

The problem is that they remember TOO LATE.

Traditional time-based reminders can also fire too early. For example, a reminder might appear at 7:00 AM while the user is still getting ready. They dismiss it and then leave at 7:25 without their laptop.

Unforgeter is designed to trigger the reminder based on the actual departure event.

### 2. CORE PRODUCT CONCEPT

Unforgeter is a context-aware, location-based reminder application.

Users create automated “Rules.”

A Rule combines:

LOCATION
+
GEOFENCE/RADIUS
+
DAYS
+
TIME WINDOW
+
PERSONALIZED CHECKLIST

When the user physically exits the configured radius during the Rule's active schedule, Unforgeter sends the relevant reminder/checklist.

Conceptually:

IF:
    User exits configured geofence
AND:
    Rule is enabled
AND:
    Current day is an active day
AND:
    Current time is inside the Rule's active time window

THEN:
    Trigger the Rule's notification/checklist.

The important distinction is:

Traditional reminders know WHEN YOU PLANNED TO LEAVE.

Unforgeter knows WHEN YOU ACTUALLY LEAVE.

### 3. EXAMPLE USER RULE

RULE NAME:
Morning Class

LOCATION:
Home

RADIUS:
50 meters

TRIGGER:
Leaving location

ACTIVE DAYS:
Monday-Friday

ACTIVE TIME:
6:30 AM-8:30 AM

CHECKLIST:
- Laptop
- Charger
- Student ID
- Water bottle

ENABLED:
Yes

EXAMPLE:

It is Tuesday at 7:12 AM.

The user crosses the 50-meter boundary around Home.

Because:
- Morning Class is enabled
- Tuesday is an active day
- 7:12 AM falls between 6:30 and 8:30 AM

Unforgeter triggers:

“Morning Class
Before you go, double-check:

□ Laptop
□ Charger
□ Student ID
□ Water bottle

[I'VE GOT EVERYTHING]”

If the same user leaves Home at 2:00 PM, Morning Class does NOT trigger because the Rule is outside its active time.

### 4. MULTIPLE RULES

The same location can support multiple Rules.

Example:

HOME

Morning Class
Mon-Fri
6:30-8:30 AM
Laptop / Charger / ID / Water

Gym
Mon/Wed/Fri
4:30-7:00 PM
Shoes / Headphones / Water / Locker lock

Soccer Practice
Tue/Thu
5:00-7:00 PM
Cleats / Shin guards / Jersey / Water

Work
Sat/Sun
7:00-9:00 AM
Uniform / Keys / Wallet / Lunch

The day/time context determines which Rule applies when the user leaves the geofence.

### 5. TARGET CUSTOMER

Initial target customers:

Busy students and young professionals who follow recurring routines and need different essential items depending on where they are going.

The concept could eventually expand to:

- Travelers
- Parents
- Professionals
- Gym users
- Commuters
- People managing multiple daily routines

### 6. CUSTOMER NEED

Customers need a simple way to remember essential items at the moment they ACTUALLY leave a location rather than relying solely on memory or predetermined time reminders.

The product should reduce:

- Forgotten items
- Trips back home
- Lost time
- Stress
- Disruption to daily routines

### 7. MARKET CATEGORY

Current positioning:

“Context-aware location reminder app”

Alternative:

“Location-based reminder and personal organization app”

### 8. KEY BENEFITS

Unforgeter provides:

- The right checklist
- At the right location
- At the right time
- For the right routine

Benefits include:

- Fewer forgotten items
- Fewer return trips
- Less wasted time
- Reduced stress
- Automated reminders without needing to open the app
- Different reminders for different routines

### 9. COMPETITIVE POSITIONING

General competitive alternatives include:

- Apple Reminders
- Calendar alerts
- Alarm apps
- Google Tasks/Keep
- Checklist/to-do applications
- Existing location-based reminder functionality

IMPORTANT:

Do NOT claim Unforgeter invented location-based reminders.

Location reminders already exist.

The proposed differentiation is the combination of:

GEOFENCED DEPARTURE
+
RECURRING DAY/TIME RULE
+
ROUTINE CONTEXT
+
CUSTOM ITEM CHECKLIST

The key positioning statement is:

“Unforgeter doesn't remind you when you planned to leave. It reminds you when you actually leave.”

### 10. ORIGINAL ELEVATOR-PITCH FRAMEWORK

This originated as an entrepreneurship-class concept.

The framework was:

FOR (target customer),
WHO HAS (customer need),
Unforgeter IS A (market category)
THAT (key benefits).
UNLIKE (competition),
THE PRODUCT (unique differentiation).

Our developed positioning was approximately:

FOR busy students and young professionals who have different items they need for their daily routines,

WHO HAVE difficulty remembering everything they need before leaving home,

UNFORGETER IS A context-aware location reminder app

THAT automatically sends a customized checklist when the user leaves a predefined location, based on the day, time, and routine.

UNLIKE traditional alarms, calendars, and reminder apps that primarily notify users based on predetermined times,

UNFORGETER combines when you're leaving, where you're leaving from, and what you're leaving to do to deliver the relevant reminder at the moment it is needed.

### 11. RULE CREATION UX

The Rule creation workflow currently envisioned is:

### 1. NAME RULE
Example:
Morning Class

### 2. CHOOSE LOCATION
Example:
Home

### 3. SET RADIUS
Possible choices:
25 m
50 m
100 m
Custom

### 4. TRIGGER
Initially:
Leaving location

Potential future functionality:
Arriving at location

### 5. ACTIVE DAYS

Example:

M T W T F S S
● ● ● ● ● ○ ○

### 6. ACTIVE TIME WINDOW

Example:

FROM: 6:30 AM
TO: 8:30 AM

### 7. CHECKLIST

Example:

Laptop
Charger
Student ID
Water bottle

### 8. ENABLE RULE

### 12. MVP DEFINITION

The first version should remain SMALL.

MVP:

User creates Rule
→
chooses location
→
sets radius
→
chooses days/time
→
creates checklist
→
saves Rule
→
leaves radius during active period
→
receives Rule-specific notification
→
opens checklist.

DO NOT initially add:

- Accounts
- Social functionality
- AI
- Automatic destination prediction
- Cloud backend
- Complex analytics
- Smartwatch integration
- AirTag integration
- Sharing
- Cross-platform synchronization

These can be future enhancements.

### 13. CURRENT TECHNICAL DIRECTION

Current preferred implementation:

iOS FIRST.

Potential stack:

- Swift
- SwiftUI
- Core Location
- MapKit
- UserNotifications
- Local persistence (SwiftData/Core Data as appropriate)

No backend should be required for MVP.

The application should initially be local-first.

One reason for iOS-first development is that the developer uses an iPhone, making real-world geofence testing practical.

We discussed C/C++.

Decision:

Do NOT force C or C++ into the project unnecessarily.

Swift is the preferred implementation for V1 because Unforgeter depends heavily on native iOS functionality.

Potential future architecture could separate platform-independent Rule evaluation logic, possibly allowing a C++ core, but only if there is a legitimate engineering reason.

For V1:
Prefer Swift/SwiftUI.

### 14. CRITICAL TECHNICAL PROOF

Before building the entire polished UI, prove the highest-risk functionality:

Create a basic iOS prototype that:

### 1. Registers a test geofence.
### 2. Runs on a physical iPhone.
### 3. Detects leaving the geofence.
### 4. Triggers a local notification.

In other words:

PHONE INSIDE TEST ZONE
→
USER WALKS/DRIVES OUTSIDE ZONE
→
IPHONE DISPLAYS:
“You left the zone.”

Once that works reliably, build the complete Rule system around it.

### 15. RULE DATA MODEL

Initial conceptual model:

Rule
- id
- name
- latitude
- longitude
- radius
- activeDays
- startTime
- endTime
- checklistItems
- isEnabled

Possible future fields:

- locationName
- triggerType
- notificationMessage
- cooldown
- lastTriggered
- creationDate
- modificationDate

### 16. RULE ENGINE

Core business logic:

EXIT DETECTED
      ↓
Identify corresponding Rule
      ↓
Is Rule enabled?
      ↓ YES
Is today an active day?
      ↓ YES
Is current time inside active window?
      ↓ YES
Has duplicate/cooldown protection passed?
      ↓ YES
Trigger notification/checklist

The Rule evaluation logic should be independently unit-testable.

Examples:

Morning Class:
Mon-Fri
6:30-8:30 AM

Monday 7:15 AM → TRUE
Monday 10:00 AM → FALSE
Saturday 7:15 AM → FALSE
Rule disabled → FALSE

### 17. GITHUB

Repository already created:

https://github.com/peetsman/Unforgeter

The project should use GitHub professionally as part of the portfolio.

GitHub should eventually demonstrate:

- Source code
- Commit history
- Issues
- Milestones
- Acceptance criteria
- Tests
- Architecture decisions
- Documentation
- Screenshots
- Demo
- Product roadmap

Suggested board workflow:

BACKLOG
→
READY
→
IN PROGRESS
→
REVIEW / TEST
→
DONE

### 18. GITHUB LABELS

Recommended labels:

feature
bug
setup
architecture
UI/UX
location
geofencing
notifications
data
testing
documentation
privacy
MVP
future

Priorities:

P0-critical
P1-high
P2-medium
P3-low

### 19. MILESTONES

Create these milestones:

M0 — Project Setup
Objective:
Repository, architecture and technical foundation.

M1 — Rules MVP
Objective:
Create and manage reminder Rules.

M2 — Geofencing MVP
Objective:
Make Rules actually trigger from real-world geofence exits.

M3 — Product Polish
Objective:
Turn the working prototype into a portfolio/beta-quality application.

M4 — Beta Release
Objective:
TestFlight distribution and real-user testing.

### 20. M0 — PROJECT SETUP ISSUES

**ISSUE #1**
Initialize iOS application

Acceptance criteria:
- Xcode project created
- SwiftUI application launches
- Git repository configured
- .gitignore configured
- Basic folder structure
- Application builds successfully
- Initial code pushed to GitHub

**ISSUE #2**
Define application architecture

Acceptance criteria:
- Define Models
- Define Views
- Define Services
- Define persistence layer
- Define location/geofencing service
- Define notification service
- Document architecture

Keep architecture simple. Do not over-engineer.

**ISSUE #3**
Define Rule data model

Acceptance criteria:
- Unique ID
- Name
- Coordinates
- Radius
- Active days
- Start/end times
- Checklist items
- Enabled/disabled state
- Model can be persisted

### 21. M1 — RULES MVP ISSUES

**ISSUE #4**
Build Rules home screen

Acceptance criteria:
- Display saved Rules
- Show Rule name
- Show schedule summary
- Show enabled state
- Empty state
- New Rule button

**ISSUE #5**
Build Create Rule flow

Acceptance criteria:
- Rule name
- Location
- Radius
- Days
- Time
- Checklist
- Validation
- Save/cancel

**ISSUE #6**
Implement location selection

Acceptance criteria:
- Display MapKit map
- User selects location
- Point displayed
- Coordinates stored
- Location associated with Rule

**ISSUE #7**
Implement geofence radius selector

Acceptance criteria:
- Select radius
- Display radius numerically
- Display circle on map
- Circle updates dynamically
- Radius saved

**ISSUE #8**
Implement active-day selector

Acceptance criteria:
- Individual days selectable
- Multiple days supported
- At least one required
- Selection persisted

**ISSUE #9**
Implement active-time window

Acceptance criteria:
- Start time
- End time
- Times persisted
- Schedule can determine whether current time is active

**ISSUE #10**
Implement checklist editor

Acceptance criteria:
- Add item
- Remove item
- Edit item
- Reorder items
- Prevent empty items
- Persist checklist

**ISSUE #11**
Implement local Rule persistence

Acceptance criteria:
- Rules survive app restart
- Retrieve Rules
- Update Rules
- Delete Rules
- No external server

**ISSUE #12**
Implement Rule details screen

Display:
- Rule name
- Location
- Radius
- Days
- Time
- Checklist

Acceptance criteria:
- Complete Rule visible
- Edit button
- Delete option
- Enable/disable control

**ISSUE #13**
Edit existing Rule

Acceptance criteria:
- Existing values populate editor
- Every property editable
- Save updates Rule
- Cancel discards changes

**ISSUE #14**
Enable/disable Rule

Acceptance criteria:
- Toggle state
- State persists
- Disabled state visually clear
- Disabled Rules excluded from trigger logic

**ISSUE #15**
Delete Rule

Acceptance criteria:
- Delete option
- Confirmation
- Remove persisted Rule
- Remove associated geofence

### 22. M2 — GEOFENCING MVP ISSUES

**ISSUE #16**
Implement location permission flow

Acceptance criteria:
- Request appropriate permission
- Explain reason
- Handle approval
- Handle denial
- Handle restricted state
- Explain how to restore permission

**ISSUE #17**
Register geofence for enabled Rule

Acceptance criteria:
- Convert Rule coordinates/radius to monitored region
- Register enabled Rules
- Unique Rule identifier
- Avoid duplicates
- Remove monitoring when Rule disabled/deleted

**ISSUE #18**
Detect geofence EXIT event

CRITICAL TECHNICAL ISSUE.

Acceptance criteria:
- Detect region exit
- Identify Rule
- Work while app is backgrounded/not foregrounded as permitted by iOS
- Log event for debugging

**ISSUE #19**
Build Rule evaluation engine

Acceptance criteria:
- Check enabled
- Check active day
- Check active time
- Return trigger/no-trigger result
- Unit tests

**ISSUE #20**
Implement notification permissions

Acceptance criteria:
- Request authorization
- Handle allowed
- Handle denied
- Explain necessity

**ISSUE #21**
Trigger Unforgeter notification

Acceptance criteria:
- Notification after valid exit
- Correct Rule displayed
- Works when application isn't foregrounded as supported
- Tapping notification opens corresponding checklist

**ISSUE #22**
Build triggered checklist screen

Acceptance criteria:
- Correct checklist
- Items checkable
- “I've got everything” button
- Appropriate checklist reset behavior

**ISSUE #23**
Prevent duplicate notifications

Reason:
GPS/geofence uncertainty around a boundary could cause repeated events.

Acceptance criteria:
- Define cooldown
- Record last trigger
- Ignore duplicate exits during cooldown
- Permit future legitimate departure

**ISSUE #24**
Add developer geofence testing tools

Possible debug tools:
- Simulate Exit
- Evaluate Rule
- Send Test Notification

Acceptance criteria:
- Simulated exit
- Rule evaluator testing
- Test notification
- Debug functionality excluded/disabled in production

### 23. M3 — PRODUCT POLISH BACKLOG

#25 Design Unforgeter app icon
#26 Create onboarding experience
#27 Improve empty states
#28 Add accessibility support
#29 Add dark mode
#30 Add Rule duplication
#31 Add notification/history functionality
#32 Add human-readable location naming
#33 Add preset Rule templates
#34 Add automated UI tests
#35 Expand unit-test suite
#36 Add privacy information screen
#37 Create README screenshots/demo GIF
#38 Document architecture and technical decisions

### 24. M4 — BETA RELEASE BACKLOG

#39 Configure application signing
#40 Configure TestFlight build
#41 Recruit beta testers
#42 Create beta feedback process
#43 Conduct real-world geofence reliability testing
#44 Analyze beta feedback
#45 Prioritize V1 release bugs
#46 Prepare App Store listing

### 25. CRITICAL PATH

The most important dependency chain is:

#1 Setup
→
#3 Rule Model
→
#5 Create Rule
→
#11 Persistence
→
#16 Permissions
→
#17 Register Geofence
→
#18 Detect Exit
→
#19 Evaluate Rule
→
#21 Notification
→
#22 Checklist

Do not let lower-priority features distract from this path.

### 26. SPRINT PLAN

SPRINT 1:
Rules MVP

Goal:
User can create, save, view, edit, enable/disable and delete a Rule.

Definition of done example:

User can create:

Morning Class
Home
50 m
Mon-Fri
6:30-8:30 AM
Laptop
Charger
Student ID

Save it, close the app, reopen it and still see the Rule.

SPRINT 2:
Geofencing MVP

Goal:
Crossing the configured boundary during an active schedule triggers the correct checklist notification.

Definition of done:

At approximately 7:15 AM on an active weekday, physically leave the configured Home geofence.

Phone receives:

“Morning Class
Before you go, double-check your essentials.”

Tapping it displays:
Laptop
Charger
Student ID
Water

### 27. FUTURE ROADMAP

Potential V1.1:
- Snooze reminder
- Multiple locations
- Rule
