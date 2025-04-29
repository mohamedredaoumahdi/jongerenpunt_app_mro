import 'package:flutter/material.dart';
import 'package:jongerenpunt_app/constants/app_theme.dart';
import 'package:jongerenpunt_app/screens/home/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:jongerenpunt_app/services/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:jongerenpunt_app/widgets/custom_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _acceptedTerms = false;
  String? _errorMessage;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  // Improved email validation
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
  
  // Password strength validation
  String? _validatePasswordStrength(String password) {
    if (password.length < 8) {
      return 'Wachtwoord moet minimaal 8 tekens bevatten';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Wachtwoord moet minimaal 1 hoofdletter bevatten';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Wachtwoord moet minimaal 1 cijfer bevatten';
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Wachtwoord moet minimaal 1 speciaal teken bevatten';
    }
    return null;
  }
  
  Future<void> _register() async {
    // Clear previous error messages
    setState(() {
      _errorMessage = null;
    });
    
    if (!_formKey.currentState!.validate()) return;
    
    if (!_acceptedTerms) {
      setState(() {
        _errorMessage = 'Je moet de gebruiksvoorwaarden accepteren om door te gaan';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Get current user state before trying to modify it
      final isAnonymous = authService.isAnonymous;
      final isAuthenticated = authService.isAuthenticated;
      
      if (kDebugMode) {
        print('Current auth state - isAnonymous: $isAnonymous, isAuthenticated: $isAuthenticated');
      }
      
      if (isAuthenticated && isAnonymous) {
        // User is logged in anonymously, convert to permanent account
        if (kDebugMode) {
          print('Converting anonymous account to permanent');
        }
        
        await authService.convertAnonymousUserWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        // Create new account
        if (kDebugMode) {
          print('Creating new account');
        }
        
        await authService.registerWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Registration error: $e');
      }
      
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
    // Check if user is anonymous to show appropriate title
    final authService = Provider.of<AuthService>(context);
    final isAnonymous = authService.isAnonymous && authService.isAuthenticated;
    
    final String titleText = isAnonymous 
        ? 'Maak een account aan'
        : 'Maak een nieuw account';
        
    final String buttonText = isAnonymous 
        ? 'Account aanmaken'
        : 'Registreren';
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          isAnonymous ? 'Account aanmaken' : 'Registreren', 
          style: const TextStyle(color: Colors.white)
        ),
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
          bottom: false,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      titleText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Subtitle
                    const Text(
                      'Maak een account om alle functies te gebruiken.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Error message if any
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(Icons.error_outline, color: Colors.red, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Email field - using EmailTextField for consistent styling
                    EmailTextField(
                      controller: _emailController,
                      labelText: 'E-mailadres',
                      hintText: 'jouw@email.nl',
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Password field - using PasswordTextField for consistent styling
                    PasswordTextField(
                      controller: _passwordController,
                      labelText: 'Wachtwoord',
                      hintText: 'Voer een sterk wachtwoord in',
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Confirm Password field - using PasswordTextField for consistent styling
                    PasswordTextField(
                      controller: _confirmPasswordController,
                      labelText: 'Bevestig wachtwoord',
                      hintText: 'Voer wachtwoord opnieuw in',
                      isConfirmPassword: true,
                      primaryPasswordController: _passwordController,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Terms and conditions checkbox
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _acceptedTerms,
                            onChanged: (value) {
                              setState(() {
                                _acceptedTerms = value ?? false;
                              });
                            },
                            activeColor: AppColors.primaryStart,
                            checkColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _acceptedTerms = !_acceptedTerms;
                              });
                            },
                            child: const Text(
                              'Ik ga akkoord met de Gebruiksvoorwaarden en Privacybeleid',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Register button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primaryStart,
                          disabledBackgroundColor: Colors.white.withOpacity(0.6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading 
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: AppColors.primaryStart,
                                  strokeWidth: 2.0,
                                ),
                              )
                            : Text(
                                buttonText,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.text,
                                ),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Password requirements hint
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Wachtwoord vereisten:',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildRequirementRow('Minimaal 8 tekens'),
                          _buildRequirementRow('Minimaal 1 hoofdletter (A-Z)'),
                          _buildRequirementRow('Minimaal 1 cijfer (0-9)'),
                          _buildRequirementRow('Minimaal 1 speciaal teken (!@#\$%^&*.,?)'),
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
    );
  }
  
  Widget _buildRequirementRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}