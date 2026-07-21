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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF5EEFF),
              Color(0xFFE8D8FF),
              Color(0xFFDCC8FF),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                padding: const EdgeInsets.fromLTRB(40, 42, 40, 40),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFFFFF),
                      Color(0xFFFDFBFF),
                      Color(0xFFF6F0FF),
                      Color(0xFFEFE5FF),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.8),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF6D28D9).withOpacity(0.15),
                      blurRadius: 45,
                      spreadRadius: 8,
                      offset: Offset(0, 18),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.7),
                      blurRadius: 8,
                      spreadRadius: -2,
                      offset: Offset(-3, -3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/images/logo.png', width: 140, fit: BoxFit.contain),
                    const SizedBox(height: 18),
                    Text(
                      'Sign in with email',
                      style: AppTextStyles.display2(Color(0xFF111827)).copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Make a new start to bring your worlds, data, and teams together. For free.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium(Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 20),
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
                            decoration: InputDecoration(
                              hintText: 'Email',
                              filled: true,
                              fillColor: Color(0xFFF3F4F6),
                              prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF9CA3AF)),
                              contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: !_showPassword,
                            textInputAction: TextInputAction.done,
                            validator: Validators.password,
                            decoration: InputDecoration(
                              hintText: 'Password',
                              filled: true,
                              fillColor: Color(0xFFF3F4F6),
                              prefixIcon: Icon(Icons.lock_outline_rounded, color: Color(0xFF9CA3AF)),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: Color(0xFF6B7280),
                                ),
                                onPressed: () => setState(() => _showPassword = !_showPassword),
                              ),
                              contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              child: Text('Get Started', style: AppTextStyles.button(Colors.white)),
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
    );
  }
  
}
