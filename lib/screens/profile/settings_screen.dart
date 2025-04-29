import 'package:flutter/material.dart';
import 'package:jongerenpunt_app/constants/app_theme.dart';
import 'package:jongerenpunt_app/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jongerenpunt_app/widgets/custom_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;
  bool _isNotificationsEnabled = true;
  
  // Controllers for password change dialog
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _passwordFormKey = GlobalKey<FormState>();
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _isNotificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading settings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _setNotifications(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', value);
      setState(() {
        _isNotificationsEnabled = value;
      });
    } catch (e) {
      debugPrint('Error setting notifications: $e');
    }
  }
  
  // Show password change dialog
  void _showChangePasswordDialog() {
    // Clear previous inputs
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wachtwoord wijzigen'),
        content: Form(
          key: _passwordFormKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Current password field
                PasswordTextField(
                  controller: _currentPasswordController,
                  labelText: 'Huidig wachtwoord',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Voer je huidige wachtwoord in';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // New password field
                PasswordTextField(
                  controller: _newPasswordController,
                  labelText: 'Nieuw wachtwoord',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Voer een nieuw wachtwoord in';
                    }
                    if (value.length < 8) {
                      return 'Wachtwoord moet minimaal 8 tekens bevatten';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Confirm password field
                PasswordTextField(
                  controller: _confirmPasswordController,
                  labelText: 'Bevestig wachtwoord',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Bevestig je nieuwe wachtwoord';
                    }
                    if (value != _newPasswordController.text) {
                      return 'Wachtwoorden komen niet overeen';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuleren'),
          ),
          ElevatedButton(
            onPressed: () => _updatePassword(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryStart,
              foregroundColor: Colors.white,
            ),
            child: const Text('Bijwerken'),
          ),
        ],
      ),
    );
  }
  
  // Update password
  Future<void> _updatePassword(BuildContext dialogContext) async {
    // Validate form
    if (!_passwordFormKey.currentState!.validate()) {
      return;
    }
    
    final authService = Provider.of<AuthService>(context, listen: false);
    
    try {
      // Close dialog first
      Navigator.of(dialogContext).pop();
      
      // Show loading indicator
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Wachtwoord wordt bijgewerkt...'),
          duration: Duration(seconds: 2),
        ),
      );
      
      // Update password
      await authService.updatePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );
      
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Wachtwoord is succesvol bijgewerkt'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isAnonymous = authService.isAnonymous;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instellingen', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryStart,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Account section
                const Text(
                  'Account',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.lightText,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Profile info
                      ListTile(
                        leading: const Icon(Icons.person, color: AppColors.primaryStart),
                        title: const Text('Profiel'),
                        subtitle: Text(
                          isAnonymous ? 'Gastgebruiker' : (authService.currentUser?.email ?? 'Gebruiker'),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pushNamed(context, '/edit_profile');
                        },
                      ),
                      
                      const Divider(),
                      
                      // Change password (only for registered users)
                      if (!isAnonymous)
                        ListTile(
                          leading: const Icon(Icons.lock, color: AppColors.primaryStart),
                          title: const Text('Wachtwoord wijzigen'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _showChangePasswordDialog,
                        ),
                      
                      // Create account (only for anonymous users)
                      if (isAnonymous)
                        ListTile(
                          leading: const Icon(Icons.person_add, color: AppColors.primaryStart),
                          title: const Text('Account aanmaken'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.pushNamed(context, '/register');
                          },
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Notifications section
                const Text(
                  'Notificaties',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.lightText,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Pushberichten'),
                        subtitle: const Text('Ontvang meldingen over updates en tips'),
                        value: _isNotificationsEnabled,
                        activeColor: AppColors.primaryStart,
                        onChanged: (value) async {
                          await _setNotifications(value);
                          // Here you would also subscribe/unsubscribe from Firebase topics
                        },
                        secondary: const Icon(Icons.notifications, color: AppColors.primaryStart),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // About section
                const Text(
                  'Over',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.lightText,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const ListTile(
                    leading: Icon(Icons.info, color: AppColors.primaryStart),
                    title: Text('Versie'),
                    subtitle: Text('1.0.0'),
                  ),
                ),
              ],
            ),
    );
  }
}