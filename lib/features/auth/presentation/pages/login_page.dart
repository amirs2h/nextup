import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/glass_container.dart';
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
      duration: const Duration(milliseconds: 1500),
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
    return Scaffold(
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.go('/');
          } else if (state is AuthEmailConfirmationRequired) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: const Color(0xFF1A1A2E),
                title: const Row(
                  children: [
                    Icon(Icons.email_outlined, color: Color(0xFF6C63FF)),
                    SizedBox(width: 8),
                    Text('Check Your Email', style: TextStyle(color: Colors.white)),
                  ],
                ),
                content: Text(
                  'We sent a confirmation link to ${state.email}. Please check your email and click the link to activate your account.',
                  style: const TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: const Color(0xFFFF4757),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0A0A0F),
                Color(0xFF1A1A2E),
                Color(0xFF16213E),
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
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
                        const SizedBox(height: 60),
                        // Logo
                        Center(
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE50914), Color(0xFFFF3D47)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE50914).withOpacity(0.4),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Title
                        const Text(
                          'Welcome Back!',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Login to continue watching',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),
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
                              color: Colors.white.withOpacity(0.5),
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        // Forgot Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              if (_emailController.text.isNotEmpty) {
                                context.read<AuthCubit>().resetPassword(
                                      _emailController.text.trim(),
                                    );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Password reset email sent!'),
                                    backgroundColor: const Color(0xFF00FF88),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: const Color(0xFF6C63FF).withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
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
                              onPressed: state is AuthLoading ? () {} : _handleLogin,
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                        // Divider
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Or continue with',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Social Buttons
                        Row(
                          children: [
                            Expanded(
                              child: _buildSocialButton(
                                icon: Icons.g_mobiledata_rounded,
                                label: 'Google',
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: const Text('Coming soon!'), backgroundColor: const Color(0xFF6C63FF), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildSocialButton(
                                icon: Icons.apple_rounded,
                                label: 'Apple',
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: const Text('Coming soon!'), backgroundColor: const Color(0xFF6C63FF), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        // Register Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.go('/register'),
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: Color(0xFF6C63FF),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 14),
      borderRadius: BorderRadius.circular(14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
