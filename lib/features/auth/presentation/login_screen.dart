import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/error_snackbar.dart';
import '../../../shared/widgets/app_form_field.dart';
import '../auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthController _authController = AuthController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    // Credentials removed for production
  }

  void _handleLogin() async {
    final success = await _authController.login(
      _emailController.text,
      _passwordController.text,
    );

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } else if (mounted) {
      // Show snackbar for general errors (if any)
      if (_authController.errorMessage != null && _authController.errorMessage!.isNotEmpty) {
        ErrorSnackBar.show(context, _authController.errorMessage!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 80,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to access your dashboard',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 48),
              ListenableBuilder(
                listenable: _authController,
                builder: (context, _) {
                  return Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       AppFormField(
                          controller: _authController,
                          fieldName: 'Email',
                          textEditingController: _emailController,
                          hintText: 'Email',
                          prefixIcon: Icons.email_outlined,
                       ),
                     ],
                  );
                }
              ),
              const SizedBox(height: 16),
              ListenableBuilder(
                listenable: _authController,
                 builder: (context, _) {
                  return Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                        AppFormField(
                          controller: _authController,
                          fieldName: 'Password',
                          textEditingController: _passwordController,
                          hintText: 'Password',
                          prefixIcon: Icons.lock_outline,
                          obscureText: true,
                        ),
                     ],
                  );
                 },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ListenableBuilder(
                  listenable: _authController,
                  builder: (context, _) {
                    return PrimaryButton(
                      text: 'Sign In',
                      onPressed: _handleLogin,
                      isLoading: _authController.isLoading,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
