import 'package:flutter/material.dart';
import 'package:jongerenpunt_app/constants/app_theme.dart';
import 'package:jongerenpunt_app/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isNotificationsEnabled = true;
  bool _isDarkModeEnabled = false;
  String _selectedLanguage = 'Nederlands';
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _isNotificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _isDarkModeEnabled = prefs.getBool('dark_mode_enabled') ?? false;
      _selectedLanguage = prefs.getString('language') ?? 'Nederlands';
    });
  }
  
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setBool('notifications_enabled', _isNotificationsEnabled);
    await prefs.setBool('dark_mode_enabled', _isDarkModeEnabled);
    await prefs.setString('language', _selectedLanguage);
  }
  
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isAnonymous = authService.isAnonymous;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instellingen'),
        backgroundColor: AppColors.primaryStart,
        foregroundColor: Colors.white,
      ),
      body: ListView(
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
                    // Navigate to profile edit screen
                  },
                ),
                
                const Divider(),
                
                // Change password (only for registered users)
                if (!isAnonymous)
                  ListTile(
                    leading: const Icon(Icons.lock, color: AppColors.primaryStart),
                    title: const Text('Wachtwoord wijzigen'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Navigate to change password screen
                    },
                  ),
                
                // Create account (only for anonymous users)
                if (isAnonymous)
                  ListTile(
                    leading: const Icon(Icons.person_add, color: AppColors.primaryStart),
                    title: const Text('Account aanmaken'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Navigate to create account screen
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
                  onChanged: (value) {
                    setState(() {
                      _isNotificationsEnabled = value;
                    });
                    _saveSettings();
                  },
                  secondary: const Icon(Icons.notifications, color: AppColors.primaryStart),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Appearance section
          const Text(
            'Weergave',
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
                // Dark mode toggle
                SwitchListTile(
                  title: const Text('Donkere modus'),
                  subtitle: const Text('Schakel tussen licht en donker thema'),
                  value: _isDarkModeEnabled,
                  activeColor: AppColors.primaryStart,
                  onChanged: (value) {
                    setState(() {
                      _isDarkModeEnabled = value;
                    });
                    _saveSettings();
                    
                    // Note: In a real app, you would update the app theme here
                  },
                  secondary: const Icon(Icons.brightness_6, color: AppColors.primaryStart),
                ),
                
                const Divider(),
                
                // Language selection
                ListTile(
                  leading: const Icon(Icons.language, color: AppColors.primaryStart),
                  title: const Text('Taal'),
                  subtitle: Text(_selectedLanguage),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showLanguageSelectionDialog();
                  },
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
            child: Column(
              children: [
                // Privacy policy
                ListTile(
                  leading: const Icon(Icons.privacy_tip, color: AppColors.primaryStart),
                  title: const Text('Privacybeleid'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navigate to privacy policy screen
                  },
                ),
                
                const Divider(),
                
                // Terms and conditions
                ListTile(
                  leading: const Icon(Icons.description, color: AppColors.primaryStart),
                  title: const Text('Gebruiksvoorwaarden'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navigate to terms and conditions screen
                  },
                ),
                
                const Divider(),
                
                // App version
                const ListTile(
                  leading: Icon(Icons.info, color: AppColors.primaryStart),
                  title: Text('Versie'),
                  subtitle: Text('1.0.0'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  void _showLanguageSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kies een taal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('Nederlands'),
            _buildLanguageOption('English'),
            _buildLanguageOption('Français'),
            _buildLanguageOption('Deutsch'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuleren'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLanguageOption(String language) {
    return ListTile(
      title: Text(language),
      leading: Radio<String>(
        value: language,
        groupValue: _selectedLanguage,
        activeColor: AppColors.primaryStart,
        onChanged: (value) {
          setState(() {
            _selectedLanguage = value!;
          });
          _saveSettings();
          Navigator.of(context).pop();
        },
      ),
      onTap: () {
        setState(() {
          _selectedLanguage = language;
        });
        _saveSettings();
        Navigator.of(context).pop();
      },
    );
  }
}