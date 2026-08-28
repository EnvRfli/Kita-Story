import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _idleController;

  // Staggered Entrance Animations
  late final Animation<Offset> _topLeftSlide;
  late final Animation<double> _topLeftScale;
  late final Animation<Offset> _topRightSlide;
  late final Animation<double> _topRightScale;
  late final Animation<Offset> _bottomRightSlide;
  late final Animation<double> _bottomRightScale;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;

  // Continuous Playful / Bouncy Idle Animations
  late final Animation<double> _idleFloat1;
  late final Animation<double> _idleFloat2;
  late final Animation<double> _idleFloat3;
  late final Animation<double> _idleLogoScale;
  late final Animation<double> _idleLogoRotate;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _checkAuth();
  }

  void _initAnimations() {
    // 1. Intro Animation Controller (1400ms)
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // 2. Idle Floating & Breathing Controller (2200ms)
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // --- Top-Left Component (9785753 3.png) ---
    _topLeftSlide = Tween<Offset>(
      begin: const Offset(-0.8, -0.8),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );
    _topLeftScale = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    // --- Top-Right Component (9785753 6.png) ---
    _topRightSlide = Tween<Offset>(
      begin: const Offset(0.8, -0.8),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.12, 0.8, curve: Curves.easeOutBack),
      ),
    );
    _topRightScale = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.12, 0.8, curve: Curves.easeOutBack),
      ),
    );

    // --- Bottom-Right Component (9785753 5.png) ---
    _bottomRightSlide = Tween<Offset>(
      begin: const Offset(0.8, 0.8),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.24, 0.9, curve: Curves.easeOutBack),
      ),
    );
    _bottomRightScale = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.24, 0.9, curve: Curves.easeOutBack),
      ),
    );

    // --- Center Logo (Group 9.png) ---
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.35, 1.0, curve: Curves.elasticOut),
      ),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeIn),
      ),
    );

    // --- Idle Floating Waves ---
    _idleFloat1 = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOutSine),
    );
    _idleFloat2 = Tween<double>(begin: 6.0, end: -6.0).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOutSine),
    );
    _idleFloat3 = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOutSine),
    );
    _idleLogoScale = Tween<double>(begin: 1.0, end: 1.035).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOutSine),
    );
    _idleLogoRotate = Tween<double>(begin: -0.015, end: 0.015).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOutSine),
    );

    // Start intro, then loop idle animation smoothly
    _introController.forward().then((_) {
      if (mounted) {
        _idleController.repeat(reverse: true);
      }
    });
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.checkAuthStatus();

    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _introController.dispose();
    _idleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F8),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Background Image
          Image.asset(
            'lib/assets/background/Loading Screen.png',
            fit: BoxFit.cover,
            width: size.width,
            height: size.height,
            errorBuilder: (context, error, stackTrace) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFEFF3),
                    Color(0xFFFFF9E6),
                    Color(0xFFE8F5E9),
                    Color(0xFFE3F2FD),
                  ],
                ),
              ),
            ),
          ),

          // 2. Top-Left Component (Yellow/Orange Noodle - 9785753 3.png)
          Positioned(
            top: -size.height * 0.06,
            left: -size.width * 0.20,
            child: AnimatedBuilder(
              animation: Listenable.merge([_introController, _idleController]),
              builder: (context, child) {
                final idleY = _idleFloat1.value;
                final idleX = math.sin(_idleController.value * math.pi) * 3;
                return Transform.translate(
                  offset: _topLeftSlide.value * 100 + Offset(idleX, idleY),
                  child: Transform.scale(
                    scale: _topLeftScale.value,
                    alignment: Alignment.topLeft,
                    child: child,
                  ),
                );
              },
              child: Image.asset(
                'lib/assets/tai/9785753 3.png',
                width: size.width * 0.62,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // 3. Top-Right Component (Purple/Red Noodle - 9785753 6.png)
          Positioned(
            top: -size.height * 0.065,
            right: -size.width * 0.22,
            child: AnimatedBuilder(
              animation: Listenable.merge([_introController, _idleController]),
              builder: (context, child) {
                final idleY = _idleFloat2.value;
                final idleX = -math.sin(_idleController.value * math.pi) * 3;
                return Transform.translate(
                  offset: _topRightSlide.value * 100 + Offset(idleX, idleY),
                  child: Transform.scale(
                    scale: _topRightScale.value,
                    alignment: Alignment.topRight,
                    child: child,
                  ),
                );
              },
              child: Image.asset(
                'lib/assets/tai/9785753 6.png',
                width: size.width * 0.70,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // 4. Bottom-Right Component (Blue/Purple Noodle - 9785753 5.png)
          Positioned(
            bottom: -size.height * 0.16,
            right: -size.width * 0.27,
            child: AnimatedBuilder(
              animation: Listenable.merge([_introController, _idleController]),
              builder: (context, child) {
                final idleY = _idleFloat3.value;
                final idleX = math.cos(_idleController.value * math.pi) * 3;
                return Transform.translate(
                  offset: _bottomRightSlide.value * 100 + Offset(idleX, idleY),
                  child: Transform.scale(
                    scale: _bottomRightScale.value,
                    alignment: Alignment.bottomRight,
                    child: child,
                  ),
                );
              },
              child: Image.asset(
                'lib/assets/tai/9785753 5.png',
                width: size.width * 0.82,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // 5. Center App Logo (Group 9.png) with Bouncy Elastic Pop & Pulse
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_introController, _idleController]),
              builder: (context, child) {
                final baseScale = _logoScale.value;
                final idleScale = _idleLogoScale.value;
                final idleRotation = _idleLogoRotate.value;

                return Opacity(
                  opacity: _logoFade.value,
                  child: Transform.rotate(
                    angle: idleRotation,
                    child: Transform.scale(
                      scale: baseScale * idleScale,
                      child: child,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36.0),
                child: Image.asset(
                  'lib/assets/logo/Group 9.png',
                  width: size.width * 0.72,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
