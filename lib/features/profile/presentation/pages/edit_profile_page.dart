import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/domain/auth_cubit.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../core/theme/app_colors.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      _usernameController.text = authState.profile?['username'] ?? '';
      _bioController.text = authState.profile?['bio'] ?? '';
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await context.read<AuthCubit>().updateProfile({
        'username': _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully!'),
            backgroundColor: const Color(0xFF00FF88),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: const Color(0xFFFF4757),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 32),
                _buildAvatarSection(context),
                const SizedBox(height: 32),
                _buildForm(context),
                const SizedBox(height: 32),
                _buildSaveButton(context),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cardBg(context),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.text(context), size: 20),
          ),
        ),
        const SizedBox(width: 16),
        Text('Edit Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text(context))),
      ],
    );
  }

  Widget _buildAvatarSection(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF9D4EDD)]),
            boxShadow: [BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Center(
            child: Text(
              _usernameController.text.isNotEmpty ? _usernameController.text[0].toUpperCase() : 'U',
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Coming soon!'),
                backgroundColor: const Color(0xFF6C63FF),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          },
          child: const Text('Change Photo', style: TextStyle(color: Color(0xFF6C63FF))),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      children: [
        GlassContainer(
          padding: const EdgeInsets.all(16),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Username', style: TextStyle(color: AppColors.textSecondary(context), fontSize: 13)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _usernameController,
                style: TextStyle(color: AppColors.text(context)),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.cardBg(context),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: Icon(Icons.person_outline, color: AppColors.textMuted(context)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Username is required';
                  }
                  if (value.trim().length < 3) {
                    return 'Username must be at least 3 characters';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassContainer(
          padding: const EdgeInsets.all(16),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bio', style: TextStyle(color: AppColors.textSecondary(context), fontSize: 13)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                style: TextStyle(color: AppColors.text(context)),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.cardBg(context),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  hintText: 'Tell us about yourself...',
                  hintStyle: TextStyle(color: AppColors.textMuted(context)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return GlassButton(
      text: _isLoading ? 'Saving...' : 'Save Changes',
      icon: _isLoading ? null : Icons.save_outlined,
      onPressed: _isLoading ? () {} : _saveProfile,
    );
  }
}
