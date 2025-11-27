import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/auth_gate.dart';

class SideMenu extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;

  const SideMenu({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  Future<Map<String, dynamic>> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      return doc.data() ?? {};
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: Column(
        children: [
          FutureBuilder<Map<String, dynamic>>(
            future: _getUserData(),
            builder: (context, snapshot) {
              final userData = snapshot.data ?? {};
              final username = userData['username'] ?? 'Scouter';
              final email = FirebaseAuth.instance.currentUser?.email ?? '';
              final role = userData['role'] ?? 'user';
              final photoURL = userData['photoURL'];

              return _buildHeader(username, email, role, photoURL);
            },
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem(context, 0, 'Account Settings', Icons.manage_accounts_outlined, Icons.manage_accounts),
              ],
            ),
          ),
          const Divider(color: AppColors.surfaceHighlight),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text('Logout', style: TextStyle(color: AppColors.error)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const AuthGate()),
                );
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader(String username, String email, String role, String? photoURL) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: AppColors.surface,
            child: photoURL != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: photoURL,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const CircularProgressIndicator(color: AppColors.primary),
                      errorWidget: (context, url, error) => const Icon(Icons.error, color: AppColors.error),
                    ),
                  )
                : Text(
                    username.isNotEmpty ? username[0].toUpperCase() : 'S',
                    style: const TextStyle(fontSize: 32, color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            username,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black),
          ),
          const SizedBox(height: 4),
          Text(email, style: const TextStyle(color: Colors.black87, fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              role.toString().toUpperCase(),
              style: const TextStyle(fontSize: 11, color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, String title, IconData icon, IconData selectedIcon) {
    final isSelected = selectedIndex == index;
    return ListTile(
      leading: Icon(
        isSelected ? selectedIcon : icon,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppColors.primary : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () {
        Navigator.pop(context); 
        onDestinationSelected(index);
      },
    );
  }
}
