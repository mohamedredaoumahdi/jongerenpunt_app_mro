import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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