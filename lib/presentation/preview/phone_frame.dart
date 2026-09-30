import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/theme_provider.dart';
import '../../core/theme/app_theme.dart';

/// Cutout type for simulated device screens.
enum CutoutType {
  dynamicIsland,
  punchHole,
}

/// Device specifications and hardware layout profile.
class PhoneProfile {
  final String id;
  final String name;
  final Size logicalSize;
  final double pixelRatio;
  final EdgeInsets safeArea;
  final CutoutType cutout;
  final double outerCornerRadius;
  final double innerCornerRadius;
  final double bezelWidth;

  const PhoneProfile({
    required this.id,
    required this.name,
    required this.logicalSize,
    required this.pixelRatio,
    required this.safeArea,
    required this.cutout,
    this.outerCornerRadius = 62.0,
    this.innerCornerRadius = 50.0,
    this.bezelWidth = 12.0,
  });

  static const iphone18Pro = PhoneProfile(
    id: 'iphone_18_pro',
    name: 'iPhone 18 Pro',
    logicalSize: Size(402, 874),
    pixelRatio: 3.0,
    safeArea: EdgeInsets.only(top: 62, bottom: 34),
    cutout: CutoutType.dynamicIsland,
    outerCornerRadius: 62.0,
    innerCornerRadius: 50.0,
    bezelWidth: 12.0,
  );

  static const iphone18ProMax = PhoneProfile(
    id: 'iphone_18_pro_max',
    name: 'iPhone 18 Pro Max',
    logicalSize: Size(440, 956),
    pixelRatio: 3.0,
    safeArea: EdgeInsets.only(top: 62, bottom: 34),
    cutout: CutoutType.dynamicIsland,
    outerCornerRadius: 64.0,
    innerCornerRadius: 52.0,
    bezelWidth: 12.0,
  );

  static const smallAndroid = PhoneProfile(
    id: 'pixel_android',
    name: 'Small Android (Pixel)',
    logicalSize: Size(412, 915),
    pixelRatio: 2.625,
    safeArea: EdgeInsets.only(top: 32, bottom: 24),
    cutout: CutoutType.punchHole,
    outerCornerRadius: 48.0,
    innerCornerRadius: 38.0,
    bezelWidth: 10.0,
  );

  static const List<PhoneProfile> allProfiles = [
    iphone18Pro,
    iphone18ProMax,
    smallAndroid,
  ];
}

/// Custom scroll behavior enabling drag scrolling via mouse, touch, and trackpad inside frame.
class PhoneScrollBehavior extends MaterialScrollBehavior {
  const PhoneScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };

  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) {
    // Hide desktop scrollbars inside phone viewport for realistic touch experience
    return child;
  }
}

/// Realistic Custom-Painted iPhone 18 Phone Frame with Interactive Preview Controls.
class PhonePreviewContainer extends ConsumerStatefulWidget {
  final Widget child;

