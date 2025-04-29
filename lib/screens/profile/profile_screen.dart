import 'package:flutter/material.dart';
import 'package:jongerenpunt_app/constants/app_theme.dart';
import 'package:jongerenpunt_app/screens/auth/auth_screen.dart';
import 'package:jongerenpunt_app/screens/auth/register_screen.dart';
import 'package:jongerenpunt_app/screens/help/contact_screen.dart';
import 'package:jongerenpunt_app/screens/help/faq_screen.dart';
import 'package:jongerenpunt_app/screens/profile/edit_profile_screen.dart';
import 'package:jongerenpunt_app/screens/profile/privacy_policy_screen.dart';
import 'package:jongerenpunt_app/screens/profile/settings_screen.dart';
import 'package:jongerenpunt_app/services/auth_service.dart';
import 'package:jongerenpunt_app/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _isNotificationsEnabled = true;
  bool _isLoading = true;
  Map<String, dynamic> _userData = {};
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadNotificationPreference();
  }
  
  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      if (authService.currentUser == null) {
        throw Exception('Geen gebruiker ingelogd');
      }
      
      if (!authService.isAnonymous) {
        // Fetch user profile data
        final userData = await authService.getUserProfile();
        
        if (!mounted) return;
        
        setState(() {
          _userData = userData;
          _isLoading = false;
        });
      } else {
        setState(() {
          _userData = {
            'username': 'Gastgebruiker',
            'isAnonymous': true,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user profile: $e');
      }
      
      if (mounted) {
        setState(() {
          _errorMessage = 'Fout bij het laden van je profiel';
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _loadNotificationPreference() async {
    // In a real app, this would be loaded from SharedPreferences
    setState(() {
      _isNotificationsEnabled = true;
    });
  }
  
  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _isNotificationsEnabled = value;
    });
    
    // Subscribe or unsubscribe from notification topics
    if (value) {
      await _notificationService.subscribeToTopic('general');
    } else {
      await _notificationService.unsubscribeFromTopic('general');
    }
    
    // Save preference to SharedPreferences (not implemented here)
  }
  
  Future<void> _logout() async {
    // Show confirmation dialog
    final bool confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uitloggen'),
        content: const Text('Weet je zeker dat je wilt uitloggen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Uitloggen'),
          ),
        ],
      ),
    ) ?? false;
    
    if (confirmed) {
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.signOut();
        
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AuthScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error during logout: $e');
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Uitloggen mislukt: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _navigateToCreateAccount() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RegisterScreen(),
      ),
    );
  }
  
  void _navigateToEditProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EditProfileScreen(),
      ),
    ).then((_) {
      // Refresh profile after editing
      _loadUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isAnonymous = authService.isAnonymous;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profiel', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryStart,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserProfile,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Profile header - centered
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Profile image
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[200],
                                image: _userData['profileImage'] != null
                                    ? DecorationImage(
                                        image: CachedNetworkImageProvider(_userData['profileImage']),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: _userData['profileImage'] == null
                                  ? Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.grey[400],
                                    )
                                  : null,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Username
                            Text(
                              _userData['username'] ?? 'Gebruiker',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            
                            // Email if available
                            if (!isAnonymous && _userData['email'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  _userData['email'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            
                            // Bio if available
                            if (_userData['bio'] != null && _userData['bio'].isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(
                                  _userData['bio'],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            
                            const SizedBox(height: 16),
                            
                            // Edit profile / create account button
                            SizedBox(
                              width: 200, // Fixed width for a medium-sized button
                              child: ElevatedButton.icon(
                                onPressed: isAnonymous
                                    ? _navigateToCreateAccount
                                    : _navigateToEditProfile,
                                icon: Icon(isAnonymous ? Icons.person_add : Icons.edit),
                                label: Text(isAnonymous ? 'Account aanmaken' : 'Profiel bewerken'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryStart,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Settings section
                    Align(
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'Instellingen',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Notification settings
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SwitchListTile(
                        title: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryStart.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.notifications,
                                color: AppColors.primaryStart,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Pushberichten'),
                                Text(
                                  'Ontvang meldingen en updates',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        value: _isNotificationsEnabled,
                        onChanged: _toggleNotifications,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Support section
                    Align(
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'Ondersteuning',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Help & FAQ
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryStart.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.help,
                            color: AppColors.primaryStart,
                            size: 20,
                          ),
                        ),
                        title: const Text('Help & FAQ'),
                        subtitle: const Text('Veelgestelde vragen'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const FAQScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Contact
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryStart.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.email,
                            color: AppColors.primaryStart,
                            size: 20,
                          ),
                        ),
                        title: const Text('Contact'),
                        subtitle: const Text('Neem contact met ons op'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ContactScreen(),
                            ),
                          );
                        },
                      ),
                    ),

                    // Privacy Policy card
Card(
  elevation: 2,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  child: ListTile(
    leading: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.primaryStart.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.privacy_tip,
        color: AppColors.primaryStart,
        size: 20,
      ),
    ),
    title: const Text('Privacybeleid'),
    subtitle: const Text('Lees hoe we jouw gegevens beschermen'),
    trailing: const Icon(Icons.chevron_right),
    onTap: () {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const PrivacyPolicyScreen(),
        ),
      );
    },
  ),
),

const SizedBox(height: 12),
                    
                    const SizedBox(height: 32),
                    
                    
                    // Logout button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout),
                        label: const Text('Uitloggen'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}