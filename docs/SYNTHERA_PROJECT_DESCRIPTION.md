# Synthera Robotics Prosthetic Hand Simulator
## Project Description & Development Specification

> **Source of truth:** Synthera Robotics Mobile App Development Assignment.  
> This document translates the assignment into an implementation-ready product and engineering specification for autonomous development.

---

## 1. Product Overview

Build a polished Flutter/Dart mobile application that acts as the control and monitoring interface for a **simulated ESP32-based prosthetic hand**.

No physical ESP32, BLE peripheral, prosthetic hand, or external hardware is required. The application must contain a deterministic, testable **simulated device layer** that behaves like a real device from the perspective of the UI.

The application should demonstrate:

- Professional mobile UI/UX
- Clean application architecture
- Reactive real-time state handling
- Simulated hardware communication
- Smooth hand movement
- EMG signal simulation
- Battery simulation
- Operating modes
- Calibration
- Settings persistence
- Connection/reconnection handling
- Error and emergency-stop handling
- A clear abstraction boundary where the simulator can later be replaced by real BLE/ESP32 communication

The assignment explicitly values functionality, clean architecture, thoughtful UI/UX, reliable state handling, and evidence that the developer understands how a mobile application could eventually communicate with an ESP32-based robotic prosthetic system.

---

## 2. Source Requirements

### Dashboard

The dashboard must display:

- Device name
- Connection status
- Battery percentage
- Hand position
- Current operating mode
- EMG signal/value
- Current hand state

The assignment's example device is:

- Device: `DAKSH-01`
- Status: `Connected`
- Battery: `82%`
- Position: `45°`
- State: `HOLDING`
- EMG: `127`
- Mode: `AUTO`

The dashboard must provide primary controls:

- `OPEN`
- `CLOSE`
- `STOP`

### Prosthetic Hand Simulation

Canonical mechanical range:

- Fully open: `0°`
- Fully closed: `63°`

Behavior:

- `OPEN` smoothly moves the current position toward `0°`
- `CLOSE` smoothly moves the current position toward `63°`
- `STOP` immediately stops movement
- Movement must have a clear visual representation

A polished implementation should use a custom or high-quality hand visualization rather than relying only on a numeric progress bar.

### Simulated Communication

Required conceptual flow:

```text
Mobile App
    ↓
Device / Communication Service
    ↓
Simulated ESP32
    ↓
Simulated Prosthetic Hand
```

Commands:

```text
OPEN
CLOSE
STOP
CALIBRATE
```

Example device telemetry:

```text
BATTERY:82
POSITION:45
EMG:127
MODE:AUTO
STATE:HOLDING
```

The communication boundary must be designed so the simulator can later be replaced by a real BLE/ESP32 implementation without rewriting the UI.

### Real-Time EMG

The application must continuously generate sensible EMG values and display them.

Example sequence from the assignment:

```text
50 → 83 → 124 → 180 → 142 → 96 → 61 ...
```

Implement the bonus real-time EMG graph.

The graph should visibly behave like a signal rather than simply jumping between unrelated random integers. Use a bounded waveform/noise model with occasional contraction peaks.

### Battery

Battery must decrease gradually while the simulated device is operating.

Implement:

- Configurable warning threshold
- Low-battery warning
- Battery percentage display
- Safe behavior at very low battery

Default warning threshold may be `20%` unless the user changes it.

The simulator should avoid draining the battery so quickly that the demo becomes unusable. Provide a deterministic simulation strategy suitable for a 2–5 minute demonstration.

### Operating Modes

Implement all three required modes:

#### Manual

User directly controls:

- OPEN
- CLOSE
- STOP

#### EMG

Simulate EMG-driven control.

A contraction above the configured EMG threshold can trigger a hand action. The assignment gives the example of one contraction triggering closing and a subsequent contraction triggering opening.

Implement sensible debouncing/cooldown so one contraction does not produce repeated commands every telemetry tick.

#### Auto

Simulate predefined hand movements.

The automatic sequence should visibly move through several states and should be stoppable with emergency STOP.

---

## 3. Settings

Provide a dedicated Settings screen.

Editable settings:

- Device name
- Minimum angle
- Maximum angle
- EMG threshold
- Battery warning threshold
- Operating mode

Settings must persist locally.

Validation is required:

- Minimum angle must be less than maximum angle
- Angles must be within a sensible range
- EMG threshold must be within the simulator's signal range
- Battery threshold must be between `0–100`
- Device name must not be blank

