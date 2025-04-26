import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:jongerenpunt_app/firebase_options.dart';
import 'package:jongerenpunt_app/screens/auth/register_screen.dart';
import 'package:jongerenpunt_app/screens/splash/splash_screen.dart';
import 'package:jongerenpunt_app/constants/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:jongerenpunt_app/services/auth_service.dart';
import 'package:jongerenpunt_app/services/notification_service.dart';
import 'package:flutter/foundation.dart';

// Import SettingsProvider from settings_screen.dart
// Note: You'll need to extract the SettingsProvider to a separate file
// For now, this assumes you've moved it to lib/services/settings_service.dart
import 'package:jongerenpunt_app/services/settings_service.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with error handling
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Configure Crashlytics - only if Firebase init was successful
    try {
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
    } catch (e) {
      if (kDebugMode) {
        print("Failed to initialize Crashlytics: $e");
      }
      // Continue app initialization even if Crashlytics fails
    }
    
    // Initialize notification service
    try {
      await NotificationService().initialize();
    } catch (e) {
      if (kDebugMode) {
        print("Failed to initialize notification service: $e");
      }
      // Continue app initialization even if notifications fail
    }
  } catch (e) {
    if (kDebugMode) {
      print("Failed to initialize Firebase: $e");
    }
    // The app will still run, but Firebase features won't work
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const JongerenpuntApp(),
    ),
  );
}

class JongerenpuntApp extends StatelessWidget {
  const JongerenpuntApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    
    // Load settings when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      settingsProvider.loadSettings();
    });
    
    return MaterialApp(
      title: 'Jongerenpunt',
      debugShowCheckedModeBanner: false,
      theme: settingsProvider.isDarkModeEnabled 
          ? AppTheme.darkTheme  // You'll need to implement this
          : AppTheme.lightTheme,
      home: const SplashScreen(),
      routes: {
        '/register': (context) => const RegisterScreen(), // Create this import
      },
      builder: (context, child) {
        // This ensures error handling at the UI level
        ErrorWidget.builder = (FlutterErrorDetails details) {
          if (kDebugMode) {
            print('UI Error: ${details.exception}');
          }
          
          // Return a custom error widget in production
          return Container(
            color: Colors.white,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Er is iets misgegaan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      kDebugMode ? details.exception.toString() : 'Probeer het later opnieuw',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.lightText),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const SplashScreen()),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryStart,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Opnieuw proberen'),
                    ),
                  ],
                ),
              ),
            ),
          );
        };
        
        return child!;
      },
    );
  }
}