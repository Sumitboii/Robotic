import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/settings_provider.dart';
import '../../application/providers/theme_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/device_settings.dart';
import '../../domain/models/operating_mode.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/danger_button.dart';
import '../widgets/common/primary_button.dart';
import '../widgets/common/section_header.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _minAngleController;
  late TextEditingController _maxAngleController;
  late TextEditingController _emgThresholdController;
  late TextEditingController _batteryWarningController;

  OperatingMode _selectedMode = OperatingMode.auto;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _minAngleController = TextEditingController();
    _maxAngleController = TextEditingController();
    _emgThresholdController = TextEditingController();
    _batteryWarningController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _minAngleController.dispose();
    _maxAngleController.dispose();
    _emgThresholdController.dispose();
    _batteryWarningController.dispose();
    super.dispose();
  }

  void _populateForm(DeviceSettings settings) {
    if (_isInitialized) return;
    _nameController.text = settings.deviceName;
    _minAngleController.text = settings.minAngle.toStringAsFixed(1);
    _maxAngleController.text = settings.maxAngle.toStringAsFixed(1);
    _emgThresholdController.text = settings.emgThreshold.toStringAsFixed(0);
    _batteryWarningController.text =
        settings.batteryWarningThreshold.toStringAsFixed(0);
    _selectedMode = settings.defaultOperatingMode;
    _isInitialized = true;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final minAngle = double.tryParse(_minAngleController.text) ?? 0.0;
    final maxAngle = double.tryParse(_maxAngleController.text) ?? 63.0;
    final emgThreshold = double.tryParse(_emgThresholdController.text) ?? 120.0;
    final batteryWarning =
        double.tryParse(_batteryWarningController.text) ?? 20.0;

    final validationError = DeviceSettings.validate(
      deviceName: name,
      minAngle: minAngle,
      maxAngle: maxAngle,
      emgThreshold: emgThreshold,
      batteryWarningThreshold: batteryWarning,
    );

    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: AppColors.emergencyRed,
        ),
      );
      return;
    }

    final updatedSettings = DeviceSettings(
      deviceName: name,
      minAngle: minAngle,
      maxAngle: maxAngle,
      emgThreshold: emgThreshold,
      batteryWarningThreshold: batteryWarning,
      defaultOperatingMode: _selectedMode,
    );

    final success = await ref
        .read(settingsNotifierProvider.notifier)
        .saveSettings(updatedSettings);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Settings saved & synchronized to device successfully.'
              : 'Failed to save settings.'),
          backgroundColor: success
              ? (Theme.of(context).brightness == Brightness.dark
                  ? AppColors.successDark
                  : AppColors.successLight)
              : AppColors.emergencyRed,
        ),
      );
    }
  }

  Future<void> _handleReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset to Factory Defaults?'),
        content: const Text(
          'This will reset all hardware limits, thresholds, and device names to factory default values.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emergencyRed),
            child: const Text('RESET'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(settingsNotifierProvider.notifier).resetToDefaults();
      _isInitialized = false;
      final settings = ref.read(settingsNotifierProvider).value;
      if (settings != null) {
        _populateForm(settings);
        setState(() {});
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Factory defaults restored.'),
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? AppColors.primaryDark
                : AppColors.primaryLight,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsNotifierProvider);
    final currentThemeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SETTINGS'),
        actions: [
          IconButton(
            tooltip: 'Reset Defaults',
            icon: Icon(
              Icons.restart_alt,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            onPressed: _handleReset,
          ),
        ],
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading settings: $err')),
        data: (settings) {
          _populateForm(settings);

          return SafeArea(
            child: Form(
              key: _formKey,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: ListView(
                    padding: AppSpacing.edgeInsetsScreen,
                    children: [
                      // 1. Device Identity Card
                      AppCard(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionHeader(
                              title: 'DEVICE IDENTITY',
                              subtitle:
                                  'Firmware identification & BLE advertising broadcast name',
                              icon: Icons.devices,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Device Name / Model',
                                prefixIcon: Icon(
                                  Icons.badge_outlined,
                                  color: isDark
                                      ? AppColors.primaryDark
                                      : AppColors.primaryLight,
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Device name cannot be blank.';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // 2. Mechanical Motion Limits Card
                      AppCard(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionHeader(
                              title: 'MECHANICAL MOTION LIMITS',
                              subtitle:
                                  'Physical actuator stroke boundaries and calibration range',
                              icon: Icons.precision_manufacturing,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _minAngleController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    decoration: const InputDecoration(
                                      labelText: 'Min Angle (OPEN)',
                                      suffixText: '°',
                                      helperText: 'Physical open rest limit',
                                    ),
                                    validator: (val) {
                                      final num = double.tryParse(val ?? '');
                                      if (num == null) {
                                        return 'Enter valid angle';
                                      }
                                      if (num < AppConstants.absoluteMinAngle ||
                                          num > AppConstants.absoluteMaxAngle) {
                                        return '${AppConstants.absoluteMinAngle}°-${AppConstants.absoluteMaxAngle}°';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: TextFormField(
                                    controller: _maxAngleController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    decoration: const InputDecoration(
                                      labelText: 'Max Angle (CLOSED)',
                                      suffixText: '°',
                                      helperText: 'Full closed grip stroke',
                                    ),
                                    validator: (val) {
                                      final max = double.tryParse(val ?? '');
                                      final min = double.tryParse(
                                          _minAngleController.text);
                                      if (max == null) {
                                        return 'Enter valid angle';
                                      }
                                      if (max < AppConstants.absoluteMinAngle ||
                                          max > AppConstants.absoluteMaxAngle) {
                                        return '${AppConstants.absoluteMinAngle}°-${AppConstants.absoluteMaxAngle}°';
                                      }
                                      if (min != null && max <= min) {
                                        return 'Must be > Min';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // 3. Biosensor & Power Thresholds Card
                      AppCard(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionHeader(
                              title: 'BIOSENSOR & POWER THRESHOLDS',
                              subtitle:
                                  'EMG contraction sensitivity & critical battery cutoff',
                              icon: Icons.tune,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: _emgThresholdController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'EMG Contraction Trigger Threshold',
                                suffixText: 'μV',
                                helperText:
                                    'Recommended clinical range: 100 - 180 μV',
                                prefixIcon: Icon(
                                  Icons.sensors,
                                  color: isDark
                                      ? AppColors.primaryDark
                                      : AppColors.primaryLight,
                                ),
                              ),
                              validator: (val) {
                                final num = double.tryParse(val ?? '');
                                if (num == null) {
                                  return 'Enter numeric value';
                                }
                                if (num < AppConstants.minEmgThreshold ||
                                    num > AppConstants.maxEmgThreshold) {
                                  return 'Range: ${AppConstants.minEmgThreshold.toInt()} - ${AppConstants.maxEmgThreshold.toInt()}';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: _batteryWarningController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Battery Warning Threshold',
                                suffixText: '%',
                                helperText:
                                    'Alert triggered when power drops below this percentage',
                                prefixIcon: Icon(
                                  Icons.battery_alert,
                                  color: isDark
                                      ? AppColors.warningDark
                                      : AppColors.warningLight,
                                ),
                              ),
                              validator: (val) {
                                final num = double.tryParse(val ?? '');
                                if (num == null) {
                                  return 'Enter percentage';
                                }
                                if (num < 5 || num > 50) {
                                  return 'Must be between 5% - 50%';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // 4. Default Operating Mode Card
                      AppCard(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionHeader(
                              title: 'DEFAULT OPERATING MODE',
                              subtitle:
                                  'Firmware boot & reconnect initial control profile',
                              icon: Icons.settings_suggest,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            DropdownButtonFormField<OperatingMode>(
                              value: _selectedMode,
                              decoration: InputDecoration(
                                labelText: 'Startup Mode',
                                prefixIcon: Icon(
                                  Icons.tune,
                                  color: isDark
                                      ? AppColors.primaryDark
                                      : AppColors.primaryLight,
                                ),
                              ),
                              items: OperatingMode.values.map((mode) {
                                return DropdownMenuItem(
                                  value: mode,
                                  child: Text(mode.displayName),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedMode = val);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // 5. Application Appearance Card
                      AppCard(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionHeader(
                              title: 'APPLICATION APPEARANCE',
                              subtitle:
                                  'Clinical dark slate or warm off-white theme selection',
                              icon: Icons.palette_outlined,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            SegmentedButton<ThemeMode>(
                              segments: const [
                                ButtonSegment(
                                  value: ThemeMode.dark,
                                  icon: Icon(Icons.dark_mode),
                                  label: Text('Dark (Telemetry)'),
                                ),
                                ButtonSegment(
                                  value: ThemeMode.light,
                                  icon: Icon(Icons.light_mode),
                                  label: Text('Light (Clinical)'),
                                ),
                              ],
                              selected: {currentThemeMode},
                              onSelectionChanged: (selection) {
                                ref
                                    .read(themeModeProvider.notifier)
                                    .setThemeMode(selection.first);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // 6. Danger Zone Card
                      AppCard(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        borderColor: AppColors.emergencyRed.withAlpha(120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionHeader(
                              title: 'DANGER ZONE',
                              subtitle:
                                  'Restore hardware configuration to factory defaults',
                              icon: Icons.warning_amber_rounded,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            DangerButton(
                              label: 'RESET FACTORY DEFAULTS',
                              icon: Icons.restart_alt,
                              height: 48,
                              onPressed: _handleReset,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Primary Sticky Save Action Button
                      PrimaryButton(
                        label: 'SAVE & APPLY SETTINGS',
                        icon: Icons.save,
                        height: 52,
                        onPressed: _handleSave,
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
