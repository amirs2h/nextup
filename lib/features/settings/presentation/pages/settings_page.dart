import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/domain/auth_cubit.dart';
import '../../domain/settings_cubit.dart';
import '../../../../shared/widgets/glass_container.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0A0A0F), const Color(0xFF1A1A2E)]
                : [const Color(0xFFF5F5F5), const Color(0xFFE8E8F0)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, isDark),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: BlocBuilder<SettingsCubit, SettingsState>(
                    builder: (context, state) {
                      return Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildSection(
                            isDark: isDark,
                            title: state.locale.languageCode == 'fa' ? 'ظاهر' : 'Appearance',
                            children: [
                              _buildThemeSelector(context, state, isDark),
                              _buildLanguageSelector(context, state, isDark),
                            ],
                          ),
                          _buildSection(
                            isDark: isDark,
                            title: state.locale.languageCode == 'fa' ? 'اعلان‌ها' : 'Notifications',
                            children: [
                              _buildSwitchTile(
                                isDark: isDark,
                                icon: Icons.notifications_outlined,
                                title: state.locale.languageCode == 'fa' ? 'اعلان‌های فشاری' : 'Push Notifications',
                                subtitle: state.locale.languageCode == 'fa' ? 'اعلان قسمت جدید' : 'Get notified for new episodes',
                                value: state.notificationsEnabled,
                                onChanged: (_) => context.read<SettingsCubit>().toggleNotifications(),
                              ),
                              _buildSwitchTile(
                                isDark: isDark,
                                icon: Icons.email_outlined,
                                title: state.locale.languageCode == 'fa' ? 'اعلان‌های ایمیلی' : 'Email Notifications',
                                subtitle: state.locale.languageCode == 'fa' ? 'خلاصه هفتگی' : 'Weekly watch summary',
                                value: state.emailNotifications,
                                onChanged: (_) => context.read<SettingsCubit>().toggleEmailNotifications(),
                              ),
                            ],
                          ),
                          _buildSection(
                            isDark: isDark,
                            title: state.locale.languageCode == 'fa' ? 'حساب کاربری' : 'Account',
                            children: [
                              _buildMenuTile(
                                isDark: isDark,
                                icon: Icons.person_outline,
                                title: state.locale.languageCode == 'fa' ? 'ویرایش پروفایل' : 'Edit Profile',
                                onTap: () => context.push('/edit-profile'),
                              ),
                              _buildMenuTile(
                                isDark: isDark,
                                icon: Icons.lock_outline,
                                title: state.locale.languageCode == 'fa' ? 'تغییر رمز عبور' : 'Change Password',
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(state.locale.languageCode == 'fa' ? 'بزودی!' : 'Coming soon!'), backgroundColor: const Color(0xFF6C63FF), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                  );
                                },
                              ),
                              _buildMenuTile(
                                isDark: isDark,
                                icon: Icons.delete_outline,
                                title: state.locale.languageCode == 'fa' ? 'حذف حساب' : 'Delete Account',
                                titleColor: const Color(0xFFFF4757),
                                onTap: () => _showDeleteDialog(context, state.locale.languageCode == 'fa'),
                              ),
                            ],
                          ),
                          _buildSection(
                            isDark: isDark,
                            title: state.locale.languageCode == 'fa' ? 'درباره' : 'About',
                            children: [
                              _buildInfoTile(isDark: isDark, icon: Icons.info_outline, title: state.locale.languageCode == 'fa' ? 'نسخه' : 'Version', value: '1.0.0'),
                              _buildMenuTile(
                                isDark: isDark,
                                icon: Icons.description_outlined,
                                title: state.locale.languageCode == 'fa' ? 'شرایط استفاده' : 'Terms of Service',
                                onTap: () {},
                              ),
                              _buildMenuTile(
                                isDark: isDark,
                                icon: Icons.privacy_tip_outlined,
                                title: state.locale.languageCode == 'fa' ? 'سیاست حریم خصوصی' : 'Privacy Policy',
                                onTap: () {},
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

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08)),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, state) {
              return Text(
                state.locale.languageCode == 'fa' ? 'تنظیمات' : 'Settings',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required bool isDark, required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5))),
        const SizedBox(height: 12),
        GlassContainer(
          padding: const EdgeInsets.all(4),
          borderRadius: BorderRadius.circular(16),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildThemeSelector(BuildContext context, SettingsState state, bool isDark) {
    String themeName = state.locale.languageCode == 'fa' ? 'تاریک' : 'Dark';
    if (state.themeMode == ThemeMode.light) themeName = state.locale.languageCode == 'fa' ? 'روشن' : 'Light';
    if (state.themeMode == ThemeMode.system) themeName = state.locale.languageCode == 'fa' ? 'سیستم' : 'System';

    return ListTile(
      leading: Icon(Icons.dark_mode_outlined, color: isDark ? Colors.white70 : Colors.black54),
      title: Text(state.locale.languageCode == 'fa' ? 'پوسته' : 'Theme', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
      subtitle: Text(themeName, style: TextStyle(color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5))),
      trailing: Icon(Icons.chevron_right, color: isDark ? Colors.white54 : Colors.black38),
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (modalContext) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.locale.languageCode == 'fa' ? 'انتخاب پوسته' : 'Choose Theme',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                ),
                const SizedBox(height: 20),
                _buildThemeOption(context, state.locale.languageCode == 'fa' ? 'تاریک' : 'Dark', Icons.dark_mode, ThemeMode.dark, state.themeMode, isDark),
                _buildThemeOption(context, state.locale.languageCode == 'fa' ? 'روشن' : 'Light', Icons.light_mode, ThemeMode.light, state.themeMode, isDark),
                _buildThemeOption(context, state.locale.languageCode == 'fa' ? 'سیستم' : 'System', Icons.settings_brightness, ThemeMode.system, state.themeMode, isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(BuildContext context, String title, IconData icon, ThemeMode mode, ThemeMode current, bool isDark) {
    final isSelected = mode == current;
    return ListTile(
      leading: Icon(icon, color: isSelected ? const Color(0xFFE50914) : (isDark ? Colors.white70 : Colors.black54)),
      title: Text(title, style: TextStyle(color: isSelected ? const Color(0xFFE50914) : (isDark ? Colors.white : Colors.black), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? const Icon(Icons.check, color: Color(0xFFE50914)) : null,
      onTap: () {
        context.read<SettingsCubit>().setThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildLanguageSelector(BuildContext context, SettingsState state, bool isDark) {
    String langName = state.locale.languageCode == 'fa' ? 'فارسی' : 'English';

    return ListTile(
      leading: Icon(Icons.language, color: isDark ? Colors.white70 : Colors.black54),
      title: Text(state.locale.languageCode == 'fa' ? 'زبان' : 'Language', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
      subtitle: Text(langName, style: TextStyle(color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5))),
      trailing: Icon(Icons.chevron_right, color: isDark ? Colors.white54 : Colors.black38),
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (modalContext) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.locale.languageCode == 'fa' ? 'انتخاب زبان' : 'Choose Language',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                ),
                const SizedBox(height: 20),
                _buildLanguageOption(context, 'English', 'en', state.locale, isDark),
                _buildLanguageOption(context, 'فارسی', 'fa', state.locale, isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(BuildContext context, String title, String code, Locale current, bool isDark) {
    final isSelected = code == current.languageCode;
    return ListTile(
      title: Text(title, style: TextStyle(color: isSelected ? const Color(0xFFE50914) : (isDark ? Colors.white : Colors.black), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? const Icon(Icons.check, color: Color(0xFFE50914)) : null,
      onTap: () {
        context.read<SettingsCubit>().setLocale(Locale(code));
        Navigator.pop(context);
      },
    );
  }

  Widget _buildSwitchTile({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: isDark ? Colors.white70 : Colors.black54),
      title: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
      subtitle: Text(subtitle, style: TextStyle(color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5))),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFFE50914),
    );
  }

  Widget _buildMenuTile({
    required bool isDark,
    required IconData icon,
    required String title,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: titleColor ?? (isDark ? Colors.white70 : Colors.black54)),
      title: Text(title, style: TextStyle(color: titleColor ?? (isDark ? Colors.white : Colors.black))),
      trailing: Icon(Icons.chevron_right, color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3)),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile({required bool isDark, required IconData icon, required String title, required String value}) {
    return ListTile(
      leading: Icon(icon, color: isDark ? Colors.white70 : Colors.black54),
      title: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
      trailing: Text(value, style: TextStyle(color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5))),
    );
  }

  Widget _buildSignOutButton(BuildContext context, bool isPersian) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(16),
      borderColor: const Color(0xFFFF4757).withOpacity(0.3),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              backgroundColor: const Color(0xFF1A1A2E),
              title: Text(isPersian ? 'خروج' : 'Sign Out', style: const TextStyle(color: Colors.white)),
              content: Text(isPersian ? 'آیا مطمئن هستید؟' : 'Are you sure you want to sign out?', style: const TextStyle(color: Colors.white70)),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(isPersian ? 'لغو' : 'Cancel')),
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    context.read<AuthCubit>().signOut();
                    context.go('/login');
                  },
                  child: Text(isPersian ? 'خروج' : 'Sign Out', style: const TextStyle(color: Color(0xFFFF4757))),
                ),
              ],
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, color: Color(0xFFFF4757), size: 22),
            const SizedBox(width: 8),
            Text(isPersian ? 'خروج از حساب' : 'Sign Out', style: const TextStyle(color: Color(0xFFFF4757), fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, bool isPersian) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(isPersian ? 'حذف حساب' : 'Delete Account', style: const TextStyle(color: Colors.white)),
        content: Text(
          isPersian ? 'آیا مطمئن هستید؟ این عمل غیرقابل بازگشت است.' : 'Are you sure you want to delete your account? This action cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(isPersian ? 'لغو' : 'Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isPersian ? 'حذف' : 'Delete', style: const TextStyle(color: Color(0xFFFF4757))),
          ),
        ],
      ),
    );
  }
}
