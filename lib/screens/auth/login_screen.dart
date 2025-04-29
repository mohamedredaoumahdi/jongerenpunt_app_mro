import 'package:flutter/material.dart';
import 'package:jongerenpunt_app/constants/app_theme.dart';
import 'package:jongerenpunt_app/screens/auth/forgot_password_screen.dart';
import 'package:jongerenpunt_app/screens/home/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:jongerenpunt_app/services/auth_service.dart';
import 'package:jongerenpunt_app/widgets/custom_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _rememberMe = false;
  
  // Animation controller for staggered animations
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    // Slide animation for form fields
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );
    
    // Fade animation for form fields
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );
    
    // Start the animation
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _login() async {
    // Clear previous error messages
    setState(() {
      _errorMessage = null;
    });
    
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Inloggen', style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          bottom: false, // Don't add padding at the bottom
          child: Stack(
            children: [
              // Background decorative elements - positioned relative to screen
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              Positioned(
                bottom: -150,
                left: -150,
                child: Container(
                  height: 300,
                  width: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              
              // Content
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - 
                                MediaQuery.of(context).padding.top - 
                                kToolbarHeight,
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 40),
                              
                              // Title
                              const Text(
                                'Log in op je account',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              
                              const SizedBox(height: 8),
                              
                              // Subtitle
                              const Text(
                                'Welkom terug! Vul je gegevens in om toegang te krijgen.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              
                              const SizedBox(height: 32),
                              
                              // Error message if any
                              if (_errorMessage != null)
                                ErrorMessage(
                                  message: _errorMessage!,
                                  onDismiss: () {
                                    setState(() {
                                      _errorMessage = null;
                                    });
                                  },
                                ),
                              
                              // Email field
                              EmailTextField(
                                controller: _emailController,
                                labelText: 'E-mailadres',
                                hintText: 'jouw@email.nl',
                              ),
                              
                              // Password field
                              PasswordTextField(
                                controller: _passwordController,
                                labelText: 'Wachtwoord',
                              ),
                              
                              // Remember me checkbox and forgot password link
                              Container(
                                width: double.infinity, // Ensure the Row has a finite width constraint
                                child: Row(
                                  mainAxisSize: MainAxisSize.max, // Use all available space
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Remember me checkbox
                                    LabeledCheckbox(
                                      label: 'Onthoud mij',
                                      value: _rememberMe,
                                      onChanged: (value) {
                                        setState(() {
                                          _rememberMe = value ?? false;
                                        });
                                      },
                                      textStyle: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                    
                                    // Forgot password link
                                    TextButton(
                                      onPressed: _isLoading 
                                          ? null 
                                          : () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) => const ForgotPasswordScreen(),
                                                ),
                                              );
                                            },
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                      ),
                                      child: const Text(
                                        'Wachtwoord vergeten?',
                                        style: TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 32),
                              
                              // Login button
                              PrimaryButton(
                                text: 'Inloggen',
                                onPressed: _login,
                                isLoading: _isLoading,
                                icon: Icons.login,
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // // Social login options
                              // Column(
                              //   crossAxisAlignment: CrossAxisAlignment.center,
                              //   children: [
                              //     Row(
                              //       children: [
                              //         const Expanded(
                              //           child: Divider(color: Colors.white30, thickness: 1),
                              //         ),
                              //         Padding(
                              //           padding: const EdgeInsets.symmetric(horizontal: 16),
                              //           child: Text(
                              //             'OF',
                              //             style: TextStyle(
                              //               color: Colors.white.withOpacity(0.7),
                              //               fontWeight: FontWeight.w500,
                              //             ),
                              //           ),
                              //         ),
                              //         const Expanded(
                              //           child: Divider(color: Colors.white30, thickness: 1),
                              //         ),
                              //       ],
                              //     ),
                                  
                              //     const SizedBox(height: 24),
                                  
                              //     // Social login buttons - ensure proper width constraints
                              //     SizedBox(
                              //       width: double.infinity,
                              //       child: Row(
                              //         mainAxisSize: MainAxisSize.min,
                              //         mainAxisAlignment: MainAxisAlignment.center,
                              //         children: [
                              //           // Google login button
                              //           _buildSocialButton(
                              //             icon: Icons.g_mobiledata,
                              //             label: 'Google',
                              //             onPressed: () {
                              //               _showSocialLoginNotImplemented('Google');
                              //             },
                              //           ),
                                        
                              //           const SizedBox(width: 16),
                                        
                              //           // Facebook login button
                              //           _buildSocialButton(
                              //             icon: Icons.facebook,
                              //             label: 'Facebook',
                              //             onPressed: () {
                              //               _showSocialLoginNotImplemented('Facebook');
                              //             },
                              //           ),
                                        
                              //           const SizedBox(width: 16),
                                        
                              //           // Apple login button
                              //           _buildSocialButton(
                              //             icon: Icons.apple,
                              //             label: 'Apple',
                              //             onPressed: () {
                              //               _showSocialLoginNotImplemented('Apple');
                              //             },
                              //           ),
                              //         ],
                              //       ),
                              //     ),
                              //   ],
                              // ),
                              
                              const SizedBox(height: 32),
                              
                              // No account yet? Register
                              SizedBox(
                                width: double.infinity, // Ensure the Row has a finite width constraint
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Nog geen account?',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pushReplacementNamed(context, '/register');
                                      },
                                      child: const Text(
                                        'Registreer hier',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Add extra space at the bottom to ensure no white gap
                              const SizedBox(height: 40),
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
    );
  }
  
  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Ensure column doesn't expand
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showSocialLoginNotImplemented(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Inloggen met $provider is nog niet beschikbaar.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}