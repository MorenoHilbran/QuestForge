import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/neo_button.dart';
import '../../widgets/common/neo_text_field.dart';
import '../main_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleGoogleSignIn() {
    final authProvider = context.read<AuthProvider>();
    authProvider.signInWithGoogle().then((success) {
      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigation()),
        );
      } else if (authProvider.errorMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });
  }

  void _handleEmailSignIn() {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    authProvider.signInWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
    ).then((success) {
      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigation()),
        );
      } else if (authProvider.errorMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.spacingL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title - Neobrutalism Style
                Text(
                'QuestForge',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -4,
                  height: 1,
                  color: Colors.black,
                  shadows: [
                    Shadow(
                      color: Color(0xFFFF3B30),   // merah terang
                      offset: Offset(6, 6),
                      blurRadius: 0,
                    ),
                    Shadow(
                      color: Color(0xFF00D2FF),   // cyan kontras
                      offset: Offset(-3, -3),
                      blurRadius: 0,
                    ),
                  ],
                ),
              ),
                const SizedBox(height: AppConstants.spacingS),
                Text(
                  'Build Your Dev Journey',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: AppConstants.spacingXL * 2),

                // Email Login Form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      NeoTextField(
                        label: 'Email',
                        hint: 'Enter your email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      NeoTextField(
                        label: 'Password',
                        hint: 'Enter your password',
                        controller: _passwordController,
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppConstants.spacingL),
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          return NeoButton(
                            text: auth.isLoading ? 'Signing In...' : 'Sign In',
                            onPressed: auth.isLoading ? () {} : _handleEmailSignIn,
                            color: AppColors.primary,
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppConstants.spacingL),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.border, thickness: 2)),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingM,
                      ),
                      child: Text(
                        'OR',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppColors.border, thickness: 2)),
                  ],
                ),

                const SizedBox(height: AppConstants.spacingL),

                // Google Sign In Button
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return NeoButton(
                      text: 'Continue with Google',
                      onPressed: auth.isLoading ? () {} : _handleGoogleSignIn,
                      color: Colors.white,
                      icon: Icons.g_mobiledata_rounded,
                    );
                  },
                ),

                const SizedBox(height: AppConstants.spacingXL),

                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    TextButton(
                      onPressed: () {
                        // TODO: Navigate to register screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Register with Google or contact admin for email account'),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Register',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppConstants.spacingM),
                
              ],
            ),
          ),
        ),
      ),
    );
  }
}
