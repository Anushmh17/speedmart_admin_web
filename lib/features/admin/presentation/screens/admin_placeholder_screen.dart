import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../widgets/admin_screen_header.dart';

class AdminPlaceholderScreen extends ConsumerWidget {
  const AdminPlaceholderScreen({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryText = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF3F4F6),
      body: Column(
        children: [
          AdminScreenHeader(
            title: title,
            subtitle: subtitle,
            icon: Icons.view_list_rounded,
            isDark: isDark,
          ),
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.construction_rounded, size: 48, color: AppColors.adminColor),
                    const SizedBox(height: 18),
                    Text('Coming soon', style: AppTextStyles.h2(primaryText)),
                    const SizedBox(height: 10),
                    Text(
                      'This admin section is not implemented yet. Use the main dashboard actions until the feature is available.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium(secondaryText),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
