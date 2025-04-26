import 'package:flutter/material.dart';
import 'package:jongerenpunt_app/constants/app_theme.dart';
import 'package:jongerenpunt_app/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Create a ChangeNotifier to manage app settings
class SettingsProvider extends ChangeNotifier {
  bool _isDarkModeEnabled = false;
  bool _isNotificationsEnabled = true;
  String _selectedLanguage = 'Nederlands';
  
  bool get isDarkModeEnabled => _isDarkModeEnabled;
  bool get isNotificationsEnabled => _isNotificationsEnabled;
  String get selectedLanguage => _selectedLanguage;
  
  // Initialize settings from SharedPreferences
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _isDarkModeEnabled = prefs.getBool('dark_mode_enabled') ?? false;
      _isNotificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _selectedLanguage = prefs.getString('language') ?? 'Nederlands';
      
      notifyListeners();
    } catch (e) {
      print('Error loading settings: $e');
    }
  }
  
  // Update dark mode setting
  Future<void> setDarkMode(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dark_mode_enabled', value);
      _isDarkModeEnabled = value;
      notifyListeners();
    } catch (e) {
      print('Error setting dark mode: $e');
    }
  }
  
  // Update notifications setting
  Future<void> setNotifications(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', value);
      _isNotificationsEnabled = value;
      notifyListeners();
    } catch (e) {
      print('Error setting notifications: $e');
    }
  }
  
  // Update language setting
  Future<void> setLanguage(String language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', language);
      _selectedLanguage = language;
      notifyListeners();
    } catch (e) {
      print('Error setting language: $e');
    }
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    await settingsProvider.loadSettings();
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<SettingsProvider>(
              builder: (context, settings, _) {
                return ListView(
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
                            value: settings.isNotificationsEnabled,
                            activeColor: AppColors.primaryStart,
                            onChanged: (value) async {
                              await settings.setNotifications(value);
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
                            value: settings.isDarkModeEnabled,
                            activeColor: AppColors.primaryStart,
                            onChanged: (value) async {
                              await settings.setDarkMode(value);
                              // Note: In a real app with theme provider, you would update the app theme here
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    value 
                                        ? 'Donker thema ingeschakeld (herstart de app om te zien)'
                                        : 'Licht thema ingeschakeld (herstart de app om te zien)',
                                  ),
                                ),
                              );
                            },
                            secondary: const Icon(Icons.brightness_6, color: AppColors.primaryStart),
                          ),
                          
                          const Divider(),
                          
                          // Language selection
                          ListTile(
                            leading: const Icon(Icons.language, color: AppColors.primaryStart),
                            title: const Text('Taal'),
                            subtitle: Text(settings.selectedLanguage),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              _showLanguageSelectionDialog(settings);
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
                );
              },
            ),
    );
  }
  
  void _showLanguageSelectionDialog(SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kies een taal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('Nederlands', settings),
            _buildLanguageOption('English', settings),
            _buildLanguageOption('Français', settings),
            _buildLanguageOption('Deutsch', settings),
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
  
  Widget _buildLanguageOption(String language, SettingsProvider settings) {
    return ListTile(
      title: Text(language),
      leading: Radio<String>(
        value: language,
        groupValue: settings.selectedLanguage,
        activeColor: AppColors.primaryStart,
        onChanged: (value) async {
          if (value != null) {
            await settings.setLanguage(value);
            Navigator.of(context).pop();
            
            // Show information about language change
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Taal gewijzigd naar $value (herstart de app om te zien)',
                  ),
                ),
              );
            }
          }
        },
      ),
      onTap: () async {
        await settings.setLanguage(language);
        Navigator.of(context).pop();
        
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
      },
    );
  }
}