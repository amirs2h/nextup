import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/domain/auth_cubit.dart';
import '../../domain/settings_cubit.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../../../core/theme/app_colors.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: BlocBuilder<SettingsCubit, SettingsState>(
                    builder: (context, state) {
                      return Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildSection(
                            context,
                            title: state.locale.languageCode == 'fa' ? 'ظاهر' : 'Appearance',
                            children: [
                              _buildThemeSelector(context, state),
                              _buildLanguageSelector(context, state),
                            ],
                          ),
                          _buildSection(
                            context,
                            title: state.locale.languageCode == 'fa' ? 'اعلان‌ها' : 'Notifications',
                            children: [
                              _buildSwitchTile(
                                context,
                                icon: Icons.notifications_outlined,
                                title: state.locale.languageCode == 'fa' ? 'اعلان‌های فشاری' : 'Push Notifications',
                                subtitle: state.locale.languageCode == 'fa' ? 'اعلان قسمت جدید' : 'Get notified for new episodes',
                                value: state.notificationsEnabled,
                                onChanged: (_) => context.read<SettingsCubit>().toggleNotifications(),
                              ),
                              _buildSwitchTile(
                                context,
                                icon: Icons.email_outlined,
                                title: state.locale.languageCode == 'fa' ? 'اعلان‌های ایمیلی' : 'Email Notifications',
                                subtitle: state.locale.languageCode == 'fa' ? 'خلاصه هفتگی' : 'Weekly watch summary',
                                value: state.emailNotifications,
                                onChanged: (_) => context.read<SettingsCubit>().toggleEmailNotifications(),
                              ),
                            ],
                          ),
                          _buildSection(
                            context,
                            title: state.locale.languageCode == 'fa' ? 'حساب کاربری' : 'Account',
                            children: [
                              _buildMenuTile(
                                context,
                                icon: Icons.person_outline,
                                title: state.locale.languageCode == 'fa' ? 'ویرایش پروفایل' : 'Edit Profile',
                                onTap: () => context.push('/edit-profile'),
                              ),
                              _buildMenuTile(
                                context,
                                icon: Icons.lock_outline,
                                title: state.locale.languageCode == 'fa' ? 'تغییر رمز عبور' : 'Change Password',
                                onTap: () => _showChangePasswordDialog(context, state.locale.languageCode == 'fa'),
                              ),
                              _buildMenuTile(
                                context,
                                icon: Icons.delete_outline,
                                title: state.locale.languageCode == 'fa' ? 'حذف حساب' : 'Delete Account',
                                titleColor: AppColors.error,
                                onTap: () => _showDeleteDialog(context, state.locale.languageCode == 'fa'),
                              ),
                            ],
                          ),
                          _buildSection(
                            context,
                            title: state.locale.languageCode == 'fa' ? 'درباره' : 'About',
                            children: [
                              _buildInfoTile(context, icon: Icons.info_outline, title: state.locale.languageCode == 'fa' ? 'نسخه' : 'Version', value: '1.0.0'),
                              _buildMenuTile(
                                context,
                                icon: Icons.description_outlined,
                                title: state.locale.languageCode == 'fa' ? 'شرایط استفاده' : 'Terms of Service',
                                onTap: () => _showInfoDialog(context, state.locale.languageCode == 'fa' ? 'شرایط استفاده' : 'Terms of Service', state.locale.languageCode == 'fa' ? 'این برنامه تحت قوانین جمهوری اسلامی ایران فعالیت می‌کند.' : 'This application operates under applicable laws.'),
                              ),
                              _buildMenuTile(
                                context,
                                icon: Icons.privacy_tip_outlined,
                                title: state.locale.languageCode == 'fa' ? 'سیاست حریم خصوصی' : 'Privacy Policy',
                                onTap: () => _showInfoDialog(context, state.locale.languageCode == 'fa' ? 'سیاست حریم خصوصی' : 'Privacy Policy', state.locale.languageCode == 'fa' ? 'ما به حریم خصوصی شما احترام می‌گذاریم.' : 'We respect your privacy.'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          _buildSignOutButton(context, state.locale.languageCode == 'fa'),
                          const SizedBox(height: 100),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
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
          Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text(context))),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textSecondary(context))),
        ),
        GlassContainer(
          padding: const EdgeInsets.all(4),
          borderRadius: BorderRadius.circular(16),
          child: Column(children: children),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildThemeSelector(BuildContext context, SettingsState state) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: AppColors.electricPurple.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.palette_outlined, color: AppColors.electricPurple, size: 20),
      ),
      title: Text(state.locale.languageCode == 'fa' ? 'تم' : 'Theme', style: TextStyle(color: AppColors.text(context), fontSize: 15, fontWeight: FontWeight.w500)),
      subtitle: Text(
        state.themeMode == ThemeMode.dark ? 'Dark' : state.themeMode == ThemeMode.light ? 'Light' : 'System',
        style: TextStyle(color: AppColors.textMuted(context), fontSize: 13),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textMuted(context)),
      onTap: () => _showThemeBottomSheet(context, state),
    );
  }

  Widget _buildLanguageSelector(BuildContext context, SettingsState state) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: AppColors.neonBlue.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.language_rounded, color: AppColors.neonBlue, size: 20),
      ),
      title: Text(state.locale.languageCode == 'fa' ? 'زبان' : 'Language', style: TextStyle(color: AppColors.text(context), fontSize: 15, fontWeight: FontWeight.w500)),
      subtitle: Text(
        state.locale.languageCode == 'fa' ? 'فارسی' : 'English',
        style: TextStyle(color: AppColors.textMuted(context), fontSize: 13),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textMuted(context)),
      onTap: () => _showLanguageBottomSheet(context, state),
    );
  }

  Widget _buildSwitchTile(BuildContext context, {required IconData icon, required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppColors.accent, size: 20),
      ),
      title: Text(title, style: TextStyle(color: AppColors.text(context), fontSize: 15, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(color: AppColors.textMuted(context), fontSize: 13)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.electricPurple,
      ),
    );
  }

  Widget _buildMenuTile(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap, Color? titleColor}) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: AppColors.cardBg(context), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: titleColor ?? AppColors.icon(context), size: 20),
      ),
      title: Text(title, style: TextStyle(color: titleColor ?? AppColors.text(context), fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textMuted(context)),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile(BuildContext context, {required IconData icon, required String title, required String value}) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: AppColors.cardBg(context), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppColors.icon(context), size: 20),
      ),
      title: Text(title, style: TextStyle(color: AppColors.text(context), fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: Text(value, style: TextStyle(color: AppColors.textMuted(context), fontSize: 14)),
    );
  }

  Widget _buildSignOutButton(BuildContext context, bool isPersian) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: AppColors.surface(context),
            title: Text(isPersian ? 'خروج' : 'Sign Out', style: TextStyle(color: AppColors.text(context))),
            content: Text(isPersian ? 'آیا مطمئن هستید؟' : 'Are you sure?', style: TextStyle(color: AppColors.textSecondary(context))),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surface(context),
                  foregroundColor: AppColors.text(context),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text(isPersian ? 'لغو' : 'Cancel', style: TextStyle(color: AppColors.textMuted(context), fontWeight: FontWeight.w600)),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await context.read<AuthCubit>().signOut();
                  if (context.mounted) context.go('/login');
                },
                child: Text(isPersian ? 'خروج' : 'Sign Out', style: const TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
            const SizedBox(width: 8),
            Text(isPersian ? 'خروج از حساب' : 'Sign Out', style: const TextStyle(color: AppColors.error, fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _showThemeBottomSheet(BuildContext context, SettingsState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.locale.languageCode == 'fa' ? 'انتخاب تم' : 'Select Theme', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text(context))),
            const SizedBox(height: 16),
            _buildThemeOption(context, state, ThemeMode.dark, Icons.dark_mode_rounded, 'Dark'),
            _buildThemeOption(context, state, ThemeMode.light, Icons.light_mode_rounded, 'Light'),
            _buildThemeOption(context, state, ThemeMode.system, Icons.phone_android_rounded, 'System'),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, SettingsState state, ThemeMode mode, IconData icon, String label) {
    final isSelected = state.themeMode == mode;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.electricPurple : AppColors.icon(context)),
      title: Text(label, style: TextStyle(color: isSelected ? AppColors.electricPurple : AppColors.text(context), fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
      trailing: isSelected ? const Icon(Icons.check_rounded, color: AppColors.electricPurple) : null,
      onTap: () {
        context.read<SettingsCubit>().setThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }

  void _showLanguageBottomSheet(BuildContext context, SettingsState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.locale.languageCode == 'fa' ? 'انتخاب زبان' : 'Select Language', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text(context))),
            const SizedBox(height: 16),
            _buildLanguageOption(context, state, const Locale('en'), 'English', '🇺🇸'),
            _buildLanguageOption(context, state, const Locale('fa'), 'فارسی', '🇮🇷'),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(BuildContext context, SettingsState state, Locale locale, String label, String flag) {
    final isSelected = state.locale == locale;
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(label, style: TextStyle(color: isSelected ? AppColors.electricPurple : AppColors.text(context), fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
      trailing: isSelected ? const Icon(Icons.check_rounded, color: AppColors.electricPurple) : null,
      onTap: () {
        context.read<SettingsCubit>().setLocale(locale);
        Navigator.pop(context);
      },
    );
  }

  void _showChangePasswordDialog(BuildContext context, bool isPersian) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isPersian ? 'تغییر رمز عبور' : 'Change Password', style: TextStyle(color: AppColors.text(context))),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPasswordController,
                obscureText: true,
                style: TextStyle(color: AppColors.text(context)),
                decoration: InputDecoration(
                  hintText: isPersian ? 'رمز عبور فعلی' : 'Current Password',
                  hintStyle: TextStyle(color: AppColors.textMuted(context)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border(context))),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.electricPurple)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return isPersian ? 'رمز عبور فعلی را وارد کنید' : 'Please enter current password';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newPasswordController,
                obscureText: true,
                style: TextStyle(color: AppColors.text(context)),
                decoration: InputDecoration(
                  hintText: isPersian ? 'رمز عبور جدید' : 'New Password',
                  hintStyle: TextStyle(color: AppColors.textMuted(context)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border(context))),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.electricPurple)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return isPersian ? 'رمز عبور را وارد کنید' : 'Please enter password';
                  if (value.length < 8) return isPersian ? 'حداقل ۸ کاراکتر' : 'Minimum 8 characters';
                  if (!RegExp(r'[A-Z]').hasMatch(value)) return isPersian ? 'باید حرف بزرگ داشته باشد' : 'Must contain an uppercase letter';
                  if (!RegExp(r'[0-9]').hasMatch(value)) return isPersian ? 'باید عدد داشته باشد' : 'Must contain a number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                style: TextStyle(color: AppColors.text(context)),
                decoration: InputDecoration(
                  hintText: isPersian ? 'تکرار رمز عبور' : 'Confirm Password',
                  hintStyle: TextStyle(color: AppColors.textMuted(context)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border(context))),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.electricPurple)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return isPersian ? 'تکرار رمز عبور را وارد کنید' : 'Please confirm password';
                  if (value != newPasswordController.text) return isPersian ? 'رمز عبور مطابقت ندارد' : 'Passwords do not match';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surface(context),
              foregroundColor: AppColors.text(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(isPersian ? 'لغو' : 'Cancel', style: TextStyle(color: AppColors.textMuted(context), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext);
                try {
                  final supabase = context.read<SupabaseService>();
                  final user = supabase.currentUser;
                  if (user?.email != null) {
                    // Re-authenticate with current password
                    await supabase.signIn(email: user!.email!, password: currentPasswordController.text);
                    // Then update to new password
                    await supabase.updatePassword(newPasswordController.text);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(isPersian ? 'رمز عبور تغییر کرد' : 'Password changed'), backgroundColor: AppColors.success),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isPersian ? 'رمز عبور فعلی اشتباه است' : 'Current password is incorrect'), backgroundColor: AppColors.error),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.electricPurple),
            child: Text(isPersian ? 'تغییر' : 'Change'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, bool isPersian) {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isPersian ? 'حذف حساب' : 'Delete Account', style: const TextStyle(color: AppColors.error)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isPersian ? 'آیا مطمئن هستید؟ این عمل غیرقابل بازگشت است.' : 'Are you sure you want to delete your account? This action cannot be undone.',
                style: TextStyle(color: AppColors.textSecondary(context)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                style: TextStyle(color: AppColors.text(context)),
                decoration: InputDecoration(
                  hintText: isPersian ? 'رمز عبور فعلی را وارد کنید' : 'Enter your password to confirm',
                  hintStyle: TextStyle(color: AppColors.textMuted(context)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border(context))),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.error)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return isPersian ? 'رمز عبور را وارد کنید' : 'Please enter your password';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surface(context),
              foregroundColor: AppColors.text(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(isPersian ? 'لغو' : 'Cancel', style: TextStyle(color: AppColors.textMuted(context), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(dialogContext);
              try {
                final supabase = context.read<SupabaseService>();
                final user = supabase.currentUser;
                if (user?.email != null) {
                  // Re-authenticate first
                  await supabase.signIn(email: user!.email!, password: passwordController.text);
                  // Then delete
                  await supabase.deleteAccount(user.id);
                  if (context.mounted) {
                    context.read<AuthCubit>().signOut();
                    context.go('/login');
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isPersian ? 'رمز عبور اشتباه است' : 'Incorrect password'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(isPersian ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: TextStyle(color: AppColors.text(context))),
        content: Text(content, style: TextStyle(color: AppColors.textSecondary(context))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('OK')),
        ],
      ),
    );
  }
}
