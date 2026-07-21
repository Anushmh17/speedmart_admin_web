import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../../../../shared/models/user_role.dart';
import '../../domain/auth_state.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key, required this.role});
  final UserRole role;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _inviteCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _inviteCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.role == UserRole.admin && _inviteCtrl.text.trim() != 'SPEEDMART_ADMIN') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid admin invite code')),
      );
      return;
    }

    await ref.read(authProvider.notifier).register(
          fullName: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          phone: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          role: widget.role,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated && !next.isLoading && next.user != null) {
        if (next.user!.role == UserRole.admin) {
          context.go(RouteNames.adminDashboard);
        }
      }
    });

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Create Admin Account', style: AppTextStyles.h2(isDark ? Colors.white : Colors.black)),
                  const SizedBox(height: 24),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextField(
                          label: 'Full Name',
                          controller: _nameCtrl,
                          prefixIcon: Icons.person_outline_rounded,
                          textInputAction: TextInputAction.next,
                          validator: Validators.fullName,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Email Address',
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          prefixIcon: Icons.email_outlined,
                          validator: Validators.email,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Password',
                          controller: _passwordCtrl,
                          obscureText: true,
                          textInputAction: TextInputAction.next,
                          prefixIcon: Icons.lock_outline_rounded,
                          validator: Validators.password,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Confirm Password',
                          controller: _confirmCtrl,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          prefixIcon: Icons.lock_outline_rounded,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value.trim() != _passwordCtrl.text.trim()) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Admin Invite Code',
                          controller: _inviteCtrl,
                          textInputAction: TextInputAction.done,
                          prefixIcon: Icons.vpn_key_outlined,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Invite code is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 52,
                          child: AppButton(
                            label: authState.isLoading ? 'Registering...' : 'Register',
                            onPressed: authState.isLoading ? null : _register,
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
    );
  }
}
