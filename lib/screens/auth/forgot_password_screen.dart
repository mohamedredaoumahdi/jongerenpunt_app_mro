import 'package:flutter/material.dart';
import 'package:jongerenpunt_app/constants/app_theme.dart';
import 'package:jongerenpunt_app/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:jongerenpunt_app/widgets/custom_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;
  String? _successMessage;
  
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
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _resetPassword() async {
    // Clear previous messages
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });
    
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.resetPassword(_emailController.text.trim());
      
      if (mounted) {
        setState(() {
          _emailSent = true;
          _isLoading = false;
          _successMessage = 'Een e-mail met instructies om je wachtwoord te resetten is verzonden naar ${_emailController.text}';
        });
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
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Wachtwoord vergeten',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Make back button white
        iconTheme: const IconThemeData(color: Colors.white),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Background decorative elements
              Positioned(
                top: -screenHeight * 0.1,
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
                bottom: -screenHeight * 0.15,
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
              
              // Main content
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: _emailSent ? _buildSuccessMessage() : _buildResetForm(),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildResetForm() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Wachtwoord resetten',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 12),
              
              const Text(
                'Voer je e-mailadres in en we sturen je een link om je wachtwoord te resetten.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
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
              
              // Success message if any
              if (_successMessage != null)
                SuccessMessage(
                  message: _successMessage!,
                  onDismiss: () {
                    setState(() {
                      _successMessage = null;
                    });
                  },
                ),
              
              // Email field
              EmailTextField(
                controller: _emailController,
                labelText: 'E-mailadres',
                hintText: 'jouw@email.nl',
              ),
              
              const SizedBox(height: 32),
              
              // Reset button
              PrimaryButton(
                text: 'Verstuur reset link',
                onPressed: _resetPassword,
                isLoading: _isLoading,
                icon: Icons.send,
              ),
              
              const Spacer(),
              
              // Back to login link
              Center(
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, color: Colors.white70, size: 16),
                  label: const Text(
                    'Terug naar inloggen',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
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
  
  Widget _buildSuccessMessage() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 80,
            ),
            
            const SizedBox(height: 32),
            
            const Text(
              'E-mail verstuurd!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'We hebben een e-mail met een link om je wachtwoord te resetten verzonden naar ${_emailController.text}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            
            const SizedBox(height: 32),
            
            PrimaryButton(
              text: 'Terug naar inloggen',
              onPressed: () => Navigator.of(context).pop(),
              icon: Icons.login,
            ),
            
            const SizedBox(height: 16),
            
            SecondaryButton(
              text: 'Opnieuw versturen',
              onPressed: _resetPassword,
              icon: Icons.refresh,
            ),
          ],
        ),
      ),
    );
  }
}