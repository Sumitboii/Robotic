# Synthera Robotics UI/UX Audit & Clinical-Grade Gap Analysis

**Date:** September 2026  
**Scope:** Presentation Layer (`lib/presentation/`, `lib/core/theme/`, `docs/screenshots/`)  
**Target Standard:** Clinical medical device companion software (IEC 62366 / WCAG 2.1 AA compliant)

---

## Executive Summary
An audit of the initial Synthera application identified key presentation weaknesses across visual hierarchy, responsive ergonomics, clinical contrast compliance, and custom bionic kinematics rendering. The application currently presents as a generic enthusiast/cyberpunk prototype rather than an FDA/CE-ready clinical prosthetic companion.

---

## Key Deficiencies by Component & File

### 1. Visual Hierarchy & Theme Palette
- **File:** `lib/core/theme/app_theme.dart`
- **Issues:**
  - High-saturation neon cyan (`#00E5FF`) and cyberpunk crimson (`#FFFF1744`) produce visual fatigue rather than calm clinical authority.
  - Secondary/muted text colors (`#90A4AE` and `#78909C`) on dark (`#141923`) and light (`#E9ECEF`) surfaces achieve only ~3.6:1 contrast ratio, failing WCAG AA (4.5:1) for body/caption text.
  - No unified design token system; spacing, radius, typography, and border values are scattered as raw literals across widgets.
  - Telemetry digits jitter during real-time updates due to lack of tabular mono figures.

### 2. Wide-Screen & Viewport Imbalance
- **File:** `lib/presentation/screens/dashboard_screen.dart`
- **Issues:**
  - Unresponsive single-column layout stretches controls across the entire screen on tablets (768px) and desktop viewports (1280px), creating excessive horizontal whitespace and distorted aspect ratios.
  - Lacks a dual-pane layout at $\ge 900\text{ px}$ (hero visualizer/controls on left, telemetry/EMG graph on right).

### 3. Prosthetic Hand Visualizer Kinematics
- **File:** `lib/presentation/widgets/hand_visualizer.dart`
- **Issues:**
  - Thin single-stroke wireframe segments and simplistic circle joints resemble a basic 2D toy rather than an articulated medical-grade prosthetic device.
  - Lacks rounded anatomical phalanges, depth shading, motion easing curves, angle sweep arcs, and high-contrast state indicators that do not rely solely on color.

### 4. Actuator Controls & Emergency Ergonomics
- **File:** `lib/presentation/widgets/control_panel.dart`
- **Issues:**
  - `OPEN`, `STOP`, and `CLOSE` buttons compete in a cramped row. On small viewports (360×640), buttons compress under 48dp touch targets.
  - `EMERGENCY STOP` lacks distinct clinical safety dominance (minimum 56dp height, dedicated high-contrast emergency red styling, clear physical isolation).

### 5. Biosensor Telemetry & Graph Rendering
- **Files:** `lib/presentation/widgets/emg_graph.dart`, `lib/presentation/widgets/battery_indicator.dart`
- **Issues:**
  - Graph lacks `RepaintBoundary` isolation, forcing parent re-renders.
  - Threshold trigger lacks distinct visual highlight fill and callout badges.
  - Telemetry cards use divergent styling instead of unified `MetricTile` componentry.

### 6. Calibration Stepper & Settings Experience
- **Files:** `lib/presentation/screens/calibration_screen.dart`, `lib/presentation/screens/settings_screen.dart`
- **Issues:**
  - Calibration wizard uses a plain progress bar instead of a connected 3-stage clinical stepper with stage validation and summary review.
  - Settings screen lacks grouped clinical card sections, interactive limit sliders with live value previews, and a persistent sticky save bar.

---

## Action Plan
1. **Design Tokens (`AppColors`, `AppTypography`, `AppSpacing`, `AppRadius`)**: Clinical teal/cyan palette, slate dark mode, warm off-white light mode, WCAG AA $\ge 4.5:1$ compliance, local Inter & IBM Plex Mono fonts.
2. **Reusable Component System**: `AppCard`, `MetricTile`, `StatusChip`, `SectionHeader`, `PrimaryButton`, `DangerButton`, `SegmentedModeControl`.
3. **Responsive Architecture**: Multi-pane layout on wide screens ($\ge 900\text{ px}$), single column on mobile, zero overflow from 360px to 1280px with 1.3× text scale.
4. **Custom Painter Upgrade**: Bionic prosthetic visualizer with rounded phalanx geometry, smooth joint pivots, angle sweeps, and state semantics.
