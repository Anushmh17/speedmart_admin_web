import 'package:speedmart_admin_web/shared/models/user_role.dart';

/// Resolves the role that should be used when the app starts.
///
/// For the web admin build we want the admin experience to open by default,
/// even if no previous role is stored in local storage.
String resolveStartupRole({required bool isWeb, String? savedRole}) {
  if (isWeb) {
    return UserRole.admin.name;
  }

  if (savedRole == null || savedRole.isEmpty) {
    return UserRole.customer.name;
  }

  return savedRole;
}
