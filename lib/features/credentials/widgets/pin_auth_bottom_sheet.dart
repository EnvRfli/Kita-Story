import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/credential_security_provider.dart';
import 'pin_dots_input.dart';

enum PinSheetMode {
  verify,
  setup,
  reset,
}

class PinAuthBottomSheet extends StatefulWidget {
  final VoidCallback onSuccess;

  const PinAuthBottomSheet({
    super.key,
    required this.onSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onSuccess,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PinAuthBottomSheet(onSuccess: onSuccess),
    );
  }

  @override
  State<PinAuthBottomSheet> createState() => _PinAuthBottomSheetState();
}

class _PinAuthBottomSheetState extends State<PinAuthBottomSheet> {
  PinSheetMode _mode = PinSheetMode.verify;
  bool _isCheckingStatus = true;

  // Controllers
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Visibility Toggles
  bool _obscurePassword = true;

  String? _localError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initCheck());
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _initCheck() async {
    final authProvider = context.read<AuthProvider>();
    final securityProvider = context.read<CredentialSecurityProvider>();
    final userId = authProvider.currentUserProfile?.id;

    if (userId == null) {
      setState(() => _isCheckingStatus = false);
      return;
    }

    final hasPin = await securityProvider.checkPinStatus(userId);
    if (!mounted) return;

    setState(() {
      _mode = hasPin ? PinSheetMode.verify : PinSheetMode.setup;
      _isCheckingStatus = false;
    });
  }

  void _clearFields() {
    _pinController.clear();
    _confirmPinController.clear();
    _passwordController.clear();
    _localError = null;
    context.read<CredentialSecurityProvider>().clearError();
  }

  Future<void> _handleVerify() async {
    final pin = _pinController.text.trim();
    if (pin.length != 6) {
      setState(() => _localError = 'PIN harus terdiri dari 6 angka.');
      return;
    }

    setState(() => _localError = null);
    final authProvider = context.read<AuthProvider>();
    final securityProvider = context.read<CredentialSecurityProvider>();
    final userId = authProvider.currentUserProfile?.id;

    if (userId == null) {
      setState(() => _localError = 'Sesi pengguna tidak valid.');
      return;
    }

    final isValid = await securityProvider.verifyPin(userId, pin);
    if (!mounted) return;

    if (isValid) {
      Navigator.of(context).pop();
      widget.onSuccess();
    } else {
      _pinController.clear();
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _handleSetup() async {
    final pin = _pinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();
    final password = _passwordController.text;

    if (pin.length != 6) {
      setState(() => _localError = 'PIN baru harus 6 angka.');
      return;
    }
    if (pin != confirmPin) {
      setState(() => _localError = 'Konfirmasi PIN tidak cocok.');
      _confirmPinController.clear();
      HapticFeedback.mediumImpact();
      return;
    }
    if (password.isEmpty) {
      setState(
          () => _localError = 'Masukkan kata sandi akun untuk verifikasi.');
      return;
    }

    setState(() => _localError = null);
    final authProvider = context.read<AuthProvider>();
    final securityProvider = context.read<CredentialSecurityProvider>();
    final userId = authProvider.currentUserProfile?.id;
    final email = authProvider.currentEmail;

    if (userId == null || email == null) {
      setState(() => _localError = 'Data pengguna tidak ditemukan.');
      return;
    }

    final success = await securityProvider.setupPin(
      userId: userId,
      email: email,
      password: password,
      pin: pin,
    );
    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      widget.onSuccess();
    } else {
      _pinController.clear();
      _confirmPinController.clear();
      _passwordController.clear();
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _handleReset() async {
    final password = _passwordController.text;
    final newPin = _pinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (password.isEmpty) {
      setState(() => _localError = 'Masukkan kata sandi akun saat ini.');
      return;
    }
    if (newPin.length != 6) {
      setState(() => _localError = 'PIN baru harus 6 angka.');
      return;
    }
    if (newPin != confirmPin) {
      setState(() => _localError = 'Konfirmasi PIN baru tidak cocok.');
      _confirmPinController.clear();
      HapticFeedback.mediumImpact();
      return;
    }

    setState(() => _localError = null);
    final authProvider = context.read<AuthProvider>();
    final securityProvider = context.read<CredentialSecurityProvider>();
    final userId = authProvider.currentUserProfile?.id;
    final email = authProvider.currentEmail;

    if (userId == null || email == null) {
      setState(() => _localError = 'Data akun tidak ditemukan.');
      return;
    }

    final success = await securityProvider.resetPin(
      userId: userId,
      email: email,
      password: password,
      newPin: newPin,
    );
    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      widget.onSuccess();
    } else {
      _pinController.clear();
      _confirmPinController.clear();
      _passwordController.clear();
      HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final securityProvider = context.watch<CredentialSecurityProvider>();
    final isLoading = securityProvider.isLoading;
    final errorMessage = _localError ?? securityProvider.errorMessage;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: SafeArea(
          top: false,
          child: _isCheckingStatus
              ? const SizedBox(
                  height: 240,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF0088FF),
                      strokeWidth: 2.5,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Drag Handle
                      Center(
                        child: Container(
                          width: 38,
                          height: 4.5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 2. 3D Lock Illustration
                      Image.asset(
                        'lib/assets/homescreen assets/lock.png',
                        width: 78,
                        height: 78,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.lock_rounded,
                          size: 60,
                          color: Color(0xFF0088FF),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 3. Title & Subtitle
                      Text(
                        _getTitle(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _getSubtitle(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF64748B),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 4. Form Fields
                      if (_mode == PinSheetMode.verify) ...[
                        const SizedBox(height: 8),
                        PinDotsInput(
                          controller: _pinController,
                          autoFocus: true,
                          onCompleted: (_) => _handleVerify(),
                        ),
                        const SizedBox(height: 8),
                      ] else if (_mode == PinSheetMode.setup) ...[
                        _buildFieldLabel('1. Masukkan PIN Baru (6 Angka)'),
                        const SizedBox(height: 6),
                        PinDotsInput(
                          controller: _pinController,
                          autoFocus: false,
                        ),
                        const SizedBox(height: 16),
                        _buildFieldLabel('2. Konfirmasi PIN Baru'),
                        const SizedBox(height: 6),
                        PinDotsInput(
                          controller: _confirmPinController,
                          autoFocus: false,
                        ),
                        const SizedBox(height: 16),
                        _buildFieldLabel('3. Kata Sandi Akun Day Tale'),
                        const SizedBox(height: 6),
                        _buildPasswordInputField(
                          controller: _passwordController,
                          hintText: 'Masukkan kata sandi akun',
                          obscureText: _obscurePassword,
                          onToggleObscure: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                          onSubmitted: (_) => _handleSetup(),
                        ),
                      ] else if (_mode == PinSheetMode.reset) ...[
                        _buildFieldLabel('1. Kata Sandi Akun Saat Ini'),
                        const SizedBox(height: 6),
                        _buildPasswordInputField(
                          controller: _passwordController,
                          hintText: 'Masukkan kata sandi akun',
                          obscureText: _obscurePassword,
                          onToggleObscure: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        const SizedBox(height: 16),
                        _buildFieldLabel('2. PIN Baru (6 Angka)'),
                        const SizedBox(height: 6),
                        PinDotsInput(
                          controller: _pinController,
                          autoFocus: false,
                        ),
                        const SizedBox(height: 16),
                        _buildFieldLabel('3. Konfirmasi PIN Baru'),
                        const SizedBox(height: 6),
                        PinDotsInput(
                          controller: _confirmPinController,
                          autoFocus: false,
                          onCompleted: (_) => _handleReset(),
                        ),
                      ],

                      // 5. Error Alert Banner
                      if (errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFFCA5A5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: Color(0xFFDC2626),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  errorMessage,
                                  style: const TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // 6. Action Button (Gradient Biru)
                      Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: AppColors.gradientBiru,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0284F6)
                                  .withValues(alpha: 0.32),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: isLoading
                                ? null
                                : () {
                                    if (_mode == PinSheetMode.verify) {
                                      _handleVerify();
                                    } else if (_mode == PinSheetMode.setup) {
                                      _handleSetup();
                                    } else {
                                      _handleReset();
                                    }
                                  },
                            borderRadius: BorderRadius.circular(14),
                            child: Center(
                              child: isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.2,
                                      ),
                                    )
                                  : Text(
                                      _getButtonText(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),

                      // 7. Mode Switch Footer Links
                      const SizedBox(height: 10),
                      if (_mode == PinSheetMode.verify) ...[
                        TextButton(
                          onPressed: () {
                            _clearFields();
                            setState(() => _mode = PinSheetMode.reset);
                          },
                          child: const Text(
                            'Lupa PIN?',
                            style: TextStyle(
                              color: Color(0xFF0088FF),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ] else if (_mode == PinSheetMode.reset) ...[
                        TextButton(
                          onPressed: () {
                            _clearFields();
                            setState(() => _mode = PinSheetMode.verify);
                          },
                          child: const Text(
                            'Kembali ke Masukkan PIN',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF334155),
          letterSpacing: -0.1,
        ),
      ),
    );
  }

  Widget _buildPasswordInputField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggleObscure,
    ValueChanged<String>? onSubmitted,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          textInputAction: TextInputAction.done,
          onSubmitted: onSubmitted,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            hintText: hintText,
            hintStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF94A3B8),
            ),
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: Icon(
                obscureText
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF94A3B8),
                size: 20,
              ),
              onPressed: onToggleObscure,
            ),
          ),
        ),
      ),
    );
  }

  String _getTitle() {
    switch (_mode) {
      case PinSheetMode.verify:
        return 'PIN';
      case PinSheetMode.setup:
        return 'Buat PIN Baru';
      case PinSheetMode.reset:
        return 'Reset PIN';
    }
  }

  String _getSubtitle() {
    switch (_mode) {
      case PinSheetMode.verify:
        return 'Masukkan PIN untuk membuka menu ini';
      case PinSheetMode.setup:
        return 'Buat 6 digit PIN untuk mengamankan brankas kredensial';
      case PinSheetMode.reset:
        return 'Konfirmasi kata sandi akunmu untuk membuat PIN baru';
    }
  }

  String _getButtonText() {
    switch (_mode) {
      case PinSheetMode.verify:
        return 'Selesai';
      case PinSheetMode.setup:
        return 'Simpan PIN & Lanjutkan';
      case PinSheetMode.reset:
        return 'Perbarui PIN';
    }
  }
}