If the user changes calibrated limits, the application must handle the relationship between calibration and settings cleanly rather than silently creating invalid state.

---

## 4. Calibration

Implement a clear three-step workflow:

```text
Step 1 — Move hand to OPEN position
Step 2 — Move hand to CLOSED position
Step 3 — Save calibration
        ↓
Calibration Complete
```

The application must retain calibrated minimum and maximum positions.

Recommended UX:

1. Show calibration progress.
2. Allow the simulator to move to the required endpoint.
3. Confirm the measured/simulated endpoint.
4. Prevent saving incomplete calibration.
5. Persist the resulting limits.
6. Show the calibrated values in settings/device information.

Calibration must not bypass the communication abstraction.

---

## 5. Connection & Error States

Explicitly model device connectivity rather than using a single boolean scattered throughout widgets.

Required scenarios:

- Connected
- Disconnected
- Connecting
- Reconnecting
- Connection failure
- Invalid command
- Low battery
- Invalid/unavailable sensor data
- Emergency STOP

Disconnected state must provide:

```text
Device Disconnected
[ RECONNECT ]
```

Reconnection should be simulated and should update application state realistically.

Invalid commands and unavailable telemetry must be represented as controlled application states/errors, not uncaught exceptions.

---

## 6. Emergency STOP

STOP is a safety-critical interaction within the simulation.

When STOP is invoked:

- Current hand movement stops immediately
- Active automatic movement stops
- Active EMG movement is cancelled
- Device state becomes a safe stopped/idle state
- UI visibly confirms the stop
- The command is routed through the device service

Do not make STOP dependent on an animation finishing.

A clear emergency-stop treatment is encouraged while avoiding unnecessary alarmist UI.

---

## 7. Recommended Technical Stack

### Required/preferred framework

- Flutter
- Dart

### Suggested libraries

Use stable, lightweight libraries where they materially improve implementation:

- Riverpod for state management
- go_router for navigation
- fl_chart for the EMG graph
- shared_preferences for local settings persistence
- Flutter's built-in animation APIs for hand movement

Do not add dependencies merely to make the dependency list look impressive. Humanity has suffered enough from 47-package Flutter demos.

### Platform target

Prioritize a polished Android/mobile experience and ensure the project can run in an emulator or physical smartphone.

A web build may be useful as an accessible demo if the chosen Flutter implementation supports it cleanly, but web support must not compromise the mobile architecture.

---

## 8. Architecture

Use a layered architecture that preserves the future BLE boundary.

Recommended structure:

```text
Presentation
├── Screens
├── Widgets
├── Theme
└── Navigation

Application / State
├── Device Controller
├── Mode Controller
├── Calibration Controller
└── Settings Controller

Domain
├── DeviceState
├── DeviceTelemetry
├── DeviceCommand
├── OperatingMode
├── HandState
├── ConnectionState
├── CalibrationState
└── Domain validation

Data / Infrastructure
├── DeviceService interface
├── MockDeviceService
├── SimulatedEsp32
├── SimulatedProstheticHand
└── LocalSettingsRepository
```

The UI must depend on abstractions rather than directly instantiating the simulator.

Conceptually:

```text
UI
 ↓
State / Controllers
 ↓
DeviceService abstraction
 ↓
MockDeviceService
 ↓
Simulated ESP32
 ↓
Simulated Hand
```

Future architecture:

```text
UI
 ↓
State / Controllers
 ↓
DeviceService abstraction
 ↓
BleDeviceService
 ↓
ESP32 BLE GATT
 ↓
Physical Prosthetic Hand
```

The assignment's recommended architecture specifically separates the UI/state-management layer from the device service and allows a Mock Device Simulator to later be replaced by a BLE Device implementation.

---

## 9. Domain Model

Use explicit domain models instead of passing loose maps throughout the application.

Suggested concepts:

### DeviceTelemetry

```text
batteryPercentage
positionDegrees
emgValue
operatingMode
handState
timestamp
```

### DeviceStatus

```text
connectionState
telemetry
isMoving
lastError
```

### DeviceCommand

```text
open
close
stop
calibrate
```

### OperatingMode

```text
manual
emg
auto
```

### HandState

Suggested values:

```text
open
opening
holding
closing
closed
stopped
calibrating
```

Additional internal states are acceptable if they make behavior clearer.

---

## 10. Simulator Behavior

The simulator should behave like a small deterministic embedded system rather than a random-number generator wearing a tiny hat.

