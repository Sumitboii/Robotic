# Antigravity Autonomous Development Prompt
## Synthera Robotics Prosthetic Hand Simulator

You are the autonomous senior engineer responsible for taking the Synthera Robotics mobile-app assignment from specification to a working, polished implementation.

The complete implementation specification is in:

```text
SYNTHERA_PROJECT_DESCRIPTION.md
```

Treat that file as the primary project specification and source of truth.

Your task is to **initiate and execute the development phase immediately**. Work autonomously, move quickly, validate continuously, and finish with a runnable application rather than merely producing a plan.

---

# 1. Operating Mode

Use a fast, implementation-first development loop:

```text
Inspect → Plan minimally → Implement → Run → Test → Fix → Polish → Re-run
```

Do not spend the majority of the execution producing planning prose.

Do not wait for human approval between ordinary engineering decisions.

Do not ask questions for details that can be reasonably derived from `SYNTHERA_PROJECT_DESCRIPTION.md`.

If an implementation choice is not explicitly fixed by the specification, choose the simplest production-quality option that preserves the architecture and assignment intent.

Do not stop after scaffolding.

Do not stop after the first successful build.

Do not declare success based only on static code inspection.

The final state must be a **working, testable Flutter application**.

---

# 2. First Actions

Before changing source code:

1. Inspect the entire repository/workspace.
2. Determine whether a Flutter project already exists.
3. Inspect existing `README`, configuration, source, tests, assets, and platform folders.
4. Detect installed Flutter/Dart versions.
5. Check available Android tooling/emulators if possible.
6. Read `SYNTHERA_PROJECT_DESCRIPTION.md` completely.
7. Identify the smallest set of dependencies required.
8. Preserve useful existing work when it is compatible with the specification.
9. Do not blindly overwrite an existing project.

If the repository is empty or unsuitable, initialize a clean Flutter project.

---

# 3. Technology Direction

Use:

- Flutter
- Dart
- Material 3

Preferred architecture:

```text
Presentation
    ↓
Application / State
    ↓
Domain
    ↓
Device Service abstraction
    ↓
Mock Device Service
    ↓
Simulated ESP32
    ↓
Simulated Prosthetic Hand
```

Preferred supporting packages, only when useful:

- Riverpod
- go_router
- fl_chart
- shared_preferences

Do not add packages unnecessarily.

If an existing dependency is unstable, obsolete, or incompatible with the installed Flutter version, replace it with a simpler maintained solution.

---

# 4. Architecture Requirements

Create a clean separation between:

### Presentation

Screens, widgets, theme, navigation and UI-only behavior.

### Application

Controllers/notifiers coordinating user actions, simulation state, modes, calibration and settings.

### Domain

Pure models and business rules.

Examples:

- DeviceTelemetry
- DeviceCommand
- OperatingMode
- HandState
- ConnectionState
- CalibrationState
- DeviceStatus

### Infrastructure

Interfaces and implementations for device communication and persistence.

At minimum:

```text
DeviceService
MockDeviceService
SimulatedEsp32
SimulatedProstheticHand
LocalSettingsRepository
```

The UI must never directly manipulate `SimulatedEsp32` or the simulated hand.

The abstraction should make a future implementation conceptually interchangeable:

```text
MockDeviceService
        ↓
BleDeviceService
        ↓
ESP32 BLE/GATT
```

Do not implement real BLE unless it is trivial and does not distract from the assignment. The assignment requires the simulator.

---

# 5. Core Functional Implementation

Implement every mandatory feature in the project specification.

## Dashboard

Display:

- Device name
- Connection state
- Battery
- Hand position
- Operating mode
- EMG value
- Hand state

Provide:

- OPEN
- STOP
- CLOSE

Use clear hierarchy and responsive mobile layout.

---

# 6. Hand Simulation

Canonical default limits:

```text
Minimum/open = 0°
Maximum/closed = 63°
```

The limits must be configurable and calibration-aware.

Movement must be continuous rather than a single state jump.

OPEN:

```text
current → minimum
```

CLOSE:

```text
current → maximum
```

STOP:

```text
cancel movement immediately
```

When a target is reached:

```text
state = HOLDING
```

Implement smooth animation.

Do not fake the animation by only changing text.

Use a visually meaningful hand/prosthetic representation.

If custom vector geometry is practical, create it locally. Avoid network-dependent assets.

---

# 7. Real-Time Simulator

Implement a controlled simulation loop.

Telemetry should update continuously.

The simulator must produce:

- Position
- Battery
- EMG
- Mode
- Hand state
- Connection state

The simulator should be deterministic enough to test and realistic enough to demonstrate.

Avoid unconstrained random values.

---

# 8. EMG Simulation

Generate a continuous bounded signal with:

- baseline variation
- smooth/noisy changes
- occasional contraction peaks

Example conceptual sequence:

```text
50 → 83 → 124 → 180 → 142 → 96 → 61
```

Implement threshold crossing.

A contraction should trigger only once per crossing.

Use hysteresis or debounce logic so a sustained high EMG value does not produce dozens of commands.

