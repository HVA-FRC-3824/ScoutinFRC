import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AccountSettingsPage extends StatelessWidget {
  final VoidCallback? onMenuPressed;

  const AccountSettingsPage({super.key, this.onMenuPressed});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Account Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: onMenuPressed != null 
            ? IconButton(icon: const Icon(Icons.menu, color: AppColors.primary), onPressed: onMenuPressed)
            : null,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.build, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text(
              'Account Settings',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Coming Soon',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