### Position

Use a periodic update loop/timer.

For example:

```text
position += direction * movementSpeed * deltaTime
```

Clamp to configured minimum and maximum.

### OPEN

```text
target = minimumAngle
direction = opening
```

### CLOSE

```text
target = maximumAngle
direction = closing
```

### STOP

```text
movement = none
state = stopped
```

### HOLDING

When target is reached:

```text
movement = none
state = holding
```

### EMG

Generate a continuous baseline signal plus bounded variation and occasional contraction peaks.

When the signal crosses the configured threshold:

- detect a contraction edge
- debounce it
- issue one logical action
- wait for signal to fall below threshold before another contraction can trigger

### AUTO

Use a small deterministic sequence such as:

```text
OPEN
HOLD
CLOSE
HOLD
OPEN
...
```

Allow STOP to interrupt it immediately.

### Battery

Decrease gradually while the simulated device is active.

Battery must never become negative.

At or below the configured warning threshold:

- show warning
- expose low-battery state

At `0%`, prevent normal operation or transition to a safe state.

---

## 11. UI/UX Direction

The application should feel like a modern robotics/assistive-technology control console, not a school assignment with buttons placed in a column.

### Visual priorities

- Clean
- Professional
- High readability
- Strong information hierarchy
- Accessible touch targets
- Clear connection state
- Clear hand position
- Clear operating mode
- Strong STOP affordance
- Smooth transitions
- Useful empty/error/loading states

### Dashboard composition

Recommended structure:

```text
┌─────────────────────────────────────┐
│ SYNTHERA              ● CONNECTED   │
│ DAKSH-01                            │
├─────────────────────────────────────┤
│                                     │
│          [ HAND VISUAL ]            │
│                                     │
│              45°                    │
│          HOLDING                    │
│                                     │
├──────────────┬──────────────────────┤
│ Battery 82%  │ EMG 127              │
├──────────────┴──────────────────────┤
│           EMG SIGNAL GRAPH           │
├─────────────────────────────────────┤
│ MANUAL / EMG / AUTO                 │
├───────────┬───────────┬─────────────┤
│   OPEN    │   STOP    │    CLOSE    │
└───────────┴───────────┴─────────────┘
```

This is a conceptual layout, not a requirement to reproduce it literally.

### Hand visualization

Prefer a stylized prosthetic/robotic hand illustration built with Flutter primitives, vector assets, or a local asset.

The visual should:

- clearly communicate open/closed position
- animate with position changes
- indicate active movement
- show stopped/holding states
- avoid requiring external network assets

---

## 12. Navigation

Provide clear navigation to at least:

- Dashboard
- Settings
- Calibration

A bottom navigation or similarly obvious mobile navigation pattern is acceptable.

Avoid unnecessary screens. The assignment is evaluated on implementation quality, not the number of routes humans can tap through before finding the hand.

---

## 13. Persistence

Persist:

- Device name
- Minimum angle
- Maximum angle
- EMG threshold
- Battery warning threshold
- Operating mode
- Calibration values
- Relevant user preferences such as theme if implemented

Do not persist transient simulator state unless there is a concrete UX reason.

On app restart, initialize the simulated device using the saved configuration.

---

## 14. Testing

The implementation should include meaningful automated tests.

At minimum, cover:

### Unit tests

- Position clamping
- OPEN command
- CLOSE command
- STOP behavior
- Battery never below zero
- Battery warning threshold
- EMG threshold detection
- EMG contraction debounce
- Calibration validation
- Settings validation
- Invalid command handling

### Widget/integration-level tests

Cover key flows where practical:

- Dashboard renders device telemetry
- OPEN changes simulated state
- CLOSE changes simulated state
- STOP interrupts movement
- Settings save/load
- Calibration completion
- Disconnection/reconnection

Tests should focus on behavior rather than implementation details.

---

## 15. Accessibility & Robustness

Include:

- Semantic labels for controls
- Sufficient touch target sizes
- Text that remains readable in light/dark themes
- Color plus text/icon indicators for critical states
- No reliance on color alone for connection or battery state
- Safe handling of rapid repeated commands
- Safe handling of screen navigation while simulation timers are active

Dispose/cancel timers, streams, animations, and controllers correctly.

---

## 16. README Requirements

The final repository README must explain:

1. Project overview
2. Technologies used
3. Application architecture
4. How the simulated device works
5. How the application could connect to ESP32/BLE
6. Installation instructions
7. Run instructions
8. Screenshots
9. Known limitations

