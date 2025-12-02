import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common/neo_button.dart';
import '../widgets/neo_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isLoading = false;
  XFile? _imageFile;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      _nameController.text = user.name;
      _bioController.text = user.bio ?? '';
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageFile = pickedFile;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId == null) throw 'User not found';

      String? avatarUrl;

      // Upload image if selected
      if (_imageFile != null && _imageBytes != null) {
        final fileExt = _imageFile!.name.split('.').last;
        final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        final filePath = 'avatars/$fileName';

        // Upload to Supabase Storage
        await SupabaseService.client.storage
            .from('profile-images')
            .uploadBinary(filePath, _imageBytes!);

        // Get public URL
        avatarUrl = SupabaseService.client.storage
            .from('profile-images')
            .getPublicUrl(filePath);
      }

      // Update profile in database
      final updateData = {
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (avatarUrl != null) {
        updateData['avatar_url'] = avatarUrl;
      }

      await SupabaseService.client.from('profiles').update(updateData).eq('id', userId);

      // Reload user data
      await context.read<AuthProvider>().loadUserProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 24,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.border,
            height: 3,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar Preview
                    Center(
                      child: Column(
                        children: [
                          // Avatar with upload button
                          Stack(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.border,
                                    width: 3,
                                  ),
                                  image: _imageBytes != null
                                      ? DecorationImage(
                                          image: MemoryImage(_imageBytes!),
                                          fit: BoxFit.cover,
                                        )
                                      : (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                                          ? DecorationImage(
                                              image: NetworkImage(user.avatarUrl!),
                                              fit: BoxFit.cover,
                                              onError: (_, __) {},
                                            )
                                          : null),
                                  color: AppColors.secondary,
                                ),
                                child: _imageBytes == null && 
                                    (user?.avatarUrl == null || user!.avatarUrl!.isEmpty)
                                    ? Center(
                                        child: Text(
                                          user?.name.substring(0, 1).toUpperCase() ?? 'U',
                                          style: const TextStyle(
                                            fontSize: 48,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              // Upload button
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.border,
                                        width: 3,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.black,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppConstants.spacingM),
                          Text(
                            user?.email ?? '',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          if (user?.isAdmin == true) ...[
                            const SizedBox(height: AppConstants.spacingS),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppConstants.spacingM,
                                vertical: AppConstants.spacingS,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warning,
                                border: Border.all(
                                  color: AppColors.border,
                                  width: AppConstants.borderWidth,
                                ),
                                borderRadius:
                                    BorderRadius.circular(AppConstants.borderRadius),
                              ),
                              child: const Text(
                                'ADMIN',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: AppConstants.spacingXL),

                    // Name Field
                    const Text(
                      'Display Name',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingS),
                    NeoTextField(
                      label: 'Name',
                      controller: _nameController,
                      hintText: 'Enter your display name',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name is required';
                        }
                        if (value.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppConstants.spacingL),

                    // Bio Field
                    const Text(
                      'Bio',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingM),
                    NeoTextField(
                      label: 'Bio',
                      controller: _bioController,
                      hintText: 'Tell us about yourself',
                      maxLines: 4,
                    ),

                    const SizedBox(height: AppConstants.spacingXL),

                    // Save Button
                    NeoButton(
                      text: 'Save Changes',
                      onPressed: _saveProfile,
                      color: AppColors.accent,
                      icon: Icons.save,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