In EMG mode:

```text
contraction #1 → CLOSE
contraction #2 → OPEN
contraction #3 → CLOSE
...
```

Use a sensible cooldown/re-arm mechanism.

Display a live EMG graph using `fl_chart` or an equivalent lightweight implementation.

---

# 9. Battery Simulation

Battery should decrease gradually while the simulated device operates.

Requirements:

- Never below 0%
- Configurable warning threshold
- Low-battery warning
- Visible battery state

Make normal battery drain suitable for a 2–5 minute demo.

Provide a controlled development/demo mechanism if needed to demonstrate low battery without waiting.

Do not make a hidden hack that bypasses normal simulator behavior.

At 0%, enter a safe state and prevent unsafe normal movement.

---

# 10. Operating Modes

Implement:

## Manual

OPEN/CLOSE/STOP directly control the simulated hand.

## EMG

EMG threshold crossings control movement.

## Auto

Run a deterministic sequence such as:

```text
OPEN
HOLD
CLOSE
HOLD
repeat
```

STOP must interrupt Auto immediately.

Mode changes must be state-safe.

Changing away from Auto should cancel Auto scheduling.

---

# 11. Settings

Implement a dedicated Settings screen.

Editable:

- Device name
- Minimum angle
- Maximum angle
- EMG threshold
- Battery warning threshold
- Operating mode

Persist settings locally.

Validate all values.

At minimum:

```text
minAngle < maxAngle
0 <= batteryThreshold <= 100
valid EMG threshold
non-empty device name
```

Handle invalid input visibly and safely.

Do not silently save invalid configuration.

---

# 12. Calibration

Implement:

```text
Step 1: OPEN position
Step 2: CLOSED position
Step 3: SAVE
Result: Calibration Complete
```

Calibration must:

- use the device service
- move the simulated hand
- capture the endpoint
- persist calibration
- update active limits
- prevent incomplete calibration from being saved

Do not build calibration as a fake static wizard disconnected from the simulator.

---

# 13. Connection Simulation

Explicitly model:

```text
connected
connecting
disconnected
reconnecting
connectionFailed
```

Implement:

- disconnect simulation
- reconnect action
- automatic reconnection simulation where appropriate
- visible connection status

Disconnected UI should provide:

```text
Device Disconnected
[ RECONNECT ]
```

No uncaught exceptions.

---

# 14. Error Handling

Handle:

- Device disconnected
- Connection/reconnection failure
- Invalid command
- Low battery
- Invalid sensor data
- Emergency STOP

Errors should be represented in application state.

Do not allow malformed simulated telemetry to crash the app.

Add appropriate logs where useful.

---

# 15. Emergency STOP

Treat STOP as the highest-priority control action within the simulation.

When triggered:

1. Stop hand movement immediately.
2. Cancel Auto movement.
3. Cancel active EMG action.
4. Update device state.
5. Reflect the stopped state in the UI.
6. Ensure no queued movement resumes unexpectedly.

Do not wait for animation completion.

---

# 16. UI/UX

Create a polished robotics/assistive-technology interface.

The dashboard should feel deliberate and professional.

Prioritize:

- information hierarchy
- readability
- touch ergonomics
- motion feedback
- connection visibility
- battery visibility
- mode visibility
- clear STOP control

Recommended dashboard information:

```text
Brand / Device
Connection

Hand visualization
Position
State

Battery
EMG

EMG graph

Operating mode

OPEN / STOP / CLOSE
```

Use Material 3.

Support light/dark theme if it can be done cleanly.

Use animations sparingly and intentionally.

Avoid excessive gradients, decorative clutter, meaningless cards, and generic template-dashboard aesthetics.

The result should look like an engineering control interface, not a finance app that accidentally learned what a hand is.

---

# 17. Navigation

Implement at least:

```text
Dashboard
Settings
Calibration
```

Use go_router or a simple Flutter navigation solution.

Keep navigation obvious.

---

# 18. Persistence

Persist:

- device name
- min angle
- max angle
- EMG threshold
- battery warning threshold
- operating mode
- calibration limits
- theme preference if implemented

Do not persist transient animation timers or unnecessary runtime state.

---

# 19. Testing

Write automated tests for core behavior.

At minimum:

### Unit

- OPEN behavior
- CLOSE behavior
- STOP behavior
- position clamping
- target detection
- battery decrement
- battery lower bound
- low-battery threshold
- EMG threshold crossing
- EMG debounce/re-arm
- calibration validation
- settings validation
- invalid command handling

### Widget/integration where practical

- dashboard telemetry rendering
- OPEN interaction
- CLOSE interaction
- STOP interaction
- settings persistence
- calibration completion
- reconnect flow

Run tests after implementation.

Fix failures rather than merely reporting them.

---

# 20. Build Verification

At the end of every major implementation phase:

1. Run formatter.
2. Run static analysis.
3. Run unit/widget tests.
4. Build the application.
5. Fix all errors and warnings that materially affect quality.
6. Re-run verification.

Use commands appropriate to the detected Flutter environment, for example:

