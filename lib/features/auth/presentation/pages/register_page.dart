import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../domain/auth_cubit.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
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
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            username: _usernameController.text.trim(),
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
                barrierDismissible: false,
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
                      onPressed: () {
                        Navigator.pop(context);
                        context.go('/login');
                      },
                      child: const Text('Go to Login'),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(flex: 1),
                        // Back Button
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => context.go('/login'),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.cardBg(context),
                                border: Border.all(
                                  color: AppColors.border(context),
                                ),
                              ),
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: AppColors.text(context),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Title
                        Text(
                          'Create Account',
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
                          'Join NextUp to track your shows',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textMuted(context),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),
                        // Username Field
                        GlassTextField(
                          controller: _usernameController,
                          hintText: 'Username',
                          prefixIcon: Icons.person_outlined,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a username';
                            }
                            if (value.trim().length < 3) {
                              return 'Username must be at least 3 characters';
                            }
                            if (value.trim().length > 20) {
                              return 'Username must be at most 20 characters';
                            }
                            if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
                              return 'Only letters, numbers, and _ allowed';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Email Field
                        GlassTextField(
                          controller: _emailController,
                          hintText: 'Email',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
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
                              _isPasswordVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.textMuted(context),
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (value.length < 8) {
                              return 'Password must be at least 8 characters';
                            }
                            if (!RegExp(r'[A-Z]').hasMatch(value)) {
                              return 'Must contain an uppercase letter';
                            }
                            if (!RegExp(r'[0-9]').hasMatch(value)) {
                              return 'Must contain a number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Confirm Password Field
                        GlassTextField(
                          controller: _confirmPasswordController,
                          hintText: 'Confirm Password',
                          prefixIcon: Icons.lock_outlined,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const Spacer(flex: 2),
                        // Register Button
                        BlocBuilder<AuthCubit, AuthState>(
                          builder: (context, state) {
                            return GlassButton(
                              text: state is AuthLoading ? 'Loading...' : 'Create Account',
                              icon: state is AuthLoading ? null : Icons.person_add_rounded,
                              gradient: const LinearGradient(
                                colors: [AppColors.electricPurple, AppColors.neonPurple],
                              ),
                              onPressed: state is AuthLoading ? () {} : _handleRegister,
                            );
                          },
                        ),
                        const Spacer(flex: 1),
                        // Login Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: TextStyle(
                                color: AppColors.textMuted(context),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.go('/login'),
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  color: AppColors.electricPurple,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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
            ],
          ),
        ),
      ),
    ),
    );
  }
}
