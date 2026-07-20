import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/storage/storage_service.dart';
import 'shared/models/user_role.dart';
import 'main.dart' as app;

/// Minimal admin-only entrypoint.
/// This sets the saved role to `admin` so the router opens the admin shell
/// and avoids showing the customer/vendor login flows.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Persist a role hint so the router does not redirect to customer/vendor
  await StorageService.saveRole(UserRole.admin.name);

  runApp(const ProviderScope(child: app.SpeedmartApp()));
}