Also document:

- Why the selected state-management approach was used
- Why the device-service abstraction exists
- Simulator assumptions
- BLE replacement strategy
- Testing strategy

---

## 17. Demo Requirements

The final implementation should be easy to demonstrate in approximately 2–5 minutes.

A good demo sequence:

1. Launch app
2. Show connected device dashboard
3. Show live EMG graph
4. Press OPEN and demonstrate smooth movement
5. Press CLOSE and demonstrate smooth movement
6. Press STOP during movement
7. Switch to EMG mode
8. Demonstrate contraction-driven behavior
9. Switch to AUTO
10. Demonstrate automatic movement
11. Open Settings and change a value
12. Open Calibration
13. Simulate disconnect/reconnect
14. Show low-battery behavior if the simulator provides a demo control or accelerated demo mode

Avoid forcing the reviewer to wait several minutes for a battery to drop from 82% to 18%. A demo-friendly simulation control is acceptable as long as normal simulation behavior remains realistic.

---

## 18. Bonus Features

The assignment explicitly lists these as bonus opportunities:

- Real-time EMG graph
- Smooth hand animation
- Dark/light mode
- Local data storage
- Device logs
- Automatic reconnection simulation
- Multiple-device support
- OTA update interface
- User authentication
- Clean BLE abstraction
- API integration
- Excellent UI/UX

Prioritize quality of core functionality over implementing every bonus.

High-value bonus choices for this project:

1. Real-time EMG graph
2. Smooth hand animation
3. Dark/light mode
4. Device event log
5. Automatic reconnection simulation
6. Clean BLE abstraction

Avoid adding authentication, remote APIs, OTA functionality, or multi-device complexity unless they can be implemented without destabilizing the core assignment.

---

## 19. Evaluation Alignment

The assignment weights evaluation as follows:

| Category | Weight |
|---|---:|
| UI/UX & App Design | 20% |
| Application Functionality | 25% |
| Simulation & Real-Time Data | 15% |
| Code Architecture | 15% |
| Hardware/BLE Understanding | 10% |
| Error Handling | 5% |
| Documentation | 5% |
| Innovation / Bonus Features | 5% |
| **Total** | **100%** |

Development priorities should therefore emphasize:

- Core functionality
- UI/UX
- Simulation correctness
- Architecture
- BLE-ready abstraction
- Error handling
- Documentation

Do not trade core correctness for flashy features.

---

## 20. Definition of Done

The project is complete when:

- Flutter project builds successfully
- App launches without runtime errors
- Dashboard displays all required telemetry
- OPEN smoothly moves toward the configured minimum
- CLOSE smoothly moves toward the configured maximum
- STOP interrupts movement immediately
- Hand visualization responds to movement
- EMG continuously changes
- EMG graph works
- Battery decreases gradually
- Low-battery warning works
- Manual, EMG, and Auto modes work
- Settings can be edited and persist
- Calibration workflow works and persists limits
- Disconnect/reconnect states work
- Invalid commands/data are handled
- Emergency STOP works from active movement modes
- Simulator is behind a device-service abstraction
- README is complete
- Automated tests cover core simulator logic
- Project runs on a mobile emulator/device
- Repository is clean and free of generated secrets/build artifacts
- No external hardware is required

---

## 21. Engineering Principles

1. **Prefer simple deterministic behavior over fake complexity.**
2. **Keep device communication behind an interface.**
3. **Keep domain logic independent from Flutter widgets.**
4. **Keep simulation state centralized and observable.**
5. **Never let UI widgets own critical device logic.**
6. **Treat STOP as an immediate command.**
7. **Make the simulator realistic enough to demonstrate architecture.**
8. **Use local persistence only where it improves the application.**
9. **Test state transitions, not screenshots alone.**
10. **Keep the codebase understandable to another engineer.**
11. **Avoid unnecessary packages.**
12. **Document the future BLE integration boundary clearly.**

---

## 22. Scope Boundary

This is a **software simulation and engineering demonstration**, not a medical device.

The application does not need:

- Real prosthetic hardware
- Real EMG electrodes
- Medical signal processing
- Clinical validation
- Production BLE firmware
- Medical-device certification
- Cloud infrastructure

The purpose is to demonstrate how a mobile application could control and monitor a simulated ESP32-based robotic prosthetic system and how the architecture could evolve toward real hardware communication.