  const PhonePreviewContainer({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<PhonePreviewContainer> createState() =>
      _PhonePreviewContainerState();
}

class _PhonePreviewContainerState extends ConsumerState<PhonePreviewContainer> {
  PhoneProfile _selectedProfile = PhoneProfile.iphone18Pro;
  bool _fitToScreen = true;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    final isWindowNarrow = (mediaQuery?.size.width ?? 1000) < 500;

    // On narrow windows (e.g. accessed directly on a mobile phone), show full-screen directly
    if (isWindowNarrow) {
      return widget.child;
    }

    final currentThemeMode = ref.watch(themeModeProvider);
    final isDark = currentThemeMode == ThemeMode.dark ||
        (currentThemeMode == ThemeMode.system &&
            (mediaQuery?.platformBrightness ?? Brightness.dark) ==
                Brightness.dark);

    final scaffold = Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;

          if (isWide) {
            return Row(
              children: [
                // Phone Viewport Area
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: _buildScaledPhone(constraints, isDark),
                    ),
                  ),
                ),

                // Side Control Panel
                Container(
                  width: 320,
                  decoration: const BoxDecoration(
                    color: Color(0xFF161B22),
                    border: Border(
                      left: BorderSide(color: Color(0xFF30363D), width: 1),
                    ),
                  ),
                  child: _buildControls(isDark),
                ),
              ],
            );
          } else {
            return Column(
              children: [
                // Top Control Bar
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF161B22),
                    border: Border(
                      bottom: BorderSide(color: Color(0xFF30363D), width: 1),
                    ),
                  ),
                  child: _buildCompactControls(isDark),
                ),

                // Phone Viewport Area
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildScaledPhone(constraints, isDark),
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );

    final hasMaterialContext = Directionality.maybeOf(context) != null;
    if (!hasMaterialContext) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF0D1117),
        ),
        home: scaffold,
      );
    }

    return scaffold;
  }

  Widget _buildScaledPhone(BoxConstraints parentConstraints, bool isDark) {
    final frameWidth = _selectedProfile.logicalSize.width +
        (_selectedProfile.bezelWidth * 2.0);
    final frameHeight = _selectedProfile.logicalSize.height +
        (_selectedProfile.bezelWidth * 2.0);

    // Compute fit scale factor (never scale above 1.0)
    final maxAvailableHeight = parentConstraints.maxHeight - 48.0;
    final maxAvailableWidth = parentConstraints.maxWidth - 48.0;
    final scaleFactor = _fitToScreen
        ? math.min(
            1.0,
            math.min(
              maxAvailableHeight / frameHeight,
              maxAvailableWidth / frameWidth,
            ),
          )
        : 1.0;

    return Transform.scale(
      scale: scaleFactor,
      child: PhoneFrame(
        profile: _selectedProfile,
        isDark: isDark,
        child: widget.child,
      ),
    );
  }

  Widget _buildControls(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.phone_iphone, size: 20, color: AppColors.primaryDark),
              SizedBox(width: 8),
              Text(
                'DEVICE PREVIEW',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Device Profile Selector
          const Text(
            'DEVICE PROFILE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8B949E),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF21262D),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF30363D)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<PhoneProfile>(
                value: _selectedProfile,
                dropdownColor: const Color(0xFF21262D),
                isExpanded: true,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Colors.white,
                  fontSize: 13,
                ),
                items: PhoneProfile.allProfiles.map((p) {
                  return DropdownMenuItem(
                    value: p,
                    child: Text(
                      '${p.name} (${p.logicalSize.width.toInt()}×${p.logicalSize.height.toInt()})',
                    ),
                  );
                }).toList(),
                onChanged: (profile) {
                  if (profile != null) {
                    setState(() => _selectedProfile = profile);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Theme Toggle
          const Text(
            'COLOR SCHEME',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8B949E),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.light_mode, size: 16),
                  label: const Text('Light'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: !isDark ? Colors.white : Colors.grey,
                    backgroundColor:
                        !isDark ? AppColors.primaryDark : Colors.transparent,
                    side: BorderSide(
                      color: !isDark
                          ? AppColors.primaryDark
                          : const Color(0xFF30363D),
                    ),
                  ),
                  onPressed: () => ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(ThemeMode.light),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.dark_mode, size: 16),
                  label: const Text('Dark'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : Colors.grey,
                    backgroundColor:
                        isDark ? AppColors.primaryDark : Colors.transparent,
                    side: BorderSide(
                      color: isDark
                          ? AppColors.primaryDark
                          : const Color(0xFF30363D),
                    ),
                  ),
                  onPressed: () => ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(ThemeMode.dark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Viewport Scaling
          const Text(
            'VIEWPORT SCALE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8B949E),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _fitToScreen ? Colors.white : Colors.grey,
                    backgroundColor: _fitToScreen
                        ? const Color(0xFF30363D)
                        : Colors.transparent,
                    side: const BorderSide(color: Color(0xFF30363D)),
                  ),
                  onPressed: () => setState(() => _fitToScreen = true),
                  child: const Text('Fit Window'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: !_fitToScreen ? Colors.white : Colors.grey,
                    backgroundColor: !_fitToScreen
                        ? const Color(0xFF30363D)
                        : Colors.transparent,
                    side: const BorderSide(color: Color(0xFF30363D)),
                  ),
                  onPressed: () => setState(() => _fitToScreen = false),
                  child: const Text('100% Actual'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          const Divider(color: Color(0xFF30363D)),
          const SizedBox(height: 12),

          // Note disclaimer
          Text(
            'Layout preview of a ${_selectedProfile.logicalSize.width.toInt()}×${_selectedProfile.logicalSize.height.toInt()} pt screen.\nNot a real iPhone.',
            style: const TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 11,
              color: Color(0xFF8B949E),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactControls(bool isDark) {
    return Row(
      children: [
        DropdownButton<PhoneProfile>(
          value: _selectedProfile,
          dropdownColor: const Color(0xFF21262D),
          underline: const SizedBox(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          items: PhoneProfile.allProfiles.map((p) {
            return DropdownMenuItem(value: p, child: Text(p.name));
          }).toList(),
          onChanged: (profile) {
            if (profile != null) {
              setState(() => _selectedProfile = profile);
            }
          },
        ),
        const Spacer(),
        IconButton(
          icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode,
              color: Colors.white, size: 18),
          onPressed: () {
            ref
                .read(themeModeProvider.notifier)
                .setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
          },
        ),
      ],
    );
  }
}

/// Standalone Realistic Phone Frame Widget.
class PhoneFrame extends StatelessWidget {
  final PhoneProfile profile;
  final bool isDark;
  final Widget child;

  const PhoneFrame({
    super.key,
    required this.profile,
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final frameWidth = profile.logicalSize.width + (profile.bezelWidth * 2.0);
    final frameHeight = profile.logicalSize.height + (profile.bezelWidth * 2.0);

    final frameWidget = Container(
      width: frameWidth,
      height: frameHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(profile.outerCornerRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(140),
            blurRadius: 40,
            spreadRadius: 8,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Hardware Buttons (Action, Volume, Power)
          _buildHardwareButtons(frameHeight),

          // 2. Outer Metallic Bezel Body
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF434956),
                  Color(0xFF1B1E24),
                  Color(0xFF2E333D),
                ],
              ),
              borderRadius: BorderRadius.circular(profile.outerCornerRadius),
              border: Border.all(
                color: const Color(0xFF636B7B),
                width: 1.5,
              ),
            ),
          ),

          // 3. Inner Screen Content
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(profile.bezelWidth),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(profile.innerCornerRadius),
                child: SizedBox(
                  width: profile.logicalSize.width,
                  height: profile.logicalSize.height,
                  child: Stack(
                    children: [
                      // App Tree inside Simulated MediaQuery & Theme
                      Positioned.fill(
                        child: ScrollConfiguration(
                          behavior: const PhoneScrollBehavior(),
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              platform: TargetPlatform.iOS,
                            ),
                            child: MediaQuery(
                              data: MediaQuery.of(context).copyWith(
                                size: profile.logicalSize,
                                devicePixelRatio: profile.pixelRatio,
                                padding: profile.safeArea,
                                viewPadding: profile.safeArea,
                                viewInsets: EdgeInsets.zero,
                              ),
                              child: child,
                            ),
                          ),
                        ),
                      ),

                      // Hardware Cutout / Dynamic Island
                      if (profile.cutout == CutoutType.dynamicIsland)
                        Positioned(
                          top: 11,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: _buildDynamicIsland(),
                          ),
                        )
                      else if (profile.cutout == CutoutType.punchHole)
                        Positioned(
                          top: 12,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),

                      // Status Bar Text Overlay
                      Positioned(
                        top:
                            profile.cutout == CutoutType.dynamicIsland ? 17 : 8,
                        left: 28,
                        right: 28,
                        child: _buildStatusBar(isDark),
                      ),

                      // Home Indicator Bar
                      Positioned(
                        bottom: 8,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 134,
                            height: 5,
                            decoration: BoxDecoration(
                              color: (isDark ? Colors.white : Colors.black)
                                  .withAlpha(80),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (Directionality.maybeOf(context) == null) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: frameWidget,
      );
    }

    return frameWidget;
  }

  Widget _buildHardwareButtons(double frameHeight) {
    return Positioned.fill(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Left Side: Action Button
          Positioned(
            left: -3,
            top: 110,
            child: Container(
              width: 3,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF4A5568),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Left Side: Volume Up
          Positioned(
            left: -3,
            top: 155,
            child: Container(
              width: 3,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF4A5568),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Left Side: Volume Down
          Positioned(
            left: -3,
            top: 218,
            child: Container(
              width: 3,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF4A5568),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Right Side: Power / Lock Button
          Positioned(
            right: -3,
            top: 165,
            child: Container(
              width: 3,
              height: 78,
              decoration: BoxDecoration(
                color: const Color(0xFF4A5568),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicIsland() {
    return Container(
      width: 126,
      height: 37,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            width: 11,
            height: 11,
            decoration: const BoxDecoration(
              color: Color(0xFF0D121B),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(bool isDark) {
    final fgColor = isDark ? Colors.white : Colors.black;

    return IgnorePointer(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Time
          Text(
            '9:41',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: fgColor,
            ),
          ),

          // Status Icons (Cellular, Wifi, Battery)
          Row(
            children: [
              Icon(Icons.signal_cellular_4_bar, size: 14, color: fgColor),
              const SizedBox(width: 4),
              Icon(Icons.wifi, size: 14, color: fgColor),
              const SizedBox(width: 4),
              Icon(Icons.battery_full, size: 16, color: fgColor),
            ],
          ),
        ],
      ),
    );
  }
}
