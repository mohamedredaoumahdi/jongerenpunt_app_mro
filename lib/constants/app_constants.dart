import 'package:flutter/material.dart';

/// App-wide constants and configuration settings
class AppConstants {
  // App name
  static const String appName = 'Jongerenpunt';
  
  // App version
  static const String appVersion = '1.0.0';
  
  // Base URL for API
  static const String baseApiUrl = 'https://api.example.com';
  
  // OpenAI API Settings
  static const String openAIApiKey = ''; // Replace with actual key
  static const String openAIModel = 'gpt-4o'; // or gpt-4 if using that model
  static const int openAIMaxTokens = 1000; // Maximum tokens for response
  static const double openAITemperature = 0.7; // 0.0 = deterministic, 1.0 = creative
  
  // Chat settings
  static const int maxChatHistory = 20; // Maximum number of messages to store
  
  // System message that defines how the AI assistant should behave
  static const String chatSystemPrompt = '''
You are a helpful assistant for the Jongerenpunt app, which provides information for young people in The Netherlands.
You can help with information about finances, health, education, housing, work, and other topics related to youth services.
Be friendly, clear, and concise in your responses. 
If asked about something you don't know about, suggest the user check the specific category in the app.
Always respond in Dutch language.
''';

  // Local storage keys
  static const String storageChatHistory = 'chat_history';
  static const String storageUserPreferences = 'user_preferences';
  
  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration chatTimeout = Duration(seconds: 60);
}