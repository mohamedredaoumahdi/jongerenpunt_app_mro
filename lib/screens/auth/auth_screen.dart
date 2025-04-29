import 'package:flutter/material.dart';
import 'package:jongerenpunt_app/constants/app_theme.dart';
import 'package:jongerenpunt_app/screens/auth/login_screen.dart';
import 'package:jongerenpunt_app/screens/auth/register_screen.dart';
import 'package:jongerenpunt_app/screens/home/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:jongerenpunt_app/services/auth_service.dart';
import 'package:flutter/foundation.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _continueAsGuest() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      if (kDebugMode) {
        print('Attempting to sign in anonymously');
      }
      
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signInAnonymously();
      
      if (kDebugMode) {
        print('Anonymous sign in successful');
      }
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error signing in anonymously: $e');
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
    final screenHeight = MediaQuery.of(context).size.height;
    final authService = Provider.of<AuthService>(context);
    
    // If user is already authenticated, redirect to home screen
    if (authService.isAuthenticated) {
      if (kDebugMode) {
        print('User already authenticated, redirecting to home screen');
      }
      
      // Use Future.microtask to avoid build-phase navigation
      Future.microtask(() {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      });
      
      // Return a loading screen while redirecting
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }
    
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  // Background elements
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
                  SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(32.0, 48.0, 32.0, 0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(height: screenHeight * 0.08),
                          
                          // Logo - increased size
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.1),
                              ),
                              child: Image.asset(
                                'assets/images/logo1.png',
                                width: 180, // Increased from 100
                                height: 180, // Increased from 100
                                errorBuilder: (context, error, stackTrace) {
                                  if (kDebugMode) {
                                    print('Error loading logo: $error');
                                  }
                                  // Fallback if logo image is missing
                                  return Container(
                                    width: 180,
                                    height: 180,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.people,
                                      size: 90, // Increased from 50
                                      color: Colors.white,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          
                          SizedBox(height: screenHeight * 0.04),
                          
                          // Welcome title
                          SlideTransition(
                            position: _slideAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: const Text(
                                'Welkom bij Jongerenpunt',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          
                          SizedBox(height: screenHeight * 0.02),
                          
                          // Welcome description
                          SlideTransition(
                            position: _slideAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: const Text(
                                'Jouw gids voor informatie over financiën, gezondheid, onderwijs, wonen en meer',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          
                          SizedBox(height: screenHeight * 0.06),
                          
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
                          
                          // Login button
                          SlideTransition(
                            position: _slideAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildButton(
                                text: 'Inloggen',
                                icon: Icons.login,
                                isPrimary: true,
                                onPressed: _isLoading 
                                    ? null 
                                    : () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => const LoginScreen(),
                                          ),
                                        );
                                      },
                              ),
                            ),
                          ),
                          
                          SizedBox(height: screenHeight * 0.02),
                          
                          // Register button
                          SlideTransition(
                            position: _slideAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildButton(
                                text: 'Registreren',
                                icon: Icons.person_add,
                                isPrimary: false,
                                onPressed: _isLoading 
                                    ? null 
                                    : () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => const RegisterScreen(),
                                          ),
                                        );
                                      },
                              ),
                            ),
                          ),
                          
                          SizedBox(height: screenHeight * 0.04),
                          
                          // Continue as guest
                          SlideTransition(
                            position: _slideAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: TextButton.icon(
                                onPressed: _isLoading ? null : _continueAsGuest,
                                icon: _isLoading
                                    ? Container(
                                        width: 18,
                                        height: 18,
                                        padding: const EdgeInsets.all(2),
                                        child: const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.0,
                                        ),
                                      )
                                    : const Icon(Icons.remove_red_eye, color: Colors.white70, size: 18),
                                label: Text(
                                  _isLoading ? 'Even geduld...' : 'Doorgaan zonder account',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          // Add spacing to ensure bottom content is visible
                          SizedBox(height: screenHeight * 0.05),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildButton({
    required String text,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? Colors.white : Colors.transparent,
          foregroundColor: isPrimary ? AppColors.primaryStart : Colors.white,
          elevation: isPrimary ? 0 : 0,
          side: isPrimary 
              ? null 
              : const BorderSide(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}