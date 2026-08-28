import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  late final AnimationController _transitionController;
  late final AnimationController _idleController;

  // Transition Animations
  late final Animation<Offset> _logoSlideAnimation;
  late final Animation<double> _logoScaleAnimation;
  late final Animation<Offset> _cardSlideAnimation;
  late final Animation<double> _cardFadeAnimation;

  // Subtle Idle Floating for Corner Elements
  late final Animation<double> _idleFloat1;
  late final Animation<double> _idleFloat2;
  late final Animation<double> _idleFloat3;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    // 1. Transition Controller (Smooth 900ms push-up animation)
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // 2. Idle Controller for decorative corner breathing
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    // Logo slides upward smoothly (from center position to top)
    _logoSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.45),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: Curves.easeOutCubic,
      ),
    );

    _logoScaleAnimation = Tween<double>(
      begin: 1.12,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Login Card slides up from bottom with spring fade
    _cardSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: const Interval(0.15, 1.0, curve: Curves.easeOutBack),
      ),
    );

    _cardFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: const Interval(0.1, 0.7, curve: Curves.easeIn),
      ),
    );

    // Corner idle floats
    _idleFloat1 = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOutSine),
    );
    _idleFloat2 = Tween<double>(begin: 5.0, end: -5.0).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOutSine),
    );
    _idleFloat3 = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOutSine),
    );

    // Trigger entrance animation
    _transitionController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _transitionController.dispose();
    _idleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      AppSnackBar.warning(context, 'Silakan masukkan email Anda.');
      return;
    }

    if (password.isEmpty) {
      AppSnackBar.warning(context, 'Silakan masukkan kata sandi Anda.');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signIn(email, password);

    if (!mounted) return;

    if (success) {
      context.go('/home');
    } else if (authProvider.errorMessage != null) {
      AppSnackBar.error(context, authProvider.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
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
              animation: _idleController,
              builder: (context, child) {
                final idleY = _idleFloat1.value;
                final idleX = math.sin(_idleController.value * math.pi) * 3;
                return Transform.translate(
                  offset: Offset(idleX, idleY),
                  child: child,
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
              animation: _idleController,
              builder: (context, child) {
                final idleY = _idleFloat2.value;
                final idleX = -math.sin(_idleController.value * math.pi) * 3;
                return Transform.translate(
                  offset: Offset(idleX, idleY),
                  child: child,
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
              animation: _idleController,
              builder: (context, child) {
                final idleY = _idleFloat3.value;
                final idleX = math.cos(_idleController.value * math.pi) * 3;
                return Transform.translate(
                  offset: Offset(idleX, idleY),
                  child: child,
                );
              },
              child: Image.asset(
                'lib/assets/tai/9785753 5.png',
                width: size.width * 0.82,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // 5. Main Scrollable Content (Logo + Form Card)
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 20.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 12),

                    // App Logo (Slides upward when login screen loads)
                    AnimatedBuilder(
                      animation: _transitionController,
                      builder: (context, child) {
                        return SlideTransition(
                          position: _logoSlideAnimation,
                          child: Transform.scale(
                            scale: _logoScaleAnimation.value,
                            child: child,
                          ),
                        );
                      },
                      child: Image.asset(
                        'lib/assets/logo/Group 9.png',
                        width: size.width * 0.75,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Translucent Frosted Glassmorphism Login Card (Pushed from bottom)
                    AnimatedBuilder(
                      animation: _transitionController,
                      builder: (context, child) {
                        return SlideTransition(
                          position: _cardSlideAnimation,
                          child: FadeTransition(
                            opacity: _cardFadeAnimation,
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 420),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 26,
                          vertical: 32,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.85),
                            width: 1.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6B4454)
                                  .withValues(alpha: 0.06),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Card Title with GradientBiru Shader
                            ShaderMask(
                              shaderCallback: (bounds) =>
                                  AppColors.gradientBiru.createShader(
                                Rect.fromLTWH(
                                    0, 0, bounds.width, bounds.height),
                              ),
                              child: const Text(
                                'Selamat Datang',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Card Subtitle
                            const Text(
                              'Silahkan masukkan email dan kata sandi\nuntuk masuk',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF555555),
                                height: 1.35,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 26),

                            // Email Field
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF333333),
                              ),
                              decoration: _buildInputDecoration(
                                hint: 'Email',
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Password Field
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _submit(),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF333333),
                              ),
                              decoration: _buildInputDecoration(
                                hint: 'Kata Sandi',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: const Color(0xFF555555),
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Submit Button with GradientBiru
                            Container(
                              decoration: BoxDecoration(
                                gradient: AppColors.gradientBiru,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6155F5)
                                        .withValues(alpha: 0.35),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed:
                                    authProvider.isLoading ? null : _submit,
                                child: authProvider.isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : const Text(
                                        'Masuk',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13.5),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.85),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E4EB), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E4EB), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF6155F5), width: 1.8),
      ),
    );
  }
}
