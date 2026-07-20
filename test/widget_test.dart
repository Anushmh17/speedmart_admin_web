// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:speedmart_admin_web/features/admin/presentation/screens/admin_vendor_management_screen.dart';

void main() {
  testWidgets('approval requests screen defaults to pending filter', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AdminVendorManagementScreen(
            initialFilter: 'pending',
            title: 'Approval Requests',
            subtitle: 'Review new registrations',
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final pendingChip = tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'Pending'));
    expect(pendingChip.selected, isTrue);
  });

  testWidgets('shop owners screen defaults to active filter', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AdminVendorManagementScreen(
            initialFilter: 'active',
            title: 'Shop Owners',
            subtitle: 'Accepted vendors',
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final activeChip = tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'Active'));
    expect(activeChip.selected, isTrue);
  });
}
