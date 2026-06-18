import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../app/screens/browser_main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  
  bool _showFeatures = false;
  final List<bool> _featureVisibilities = [false, false, false];
  final List<bool> _featureActivated = [false, false, false];
  String _statusMessage = 'Initializing secure sandbox...';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack)),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.5, 0.9, curve: Curves.easeIn)),
    );

    _animationController.forward();

    // Trigger step-by-step feature chips entrance and status logs
    Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _statusMessage = 'Loading privacy configurations...');
    });

    Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _showFeatures = true);
    });

    for (int i = 0; i < 3; i++) {
      final index = i;
      Timer(Duration(milliseconds: 1600 + (index * 600)), () {
        if (mounted) {
          setState(() {
            _featureVisibilities[index] = true;
            if (index == 0) _statusMessage = 'Configuring Ad Blocker rules...';
            if (index == 1) _statusMessage = 'Establishing encrypted environment...';
            if (index == 2) _statusMessage = 'Preloading download manager...';
          });
        }
      });

      Timer(Duration(milliseconds: 2000 + (index * 600)), () {
        if (mounted) {
          setState(() {
            _featureActivated[index] = true;
            if (index == 0) _statusMessage = 'Ad Blocker active.';
            if (index == 1) _statusMessage = 'Private Browsing ready.';
            if (index == 2) _statusMessage = 'Downloader subsystem running.';
          });
        }
      });
    }

    Timer(const Duration(milliseconds: 3600), () {
      if (mounted) setState(() => _statusMessage = 'Launching Zyro Browser...');
    });

    // Load theme and state preferences during splash, then route
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    // Wait for the animation to complete and preloading tasks
    await Future.wait([
      Provider.of<ThemeController>(context, listen: false).init(),
      Future.delayed(const Duration(milliseconds: 4400)), // Ensure minimum splash duration
    ]);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const BrowserMainScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with custom gradient glow background
                  AnimatedBuilder(
                    animation: Listenable.merge([_animationController, _pulseController]),
                    builder: (context, child) {
                      final scalePulse = 1.0 + (_pulseController.value * 0.04);
                      return Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value * scalePulse,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(isDark ? 0.3 : 0.15),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: RotationTransition(
                          turns: _rotationController,
                          child: const Icon(
                            LucideIcons.globe,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  
                  // App Title and Sub-text
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _textOpacity.value,
                        child: child,
                      );
                    },
                    child: Column(
                      children: [
                        Text(
                          AppAssets.appName,
                          style: GoogleFonts.outfit(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 6,
                            color: theme.colorScheme.onBackground,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppAssets.appTagline,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onBackground.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Feature highlight chips (sliding one by one)
                  AnimatedOpacity(
                    opacity: _showFeatures ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: Column(
                      children: List.generate(3, (index) {
                        final feature = AppAssets.features[index];
                        IconData iconData;
                        Color iconColor;
                        if (index == 0) {
                          iconData = LucideIcons.shieldAlert;
                          iconColor = theme.colorScheme.secondary;
                        } else if (index == 1) {
                          iconData = LucideIcons.eyeOff;
                          iconColor = theme.colorScheme.tertiary;
                        } else {
                          iconData = LucideIcons.download;
                          iconColor = theme.colorScheme.primary;
                        }

                        return AnimatedPadding(
                          duration: const Duration(milliseconds: 500),
                          padding: EdgeInsets.only(
                            bottom: 12.0,
                            left: _featureVisibilities[index] ? 0.0 : 40.0,
                          ),
                          child: AnimatedOpacity(
                            opacity: _featureVisibilities[index] ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 400),
                            child: Container(
                              width: size.width * 0.8,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: theme.dividerColor.withOpacity(isDark ? 0.1 : 0.5),
                                ),
                                boxShadow: isDark ? null : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Icon(iconData, color: iconColor, size: 20),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          feature['title']!,
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onBackground,
                                          ),
                                        ),
                                        Text(
                                          feature['desc']!,
                                          style: GoogleFonts.outfit(
                                            fontSize: 10,
                                            color: theme.colorScheme.onBackground.withOpacity(0.5),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildStatusWidget(index, theme),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Dynamic Loading Status Message
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      _statusMessage,
                      key: ValueKey<String>(_statusMessage),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onBackground.withOpacity(0.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusWidget(int index, ThemeData theme) {
    if (!_featureVisibilities[index]) return const SizedBox(width: 16, height: 16);
    if (!_featureActivated[index]) {
      return SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            theme.colorScheme.primary.withOpacity(0.5),
          ),
        ),
      );
    }
    return Icon(
      LucideIcons.checkCircle,
      color: AppColors.success,
      size: 16,
    );
  }
}
