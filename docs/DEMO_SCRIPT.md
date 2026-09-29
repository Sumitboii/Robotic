# Synthera Robotics Prosthetic Hand Simulator
## 3–5 Minute Evaluator Demonstration Script (Spec §17)

This timed demonstration script guides evaluators and presenters through the complete capabilities of the Synthera Prosthetic Hand Simulator mobile application.

---

### Timing Overview
| Phase | Duration | Focus Area |
|---|---|---|
| **Phase 1** | 0:00 – 0:45 | App Launch, Dashboard Telemetry & Kinematics (OPEN / CLOSE / STOP) |
| **Phase 2** | 0:45 – 1:30 | EMG Mode Bio-Signal Triggering & Oscillogram Visualization |
| **Phase 3** | 1:30 – 2:15 | Automated Operating Mode (AUTO Cycle) & Immediate E-STOP |
| **Phase 4** | 2:15 – 3:15 | Calibration Wizard (3-Step Capture) & Persistent Settings Sync |
| **Phase 5** | 3:15 – 4:00 | Fault Simulation: Low-Battery Warning & BLE Disconnect/Reconnect |

---

### Step-by-Step Demonstration Walkthrough

#### Step 1: Launch & Initial Dashboard Inspection (0:00 – 0:30)
* **Action:** Launch the application on the test target.
* **What to Say:**
  > *"Welcome to the Synthera Prosthetic Hand Simulator. Upon launch, the app initializes the deterministic 20 Hz ESP32 firmware simulation layer and displays live telemetry for device `DAKSH-01`. We observe the battery at 82%, mechanical position at 45.0°, operating mode in AUTO, and a continuous 20 Hz physiological EMG oscillogram."*
* **Verification Points:**
  - Connection status banner shows `Connected` (Green).
  - Multi-joint skeletal hand visualizer renders at 45.0°.
  - Real-time EMG chart displays continuous baseline waveform with threshold guide line at 120 µV.

---

#### Step 2: Manual Kinematic Actuation & Emergency STOP (0:30 – 1:00)
* **Action 1:** Switch Mode Selector tab to `MANUAL`.
* **Action 2:** Tap the blue `OPEN` button.
* **What to Say:**
  > *"Tapping OPEN actuates the motor at a calibrated rate of 45°/s toward the minimum mechanical limit of 0.0°. Hand state indicates OPENING, with smooth multi-finger tendon extension."*
* **Action 3:** While moving, tap the central red `STOP` button.
* **What to Say:**
  > *"Tapping STOP immediately halts motor PWM actuation with zero millisecond latency, locking the hand in the STOPPED state at its exact current angle."*
* **Action 4:** Tap the green `CLOSE` button.
* **What to Say:**
  > *"Tapping CLOSE smoothly flexes the fingers toward the 63.0° mechanical stop, reaching CLOSED state."*

---

#### Step 3: EMG Bio-Signal Contraction Control (1:00 – 1:45)
* **Action 1:** Switch Mode Selector tab to `EMG`.
* **Action 2:** Tap the ⚡ (Quick Demo Actions) icon in the top App Bar.
* **Action 3:** Select `Trigger EMG Spike (+170 µV)`.
* **What to Say:**
  > *"In EMG mode, the ESP32 firmware monitors myoelectric potential against a configurable threshold (120 µV) with hardware-emulated hysteresis. Triggering a muscle contraction causes an EMG spike to 195 µV. The leading edge triggers the hand to close. Triggering a subsequent spike triggers it to open."*
* **Verification Points:**
  - EMG graph shows a sharp peak exceeding the amber threshold line.
  - Hysteresis prevents re-triggering until the signal returns below the re-arm threshold (105 µV).

---

#### Step 4: AUTO Periodic Cycling & Interruption (1:45 – 2:30)
* **Action 1:** Switch Mode Selector tab to `AUTO`.
* **What to Say:**
  > *"In AUTO mode, the controller runs an autonomous periodic sequence: moving OPEN → holding for 1.6 seconds → moving CLOSE → holding for 1.6 seconds."*
* **Action 2:** During active automatic movement, tap the red `STOP` button.
* **What to Say:**
  > *"Pressing Emergency STOP immediately aborts the automated cycle, transitions the operating mode safely to MANUAL, and locks the motor in the STOPPED state."*

---

#### Step 5: Mechanical Limit Calibration Wizard (2:30 – 3:15)
* **Action 1:** Tap the `Calibration` tab in the bottom navigation bar.
* **Action 2:** Tap `Start Calibration`.
* **Action 3:** Tap `Capture OPEN Endpoint` (captures 0.0°).
* **Action 4:** Tap `Capture CLOSED Endpoint` (captures 63.0°).
* **Action 5:** Tap `Save & Apply Limits`.
* **What to Say:**
  > *"The 3-step calibration wizard guides the clinician or user through establishing mechanical end-stops. Premature saving is blocked until both valid endpoints are recorded. Once confirmed, the new limits are written to the ESP32 firmware and automatically persisted to local storage."*

---

#### Step 6: Hardware Settings & Local Persistence (3:15 – 3:45)
* **Action 1:** Tap the `Settings` tab in the bottom navigation bar.
* **Action 2:** Change `Device Name` to `SYNTH-DAKSH-PRO` and `EMG Threshold` to `135 µV`.
* **Action 3:** Tap `SAVE & APPLY`.
* **Action 4:** Return to Dashboard to see the new device name and updated EMG threshold line.
* **What to Say:**
  > *"Settings validates input bounds (preventing min >= max or out-of-range thresholds), syncs parameters to the active device, and persists them across app restarts via local key-value storage."*

---

#### Step 7: Fault Simulation — Low Battery & BLE Drop (3:45 – 4:30)
* **Action 1:** Open ⚡ Quick Demo Panel and tap `Set Battery to 15% (Low Warning)`.
* **What to Say:**
  > *"When the battery drops below the 20% warning threshold, a prominent low-battery warning badge appears and log entries record power state transitions. Depleted battery (0%) safely halts all actuation."*
* **Action 2:** Open ⚡ Quick Demo Panel and tap `Simulate Connection Drop`.
* **What to Say:**
  > *"Simulating a BLE link loss immediately halts motor motion and displays a disconnected banner with a dedicated RECONNECT action."*
* **Action 3:** Tap `RECONNECT` on the top banner.
* **What to Say:**
  > *"The app executes an automated BLE reconnection handshake, transitioning through Reconnecting to Connected with full state synchronization."*

---

### Summary & Architecture Wrap-Up
* **What to Say in Conclusion:**
  > *"The Synthera Prosthetic Hand Simulator demonstrates clean Clean-Architecture layering with 100% decoupling between UI and hardware. Swapping the simulated ESP32 for physical BLE hardware requires changing only a single provider in `device_providers.dart` using the `BleDeviceService` blueprint and canonical `KEY:VALUE` wire protocol."*
