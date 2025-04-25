import 'package:flutter/material.dart';
import 'package:jongerenpunt_app/constants/app_theme.dart';
import 'package:jongerenpunt_app/screens/auth/auth_screen.dart';
import 'package:jongerenpunt_app/screens/auth/register_screen.dart';
import 'package:jongerenpunt_app/screens/profile/settings_screen.dart';
import 'package:jongerenpunt_app/services/auth_service.dart';
import 'package:jongerenpunt_app/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _isNotificationsEnabled = true;
  
  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
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

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isAnonymous = authService.isAnonymous;
    final user = authService.currentUser;
    
    if (kDebugMode) {
      print('Profile screen - User: ${user?.uid}, isAnonymous: $isAnonymous');
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profiel'),
        backgroundColor: AppColors.primaryStart,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primaryStart,
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isAnonymous ? 'Gastgebruiker' : (user?.email ?? 'Gebruiker'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isAnonymous) ...[
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _navigateToCreateAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryStart,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Account aanmaken'),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Profile sections
            const Text(
              'Instellingen',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Notification settings
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications,
                      color: AppColors.primaryStart,
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Pushberichten',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Switch(
                      value: _isNotificationsEnabled,
                      onChanged: _toggleNotifications,
                      activeColor: AppColors.primaryStart,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Language settings
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.language,
                  color: AppColors.primaryStart,
                ),
                title: const Text('Taal'),
                trailing: const Text('Nederlands'),
                onTap: () {
                  // Language selection would be implemented here
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Theme settings
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.brightness_6,
                  color: AppColors.primaryStart,
                ),
                title: const Text('Thema'),
                trailing: const Text('Licht'),
                onTap: () {
                  // Theme selection would be implemented here
                },
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Support section
            const Text(
              'Ondersteuning',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Help & FAQ
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.help,
                  color: AppColors.primaryStart,
                ),
                title: const Text('Help & FAQ'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Navigate to help screen
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Contact
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.email,
                  color: AppColors.primaryStart,
                ),
                title: const Text('Contact'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Navigate to contact screen
                },
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Logout button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Uitloggen'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}