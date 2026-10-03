import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/connection_state.dart';
import '../../domain/models/device_telemetry.dart';
import '../../domain/models/wire_protocol.dart';
import 'common/app_card.dart';

/// Assignment §2 Compliant Telemetry Card
///
/// Explicitly displays the exact 7 dashboard metrics and canonical
/// wire protocol text frame as specified in Synthera Robotics Assignment §2 & §4:
/// - Device Name
/// - Connection Status
/// - Battery Percentage
/// - Hand Position
/// - Current Operating Mode
/// - EMG Signal / Value
/// - Current Hand State
class AssignmentTelemetryCard extends StatelessWidget {
  final DeviceTelemetry telemetry;
  final DeviceConnectionState connectionState;

  const AssignmentTelemetryCard({
    super.key,
    required this.telemetry,
    required this.connectionState,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccent =
        isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.badge_outlined,
                      size: 16,
                      color: primaryAccent,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        'SPEC §2 CONSOLE',
                        style: AppTypography.labelMedium(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: connectionState.isConnected
                      ? AppColors.successDark.withAlpha(25)
                      : AppColors.emergencyRed.withAlpha(25),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: connectionState.isConnected
                        ? AppColors.successDark.withAlpha(80)
                        : AppColors.emergencyRed.withAlpha(80),
                  ),
                ),
                child: Text(
                  connectionState.isConnected ? 'ONLINE' : 'OFFLINE',
                  style: TextStyle(
                    fontFamily: AppTypography.monoFontFamily,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: connectionState.isConnected
                        ? AppColors.successDark
                        : AppColors.emergencyRed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // 7 Core Metrics in a Clean 2-Column Clinical Grid
          Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              _buildTableRow(
                context,
                label1: 'Device Name',
                value1: telemetry.deviceName,
                label2: 'Status',
                value2: connectionState.displayName,
                isStatus2: true,
                isStatus2Connected: connectionState.isConnected,
              ),
              _buildTableRow(
                context,
                label1: 'Battery',
                value1: '${telemetry.batteryPercentage.toStringAsFixed(0)}%',
                label2: 'Hand Position',
                value2: '${telemetry.positionDegrees.toStringAsFixed(1)}°',
              ),
              _buildTableRow(
                context,
                label1: 'Operating Mode',
                value1: telemetry.operatingMode.displayName.toUpperCase(),
                label2: 'Current State',
                value2: telemetry.handState.displayName.toUpperCase(),
              ),
              _buildTableRow(
                context,
                label1: 'EMG Signal',
                value1: telemetry.isEmgSensorAvailable
                    ? '${telemetry.emgValue.toStringAsFixed(0)} uV'
                    : 'UNAVAILABLE',
                label2: 'Motor Cutoff',
                value2: telemetry.batteryPercentage <= 0 ? 'PROTECT' : 'NORMAL',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Canonical Serial Wire Protocol Frame (§4)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF090D16) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.terminal,
                  size: 14,
                  color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    WireProtocol.encodeTelemetry(telemetry),
                    style: TextStyle(
                      fontFamily: AppTypography.monoFontFamily,
                      fontFamilyFallback: AppTypography.monoFontFallbacks,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.primaryDark
                          : AppColors.primaryLight,
                      letterSpacing: 0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(
    BuildContext context, {
    required String label1,
    required String value1,
    required String label2,
    required String value2,
    bool isStatus2 = false,
    bool isStatus2Connected = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget buildCell(String label, String value,
        {bool isStatus = false, bool isConn = true}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Text.rich(
          TextSpan(
            text: '$label: ',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  fontFamily: AppTypography.monoFontFamily,
                  fontFamilyFallback: AppTypography.monoFontFallbacks,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isStatus
                      ? (isConn ? AppColors.successDark : AppColors.emergencyRed)
                      : (isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary),
                ),
              ),
            ],
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      );
    }

    return TableRow(
      children: [
        buildCell(label1, value1),
        buildCell(label2, value2,
            isStatus: isStatus2, isConn: isStatus2Connected),
      ],
    );
  }
}
