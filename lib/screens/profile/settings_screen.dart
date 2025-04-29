import 'package:flutter/material.dart';
import 'package:jongerenpunt_app/constants/app_theme.dart';
import 'package:jongerenpunt_app/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jongerenpunt_app/services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;
  bool _isDarkModeEnabled = false;
  bool _isNotificationsEnabled = true;
  String _selectedLanguage = 'Nederlands';
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _isDarkModeEnabled = prefs.getBool('dark_mode_enabled') ?? false;
        _isNotificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _selectedLanguage = prefs.getString('language') ?? 'Nederlands';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading settings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _setDarkMode(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dark_mode_enabled', value);
      setState(() {
        _isDarkModeEnabled = value;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value 
                ? 'Donker thema ingeschakeld (herstart de app om te zien)'
                : 'Licht thema ingeschakeld (herstart de app om te zien)',
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error setting dark mode: $e');
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
  
  Future<void> _setLanguage(String language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', language);
      setState(() {
        _selectedLanguage = language;
      });
      
      // Show information about language change
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Taal gewijzigd naar $language (herstart de app om te zien)',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error setting language: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isAnonymous = authService.isAnonymous;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instellingen', style: TextStyle(color : Colors.white),),
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profiel bewerken functionaliteit wordt binnenkort toegevoegd'),
                            ),
                          );
                        },
                      ),
                      
                      const Divider(),
                      
                      // Change password (only for registered users)
                      if (!isAnonymous)
                        ListTile(
                          leading: const Icon(Icons.lock, color: AppColors.primaryStart),
                          title: const Text('Wachtwoord wijzigen'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            try {
                              await authService.resetPassword(authService.currentUser?.email ?? '');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('E-mail voor wachtwoord wijzigen is verzonden'),
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
                          },
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
                        onChanged: (value) async {
                          await _setDarkMode(value);
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
                          // This would typically open a WebView or navigate to a privacy policy screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Privacybeleid wordt binnenkort toegevoegd'),
                            ),
                          );
                        },
                      ),
                      
                      const Divider(),
                      
                      // Terms and conditions
                      ListTile(
                        leading: const Icon(Icons.description, color: AppColors.primaryStart),
                        title: const Text('Gebruiksvoorwaarden'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // This would typically open a WebView or navigate to a terms screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Gebruiksvoorwaarden worden binnenkort toegevoegd'),
                            ),
                          );
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
        onChanged: (value) async {
          if (value != null) {
            await _setLanguage(value);
            Navigator.of(context).pop();
          }
        },
      ),
      onTap: () async {
        await _setLanguage(language);
        Navigator.of(context).pop();
      },
    );
  }
}