```bash
flutter pub get
dart format .
flutter analyze
flutter test
flutter build apk
```

Do not assume every command is available. Inspect the environment first.

If Android tooling is available, launch the application on an emulator/device and perform a smoke test.

---

# 21. Visual QA

After the first functional build, inspect the application visually.

Check:

- no overflow
- no clipped text
- correct safe-area behavior
- usable touch targets
- readable telemetry
- graph rendering
- animation smoothness
- light/dark contrast
- error states
- disconnected state
- low-battery state
- calibration flow
- settings form

Fix visual problems rather than documenting them as "known limitations" when they are straightforward to solve.

---

# 22. README

Create/update a high-quality README containing:

- Project overview
- Features
- Screenshots/placeholders
- Tech stack
- Architecture
- Simulator architecture
- State management
- EMG simulation behavior
- Battery simulation
- Calibration
- Error handling
- Future BLE/ESP32 integration
- Installation
- Running
- Testing
- Demo flow
- Known limitations

Explain why the device-service abstraction exists.

Explicitly describe how a future BLE implementation would replace the simulator.

---

# 23. Repository Hygiene

Before completion:

- Remove dead code
- Remove unused imports
- Remove debug prints that should not ship
- Remove generated build artifacts from source control
- Ensure secrets are absent
- Ensure `.gitignore` is appropriate
- Keep dependencies minimal
- Keep naming consistent
- Keep files reasonably small
- Avoid giant widget files where decomposition improves clarity

Do not commit credentials, API keys, certificates, or machine-specific paths.

---

# 24. Priority Order

If time or environment constraints appear, implement in this order:

### P0 — Mandatory

1. Flutter project
2. Architecture
3. Dashboard
4. Simulator
5. OPEN/CLOSE/STOP
6. Hand visualization
7. Real-time EMG
8. Battery simulation
9. Manual mode
10. EMG mode
11. Auto mode
12. Settings
13. Calibration
14. Connection/error handling
15. Persistence
16. Tests
17. README

### P1 — High-value bonus

1. EMG graph
2. Smooth hand animation
3. Dark/light theme
4. Event/device logs
5. Automatic reconnection
6. Clean BLE abstraction

### P2 — Optional

- Multiple devices
- OTA interface
- Authentication
- API integration

Never sacrifice P0 quality to implement P2.

---

# 25. Development Strategy

Work in vertical slices.

Recommended sequence:

```text
1. Repository/environment inspection
2. Flutter foundation
3. Domain models
4. Device service abstraction
5. Simulator engine
6. Dashboard
7. Hand animation
8. EMG telemetry + graph
9. Battery
10. Manual mode
11. EMG mode
12. Auto mode
13. Settings + persistence
14. Calibration
15. Connection/error states
16. Theme/polish
17. Tests
18. README
19. Build verification
20. Final visual QA
```

After each slice, run the smallest relevant verification.

Do not build the entire application blindly and discover at the end that the simulator has the structural integrity of wet cardboard.

---

# 26. Autonomous Decision Rules

When encountering ambiguity:

- Prefer the assignment's explicit requirement.
- Prefer simple deterministic behavior.
- Prefer maintainable architecture.
- Prefer local/offline behavior.
- Prefer stable dependencies.
- Prefer mobile UX over desktop/web optimization.
- Prefer testability over cleverness.
- Prefer a clear abstraction over premature real BLE code.

Do not ask the user to choose between ordinary implementation details.

If a dependency is unavailable, implement the same capability using Flutter/Dart primitives when reasonable.

If an emulator is unavailable, still run static analysis, tests and build checks.

If a build failure is environmental rather than code-related, diagnose it and document the exact blocker without pretending the app was successfully verified.

---

# 27. Assignment Compliance Audit

Before declaring completion, compare the implementation against every requirement in:

```text
SYNTHERA_PROJECT_DESCRIPTION.md
```

Create an internal checklist covering:

- Dashboard
- Simulation
- Communication abstraction
- Real-time EMG
- Battery
- Manual
- EMG
- Auto
- Settings
- Calibration
- Errors
- Emergency STOP
- Architecture
- Persistence
- Testing
- README
- Demo readiness
- Bonus features

Every mandatory item must be implemented or have a clearly documented environment-specific blocker.

Do not silently omit requirements.

---

# 28. Final Verification Report

At the end of the development run, provide a concise machine-readable/human-readable summary containing:

```text
PROJECT STATUS
--------------
Build:
Tests:
Static Analysis:
Platform:
Main Features:
Bonus Features:
Known Issues:
Environment Blockers:
Files Added/Changed:
```

Also report the exact commands used for verification.

Do not claim a feature works unless it was actually verified.

Do not inflate completion percentages.

---

# 29. Final Objective

The objective is not to produce a code skeleton.

The objective is to leave the workspace with a **polished, runnable, testable Flutter application demonstrating a simulated Synthera Robotics prosthetic hand**, with:

- credible real-time behavior
- clean architecture
- professional UI
- future BLE readiness
- reliable state handling
- clear error handling
- documented engineering decisions

Start implementation immediately after inspecting the workspace and specification.
