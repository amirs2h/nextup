import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../auth/domain/auth_cubit.dart';
import '../../domain/settings_cubit.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/myket_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, s),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: BlocBuilder<SettingsCubit, SettingsState>(
                    builder: (context, state) {
                      final isFa = state.locale.languageCode == 'fa';
                      return Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildSection(
                            context,
                            title: s.appearance,
                            children: [
                              _buildThemeSelector(context, state, s),
                              _buildLanguageSelector(context, state, s),
                            ],
                          ),
                          _buildSection(
                            context,
                            title: s.notifications,
                            children: [
                              _buildSwitchTile(
                                context,
                                icon: Icons.notifications_outlined,
                                title: s.pushNotifications,
                                subtitle: s.pushNotificationsSub,
                                value: state.notificationsEnabled,
                                onChanged: (_) => context.read<SettingsCubit>().toggleNotifications(),
                              ),
                              _buildSwitchTile(
                                context,
                                icon: Icons.email_outlined,
                                title: s.emailNotifications,
                                subtitle: s.emailNotificationsSub,
                                value: state.emailNotifications,
                                onChanged: (_) => context.read<SettingsCubit>().toggleEmailNotifications(),
                              ),
                            ],
                          ),
                          _buildSection(
                            context,
                            title: s.account,
                            children: [
                              _buildMenuTile(
                                context,
                                icon: Icons.person_outline,
                                title: s.editProfile,
                                onTap: () => context.push('/edit-profile'),
                              ),
                              _buildMenuTile(
                                context,
                                icon: Icons.lock_outline,
                                title: s.changePassword,
                                onTap: () => _showChangePasswordDialog(context, isFa),
                              ),
                              _buildMenuTile(
                                context,
                                icon: Icons.delete_outline,
                                title: s.deleteAccount,
                                titleColor: AppColors.error,
                                onTap: () => _showDeleteDialog(context, isFa),
                              ),
                            ],
                          ),
                          // Myket section (store intents)
                          _buildSection(
                            context,
                            title: s.myket,
                            children: [
                              _buildMenuTile(
                                context,
                                icon: Icons.star_outline_rounded,
                                title: s.rateApp,
                                onTap: () => _openMyket(context, s, MyketService.openAppPage),
                              ),
                              _buildMenuTile(
                                context,
                                icon: Icons.rate_review_outlined,
                                title: s.sendComment,
                                onTap: () => _openMyket(context, s, MyketService.openComment),
                              ),
                              _buildMenuTile(
                                context,
                                icon: Icons.system_update_outlined,
                                title: s.checkForUpdate,
                                onTap: () => _openMyket(context, s, MyketService.openUpdate),
                              ),
                              _buildMenuTile(
                                context,
                                icon: Icons.apps_rounded,
                                title: s.otherApps,
                                onTap: () => _openMyket(context, s, MyketService.openAppPage),
                              ),
                            ],
                          ),
                          _buildSection(
                            context,
                            title: s.about,
                            children: [
                              _buildVersionTile(context, s),
                              _buildMenuTile(
                                context,
                                icon: Icons.description_outlined,
                                title: s.termsOfService,
                                onTap: () => _showInfoDialog(context, s.termsOfService, s.termsBody),
                              ),
                              _buildMenuTile(
                                context,
                                icon: Icons.privacy_tip_outlined,
                                title: s.privacyPolicy,
                                onTap: () => _showInfoDialog(context, s.privacyPolicy, s.privacyBody),
                              ),
                            ],
                          ),
                          // Publisher / editor info (Myket requirement)
                          _buildSection(
                            context,
                            title: s.aboutApp,
                            children: [
                              _buildInfoTile(context, icon: Icons.verified_user_outlined, title: s.publisher, value: AppStrings.publisherName),
                              _buildMenuTile(
                                context,
                                icon: Icons.telegram_outlined,
                                title: s.support,
                                trailingText: AppStrings.supportTelegram,
                                onTap: () => _openTelegram(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          _buildSignOutButton(context, s),
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

  Future<void> _openMyket(BuildContext context, AppStrings s, Future<bool> Function() action) async {
    final ok = await action();
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.myketNotAvailable), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _openTelegram() async {
    final handle = AppStrings.supportTelegram.replaceFirst('@', '');
    final uri = Uri.parse('https://t.me/$handle');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // ignore
    }
  }

  Widget _buildHeader(BuildContext context, AppStrings s) {
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
          Text(s.settings, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text(context))),
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

  Widget _buildThemeSelector(BuildContext context, SettingsState state, AppStrings s) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: AppColors.electricPurple.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.palette_outlined, color: AppColors.electricPurple, size: 20),
      ),
      title: Text(s.theme, style: TextStyle(color: AppColors.text(context), fontSize: 15, fontWeight: FontWeight.w500)),
      subtitle: Text(
        state.themeMode == ThemeMode.dark ? s.themeDark : state.themeMode == ThemeMode.light ? s.themeLight : s.themeSystem,
        style: TextStyle(color: AppColors.textMuted(context), fontSize: 13),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textMuted(context)),
      onTap: () => _showThemeBottomSheet(context, state, s),
    );
  }

  Widget _buildLanguageSelector(BuildContext context, SettingsState state, AppStrings s) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: AppColors.neonBlue.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.language_rounded, color: AppColors.neonBlue, size: 20),
      ),
      title: Text(s.language, style: TextStyle(color: AppColors.text(context), fontSize: 15, fontWeight: FontWeight.w500)),
      subtitle: Text(
        state.locale.languageCode == 'fa' ? 'فارسی' : 'English',
        style: TextStyle(color: AppColors.textMuted(context), fontSize: 13),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textMuted(context)),
      onTap: () => _showLanguageBottomSheet(context, state, s),
    );
  }

  Widget _buildSwitchTile(BuildContext context, {required IconData icon, required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
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

  Widget _buildMenuTile(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap, Color? titleColor, String? trailingText}) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: AppColors.cardBg(context), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: titleColor ?? AppColors.icon(context), size: 20),
      ),
      title: Text(title, style: TextStyle(color: titleColor ?? AppColors.text(context), fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: trailingText != null
          ? Text(trailingText, style: TextStyle(color: AppColors.textMuted(context), fontSize: 13))
          : Icon(Icons.chevron_right_rounded, color: AppColors.textMuted(context)),
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
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 160),
        child: Text(
          value,
          style: TextStyle(color: AppColors.textMuted(context), fontSize: 14),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          textAlign: TextAlign.end,
        ),
      ),
    );
  }

  Widget _buildVersionTile(BuildContext context, AppStrings s) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.hasData ? snapshot.data!.version : '';
        return _buildInfoTile(context, icon: Icons.info_outline, title: s.version, value: version);
      },
    );
  }

  Widget _buildSignOutButton(BuildContext context, AppStrings s) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: AppColors.surface(context),
            title: Text(s.signOut, style: TextStyle(color: AppColors.text(context))),
            content: Text(s.areYouSure, style: TextStyle(color: AppColors.textSecondary(context))),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surface(context),
                  foregroundColor: AppColors.text(context),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text(s.cancel, style: TextStyle(color: AppColors.textMuted(context), fontWeight: FontWeight.w600)),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  try {
                    await context.read<AuthCubit>().signOut();
                    if (context.mounted) context.go('/login');
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(s.failedToSignOut), backgroundColor: AppColors.error),
                      );
                    }
                  }
                },
                child: Text(s.signOut, style: const TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
            const SizedBox(width: 8),
            Text(s.signOutAccount, style: const TextStyle(color: AppColors.error, fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _showThemeBottomSheet(BuildContext context, SettingsState state, AppStrings s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.selectTheme, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text(context))),
            const SizedBox(height: 16),
            _buildThemeOption(context, state, ThemeMode.dark, Icons.dark_mode_rounded, s.themeDark),
            _buildThemeOption(context, state, ThemeMode.light, Icons.light_mode_rounded, s.themeLight),
            _buildThemeOption(context, state, ThemeMode.system, Icons.phone_android_rounded, s.themeSystem),
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

  void _showLanguageBottomSheet(BuildContext context, SettingsState state, AppStrings s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.selectLanguage, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text(context))),
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
    final s = AppStrings(isPersian);
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.changePassword, style: TextStyle(color: AppColors.text(context))),
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
                  hintText: s.currentPassword,
                  hintStyle: TextStyle(color: AppColors.textMuted(context)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border(context))),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.electricPurple)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return s.enterCurrentPassword;
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newPasswordController,
                obscureText: true,
                style: TextStyle(color: AppColors.text(context)),
                decoration: InputDecoration(
                  hintText: s.newPassword,
                  hintStyle: TextStyle(color: AppColors.textMuted(context)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border(context))),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.electricPurple)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return s.enterPassword;
                  if (value.length < 8) return s.minEightChars;
                  if (!RegExp(r'[A-Z]').hasMatch(value)) return s.mustHaveUppercase;
                  if (!RegExp(r'[0-9]').hasMatch(value)) return s.mustHaveNumber;
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                style: TextStyle(color: AppColors.text(context)),
                decoration: InputDecoration(
                  hintText: s.confirmPassword,
                  hintStyle: TextStyle(color: AppColors.textMuted(context)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border(context))),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.electricPurple)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return s.confirmPasswordHint;
                  if (value != newPasswordController.text) return s.passwordsNoMatch;
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              currentPasswordController.dispose();
              newPasswordController.dispose();
              confirmPasswordController.dispose();
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surface(context),
              foregroundColor: AppColors.text(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(s.cancel, style: TextStyle(color: AppColors.textMuted(context), fontWeight: FontWeight.w600)),
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
                        SnackBar(content: Text(s.passwordChanged), backgroundColor: AppColors.success),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(s.currentPasswordWrong), backgroundColor: AppColors.error),
                    );
                  }
                } finally {
                  currentPasswordController.dispose();
                  newPasswordController.dispose();
                  confirmPasswordController.dispose();
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.electricPurple),
            child: Text(s.change),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, bool isPersian) {
    final s = AppStrings(isPersian);
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.deleteAccount, style: const TextStyle(color: AppColors.error)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                s.deleteAccountConfirm,
                style: TextStyle(color: AppColors.textSecondary(context)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                style: TextStyle(color: AppColors.text(context)),
                decoration: InputDecoration(
                  hintText: s.enterPasswordToConfirm,
                  hintStyle: TextStyle(color: AppColors.textMuted(context)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border(context))),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.error)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return s.enterPassword;
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              passwordController.dispose();
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surface(context),
              foregroundColor: AppColors.text(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(s.cancel, style: TextStyle(color: AppColors.textMuted(context), fontWeight: FontWeight.w600)),
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
                  // Delete account (deletes data + auth user via Edge Function)
                  await supabase.deleteAccount(user.id);
                  // Clear local preferences
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  // Sign out (clears local session)
                  if (context.mounted) {
                    await context.read<AuthCubit>().signOut();
                    context.go('/login');
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(s.incorrectPassword), backgroundColor: AppColors.error),
                  );
                }
              } finally {
                passwordController.dispose();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(s.delete),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    final s = AppStrings.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: TextStyle(color: AppColors.text(context))),
        content: Text(content, style: TextStyle(color: AppColors.textSecondary(context))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(s.ok)),
        ],
      ),
    );
  }
}
