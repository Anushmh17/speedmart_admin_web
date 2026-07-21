import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../../../shared/models/user_role.dart';

class AdminLogin extends ConsumerStatefulWidget {
  const AdminLogin({super.key});

  @override
  ConsumerState<AdminLogin> createState() => _AdminLoginState();
}

class _AdminLoginState extends ConsumerState<AdminLogin> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).login(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      role: UserRole.admin,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CloudBackground(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(36),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(40, 42, 40, 40),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.72),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFFFFFF),
                            Color(0xFFFBF8FF),
                          ],
                        ),

                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x332D1457),
                            blurRadius: 60,
                            spreadRadius: 12,
                            offset: Offset(0, 30),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 180,
                            height: 43,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(13),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x22000000),
                                  blurRadius: 18,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Image.asset(
                                'assets/images/logo.png',
                                width: 150,
                                height: 42,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Sign in with Username',
                            style: AppTextStyles.display2(const Color(0xFF241B45)).copyWith(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sign in to access the Speedmart Admin Dashboard.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium(const Color(0xFF6B7280)),
                          ),
                          const SizedBox(height: 30),
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextFormField(
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  validator: Validators.email,
                                  style: const TextStyle(
                                    color: Color(0xFF1F2937),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  cursorColor: const Color(0xFF7C3AED),
                                  decoration: InputDecoration(
                                    hintText: 'Username',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF9CA3AF),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    prefixIcon: const Icon(
                                      Icons.email_outlined,
                                      color: Color(0xFF7C3AED),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 18,
                                      horizontal: 18,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE5D9FF),
                                        width: 1.5,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF7C3AED),
                                        width: 2,
                                      ),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _passwordCtrl,
                                  obscureText: !_showPassword,
                                  textInputAction: TextInputAction.done,
                                  validator: Validators.password,
                                  style: const TextStyle(
                                    color: Color(0xFF1F2937),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  cursorColor: const Color(0xFF7C3AED),
                                  decoration: InputDecoration(
                                    hintText: 'Password',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF9CA3AF),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                      color: Color(0xFF7C3AED),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _showPassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: const Color(0xFF7C3AED),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _showPassword = !_showPassword;
                                        });
                                      },
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 18,
                                      horizontal: 18,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE5D9FF),
                                        width: 1.5,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF7C3AED),
                                        width: 2,
                                      ),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 22),
                                SizedBox(
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed: _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF5B21B6),
                                      foregroundColor: Colors.white,
                                      elevation: 14,
                                      shadowColor: const Color(0x665B21B6),
                                      padding: const EdgeInsets.symmetric(vertical: 18),
                                      animationDuration: const Duration(milliseconds: 200),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Text(
                                          "Get Started",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Icon(Icons.arrow_forward_rounded, size: 20),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}

class CloudBackground extends StatelessWidget {
  const CloudBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand(
      child: _LoginBackgroundImage(),
    );
  }
}

class _LoginBackgroundImage extends StatelessWidget {
  const _LoginBackgroundImage({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/admin_login_bg.png',
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withOpacity(0.20),
      colorBlendMode: BlendMode.darken,
      errorBuilder: (context, error, stackTrace) {
        return CustomPaint(
          painter: _CloudBackgroundPainter(),
        );
      },
    );
  }
}

class _CloudBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final skyRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFF4F4F4),
          Color(0xFFE6E7E9),
          Color(0xFFC9CBCE),
        ],
      ).createShader(skyRect);
    canvas.drawRect(skyRect, skyPaint);

    void drawRange(List<Offset> points, Color color) {
      final path = Path()..moveTo(0, size.height);
      for (final point in points) {
        path.lineTo(point.dx * size.width, point.dy * size.height);
      }
      path.lineTo(size.width, size.height);
      path.close();
      canvas.drawPath(path, Paint()..color = color);
    }

    drawRange([
      const Offset(0, 0.92),
      const Offset(0.14, 0.72),
      const Offset(0.26, 0.80),
      const Offset(0.38, 0.90),
      const Offset(0.50, 0.82),
      const Offset(0.62, 0.76),
      const Offset(0.74, 0.86),
      const Offset(0.86, 0.92),
      const Offset(1, 0.88),
    ], const Color(0xFF898B8E));

    drawRange([
      const Offset(0, 0.82),
      const Offset(0.12, 0.62),
      const Offset(0.24, 0.72),
      const Offset(0.36, 0.84),
      const Offset(0.48, 0.76),
      const Offset(0.60, 0.68),
      const Offset(0.72, 0.78),
      const Offset(0.84, 0.86),
      const Offset(1, 0.80),
    ], const Color(0xFFA1A4A8));

    drawRange([
      const Offset(0, 0.70),
      const Offset(0.13, 0.50),
      const Offset(0.25, 0.60),
      const Offset(0.38, 0.74),
      const Offset(0.50, 0.66),
      const Offset(0.62, 0.56),
      const Offset(0.74, 0.66),
      const Offset(0.86, 0.74),
      const Offset(1, 0.70),
    ], const Color(0xFFB7BABB));

    drawRange([
      const Offset(0, 0.58),
      const Offset(0.14, 0.40),
      const Offset(0.28, 0.52),
      const Offset(0.42, 0.58),
      const Offset(0.56, 0.52),
      const Offset(0.70, 0.58),
      const Offset(0.82, 0.64),
      const Offset(0.94, 0.62),
      const Offset(1, 0.60),
    ], const Color(0xFFD0D2D5));

    final mistPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x00FFFFFF),
          Color(0x33FFFFFF),
          Color(0x55FFFFFF),
          Color(0x00FFFFFF),
        ],
      ).createShader(Rect.fromLTWH(0, size.height * 0.48, size.width, size.height * 0.30));
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.48, size.width, size.height * 0.30), mistPaint);

    final glowPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0x30FFFFFF),
          Color(0x00FFFFFF),
        ],
      ).createShader(Rect.fromCircle(center: Offset(size.width * 0.35, size.height * 0.20), radius: 120));
    canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.20), 120, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
