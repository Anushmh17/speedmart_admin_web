import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/user_role.dart';
import '../../presentation/widgets/admin_login.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key, required this.role});
  final UserRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AdminLogin();
  }
}
