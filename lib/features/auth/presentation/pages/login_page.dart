import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/auth_cubit.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: BlocListener<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              context.go('/');
            } else if (state is AuthEmailConfirmationRequired) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.surface(context),
                  title: Row(
                    children: [
                      const Icon(Icons.email_outlined, color: AppColors.electricPurple),
                      const SizedBox(width: 8),
                      Text('Check Your Email', style: TextStyle(color: AppColors.text(context))),
                    ],
                  ),
                  content: Text(
                    'We sent a confirmation link to ${state.email}. Please check your email and click the link to activate your account.',
                    style: TextStyle(color: AppColors.textSecondary(context)),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            } else if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            }
          },
          child: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: GlassContainer(
                          padding: const EdgeInsets.all(24),
                          borderRadius: BorderRadius.circular(28),
                          opacity: 0.06,
                          child: Form(
                            key: _formKey,
                            child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Spacer(flex: 2),
                              // Logo
                              Center(
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: AppColors.primaryGradient,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.4),
                                        blurRadius: 25,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.play_arrow_rounded, size: 40, color: Colors.white),
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Title
                              Text(
                                'Welcome Back!',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.text(context),
                                  letterSpacing: -0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Login to continue watching',
                                style: TextStyle(fontSize: 14, color: AppColors.textMuted(context)),
                                textAlign: TextAlign.center,
                              ),
                              const Spacer(flex: 1),
                              // Email Field
                              GlassTextField(
                                controller: _emailController,
                                hintText: 'Email',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Please enter your email';
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(value)) return 'Please enter a valid email';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              // Password Field
                              GlassTextField(
                                controller: _passwordController,
                                hintText: 'Password',
                                prefixIcon: Icons.lock_outlined,
                                obscureText: !_isPasswordVisible,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: AppColors.textMuted(context),
                                  ),
                                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Please enter your password';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              // Forgot Password
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                            onPressed: () async {
                              if (_emailController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Please enter your email first'),
                                    backgroundColor: AppColors.warning,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                                return;
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(_emailController.text)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Please enter a valid email'),
                                    backgroundColor: AppColors.error,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                                return;
                              }
                              try {
                                await context.read<AuthCubit>().resetPassword(_emailController.text.trim());
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Password reset email sent!'),
                                      backgroundColor: AppColors.success,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Failed to send reset email. Please try again.'),
                                      backgroundColor: AppColors.error,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  );
                                }
                              }
                            },
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(color: AppColors.electricPurple.withValues(alpha: 0.8), fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Login Button
                        BlocBuilder<AuthCubit, AuthState>(
                          builder: (context, state) {
                            return GlassButton(
                              text: state is AuthLoading ? 'Loading...' : 'Login',
                              icon: state is AuthLoading ? null : Icons.login_rounded,
                              onPressed: state is AuthLoading ? null : _handleLogin,
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                        // Divider
                        Row(
                          children: [
                            Expanded(child: Container(height: 1, color: AppColors.border(context))),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text('Or continue with', style: TextStyle(color: AppColors.textMuted(context), fontSize: 13)),
                            ),
                            Expanded(child: Container(height: 1, color: AppColors.border(context))),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Social Buttons
                        Row(
                          children: [
                            Expanded(
                              child: _buildSocialButton(
                                context,
                                icon: Icons.g_mobiledata_rounded,
                                label: 'Google',
                                onTap: () {
                                  context.read<AuthCubit>().signInWithGoogle();
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildSocialButton(
                                context,
                                icon: Icons.apple_rounded,
                                label: 'Apple',
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: const Text('Coming soon!'), backgroundColor: AppColors.electricPurple, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const Spacer(flex: 2),
                        // Register Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Don't have an account? ", style: TextStyle(color: AppColors.textMuted(context))),
                            GestureDetector(
                              onTap: () => context.go('/register'),
                              child: const Text('Sign Up', style: TextStyle(color: AppColors.electricPurple, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const Spacer(flex: 1),
                      ],
                    ),
                  ),
                ),
              ),
              ),
              ),
            ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildSocialButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 14),
      borderRadius: BorderRadius.circular(14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.text(context), size: 24),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: AppColors.text(context), fontSize: 15, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
