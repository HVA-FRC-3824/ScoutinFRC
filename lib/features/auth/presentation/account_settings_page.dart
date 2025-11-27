import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';

class AccountSettingsPage extends StatefulWidget {
  final VoidCallback? onMenuPressed;

  const AccountSettingsPage({super.key, this.onMenuPressed});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _teamNumberController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  
  String _selectedColor = 'primary'; 
  String? _photoURL;
  bool _notificationsEnabled = true;
  bool _isLoading = false;

  final Map<String, Color> _pfpColors = {
    'primary': AppColors.primary,
    'secondary': AppColors.secondary,
    'tertiary': AppColors.tertiary,
    'success': AppColors.success,
    'error': AppColors.error,
    'purple': Colors.purple,
    'teal': Colors.teal,
    'orange': Colors.orange,
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _teamNumberController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data != null) {
        _usernameController.text = data['username'] ?? '';
        _teamNumberController.text = data['teamNumber'] ?? '';
        _bioController.text = data['bio'] ?? '';
        setState(() {
          _selectedColor = data['pfpColor'] ?? 'primary';
          _photoURL = data['photoURL'];
          _notificationsEnabled = data['notificationsEnabled'] ?? true;
        });
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 75);

    if (image == null) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final storageRef = FirebaseStorage.instance.ref().child('profile_images/${user.uid}.jpg');
      
      final bytes = await image.readAsBytes();
      await storageRef.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));

      final downloadURL = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'photoURL': downloadURL,
      });

      setState(() {
        _photoURL = downloadURL;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'username': _usernameController.text,
            'teamNumber': _teamNumberController.text,
            'bio': _bioController.text,
            'pfpColor': _selectedColor,
            'notificationsEnabled': _notificationsEnabled,
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Settings saved successfully!')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error saving settings: $e')),
            );
          }
        }
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Account Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.onMenuPressed != null 
            ? IconButton(icon: const Icon(Icons.menu, color: AppColors.primary), onPressed: widget.onMenuPressed)
            : const BackButton(color: AppColors.primary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: _pickAndUploadImage,
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: AppColors.surface,
                              child: _photoURL != null
                                  ? ClipOval(
                                      child: CachedNetworkImage(
                                        imageUrl: _photoURL!,
                                        width: 92,
                                        height: 92,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => const CircularProgressIndicator(color: AppColors.primary),
                                        errorWidget: (context, url, error) => const Icon(Icons.error, color: AppColors.error),
                                      ),
                                    )
                                  : CircleAvatar(
                                      radius: 46,
                                      backgroundColor: _pfpColors[_selectedColor],
                                      child: Text(
                                        _usernameController.text.isNotEmpty 
                                            ? _usernameController.text[0].toUpperCase() 
                                            : 'S',
                                        style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickAndUploadImage,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.surface,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt, color: AppColors.primary, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text('Profile Picture Color (Fallback)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _pfpColors.entries.map((entry) {
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = entry.key),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: entry.value,
                              shape: BoxShape.circle,
                              border: _selectedColor == entry.key
                                  ? Border.all(color: Colors.white, width: 3)
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 30),
                    _buildSectionHeader('Personal Info'),
                    const SizedBox(height: 16),
                    _buildTextField('Username', _usernameController, Icons.person),
                    const SizedBox(height: 16),
                    _buildTextField('Team Number', _teamNumberController, Icons.group, keyboardType: TextInputType.number),
                    const SizedBox(height: 16),
                    _buildTextField('Bio', _bioController, Icons.info, maxLines: 3),
                    const SizedBox(height: 30),
                    _buildSectionHeader('Preferences'),
                    const SizedBox(height: 16),
                    _buildSwitchTile('Enable Notifications', 'Receive updates about matches and scouting', _notificationsEnabled, (val) => setState(() => _notificationsEnabled = val)),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        alignLabelWithHint: maxLines > 1,
      ),
      validator: (value) => value!.isEmpty && label == 'Username' ? 'Required' : null,
      onChanged: (val) {
        if (label == 'Username') setState(() {}); 
      },
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
