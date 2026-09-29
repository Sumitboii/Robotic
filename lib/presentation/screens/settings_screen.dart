import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/settings_provider.dart';
import '../../application/providers/theme_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/device_settings.dart';
import '../../domain/models/operating_mode.dart';

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
          backgroundColor: AppTheme.crimson,
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
          backgroundColor: success ? AppTheme.mint : AppTheme.crimson,
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
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson),
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
          const SnackBar(
            content: Text('Factory defaults restored.'),
            backgroundColor: AppTheme.cyan,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsNotifierProvider);
    final currentThemeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SETTINGS',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Reset Defaults',
            icon: const Icon(Icons.restart_alt, color: Color(0xFF90A4AE)),
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
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 1. Device Profile Card
                  _buildSectionHeader('DEVICE IDENTITY'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Device Name / Model',
                      prefixIcon: Icon(Icons.devices, color: AppTheme.cyan),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Device name cannot be blank.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // 2. Motion & Kinematic Limits
                  _buildSectionHeader('MECHANICAL MOTION LIMITS'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _minAngleController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Min Angle (OPEN)',
                            suffixText: '°',
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _maxAngleController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Max Angle (CLOSED)',
                            suffixText: '°',
                          ),
                          validator: (val) {
                            final max = double.tryParse(val ?? '');
                            final min =
                                double.tryParse(_minAngleController.text);
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
                  const SizedBox(height: 20),

                  // 3. Biosensor Thresholds
                  _buildSectionHeader('BIOSENSOR & POWER THRESHOLDS'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emgThresholdController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'EMG Contraction Trigger Threshold',
                      suffixText: 'μV',
                      helperText: 'Recommended range: 100 - 180 μV',
                      prefixIcon: Icon(Icons.sensors, color: AppTheme.cyan),
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
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _batteryWarningController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Battery Warning Threshold',
                      suffixText: '%',
                      helperText: 'Alert triggered when level drops below this',
                      prefixIcon:
                          Icon(Icons.battery_alert, color: AppTheme.amber),
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
                  const SizedBox(height: 20),

                  // 4. Default Mode
                  _buildSectionHeader('DEFAULT OPERATING MODE'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<OperatingMode>(
                    value: _selectedMode,
                    decoration: const InputDecoration(
                      labelText: 'Startup Mode',
                      prefixIcon: Icon(Icons.tune, color: AppTheme.cyan),
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
                  const SizedBox(height: 20),

                  // 5. App Theme Preference
                  _buildSectionHeader('APPLICATION APPEARANCE'),
                  const SizedBox(height: 8),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode),
                        label: Text('Dark (Cyber)'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode),
                        label: Text('Light (Clean)'),
                      ),
                    ],
                    selected: {currentThemeMode},
                    onSelectionChanged: (selection) {
                      ref
                          .read(themeModeProvider.notifier)
                          .setThemeMode(selection.first);
                    },
                  ),
                  const SizedBox(height: 28),

                  // Save Button
                  ElevatedButton.icon(
                    onPressed: _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.cyan,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.save, size: 20),
                    label: const Text(
                      'SAVE & APPLY SETTINGS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Color(0xFF90A4AE),
        letterSpacing: 1.0,
      ),
    );
  }
}
