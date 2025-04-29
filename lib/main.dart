import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:jongerenpunt_app/firebase_options.dart';
import 'package:jongerenpunt_app/screens/auth/register_screen.dart';
import 'package:jongerenpunt_app/screens/help/contact_screen.dart';
import 'package:jongerenpunt_app/screens/help/faq_screen.dart';
import 'package:jongerenpunt_app/screens/profile/edit_profile_screen.dart';
import 'package:jongerenpunt_app/screens/splash/splash_screen.dart';
import 'package:jongerenpunt_app/constants/app_theme.dart';
import 'package:jongerenpunt_app/services/contact_service.dart';
import 'package:jongerenpunt_app/services/storage_service.dart';
import 'package:provider/provider.dart';
import 'package:jongerenpunt_app/services/auth_service.dart';
import 'package:jongerenpunt_app/services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:jongerenpunt_app/services/settings_service.dart';
import 'package:jongerenpunt_app/services/chat_service.dart';

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
        ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider<SettingsProvider>(create: (_) => SettingsProvider()),
        ChangeNotifierProvider<ChatService>(create: (_) => ChatService()),
        Provider<StorageService>(create: (_) => StorageService()),
        Provider<ContactService>(create: (_) => ContactService()),
      ],
      child: const JongerenpuntApp(),
    ),
  );
}

class JongerenpuntApp extends StatefulWidget {
  const JongerenpuntApp({Key? key}) : super(key: key);

  @override
  State<JongerenpuntApp> createState() => _JongerenpuntAppState();
}

class _JongerenpuntAppState extends State<JongerenpuntApp> {
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }
  
  Future<void> _initializeServices() async {
    try {
      // Load settings when app starts
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      await settingsProvider.loadSettings();
      
      // Initialize chat service
      final chatService = Provider.of<ChatService>(context, listen: false);
      await chatService.loadChatHistory();
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing services: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    
    return MaterialApp(
      title: 'Jongerenpunt',
      debugShowCheckedModeBanner: false,
      theme: settingsProvider.isDarkModeEnabled 
          ? AppTheme.darkTheme  // You'll need to implement this
          : AppTheme.lightTheme,
      home: const SplashScreen(),
      routes: {
        '/register': (context) => const RegisterScreen(),
        '/edit_profile': (context) => const EditProfileScreen(),
        '/faq': (context) => const FAQScreen(),
        '/contact': (context) => const ContactScreen(),
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