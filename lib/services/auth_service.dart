import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? get currentUser => _auth.currentUser;
  Stream<User?> get userStream => _auth.authStateChanges();
  bool get isAuthenticated => currentUser != null;
  bool get isAnonymous => currentUser?.isAnonymous ?? false;
  
  // Register with email and password
  Future<User?> registerWithEmailAndPassword(String email, String password) async {
    try {
      // Print debug info
      if (kDebugMode) {
        print('Attempting to register with email: $email');
      }
      
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      User? user = result.user;
      
      if (user != null) {
        // Create user document in Firestore
        try {
          await _createUserDocument(user, isAnonymous: false);
        } catch (e) {
          if (kDebugMode) {
            print('Error creating user document: $e');
          }
          // Continue even if document creation fails
        }
      }
      
      notifyListeners();
      return user;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Firebase Auth Error: ${e.code} - ${e.message}');
      }
      
      // More user-friendly error messages
      switch (e.code) {
        case 'weak-password':
          throw 'Het wachtwoord is te zwak. Kies een sterker wachtwoord.';
        case 'email-already-in-use':
          throw 'Dit e-mailadres is al in gebruik. Probeer in te loggen of gebruik een ander e-mailadres.';
        case 'invalid-email':
          throw 'Ongeldig e-mailadres. Controleer of je het juiste e-mailadres hebt ingevoerd.';
        case 'operation-not-allowed':
          throw 'Registratie met e-mail/wachtwoord is momenteel niet mogelijk. Probeer het later opnieuw.';
        case 'network-request-failed':
          throw 'Netwerkverbinding mislukt. Controleer je internetverbinding en probeer het opnieuw.';
        default:
          throw 'Registratie mislukt: ${e.message ?? "Onbekende fout"}';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error during registration: $e');
      }
      throw 'Er is een onverwachte fout opgetreden. Probeer het later opnieuw.';
    }
  }
  
  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      if (kDebugMode) {
        print('Attempting to sign in with email: $email');
      }
      
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      notifyListeners();
      return result.user;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Firebase Auth Error: ${e.code} - ${e.message}');
      }
      
      // More user-friendly error messages
      switch (e.code) {
        case 'user-not-found':
          throw 'Geen gebruiker gevonden met dit e-mailadres. Controleer je e-mailadres of maak een nieuw account aan.';
        case 'wrong-password':
          throw 'Onjuist wachtwoord. Probeer het opnieuw of reset je wachtwoord.';
        case 'user-disabled':
          throw 'Dit account is uitgeschakeld. Neem contact op met de klantenservice.';
        case 'too-many-requests':
          throw 'Te veel inlogpogingen. Wacht even en probeer het later opnieuw.';
        case 'operation-not-allowed':
          throw 'Inloggen met e-mail/wachtwoord is momenteel niet mogelijk. Probeer het later opnieuw.';
        case 'invalid-email':
          throw 'Ongeldig e-mailadres. Controleer of je het juiste e-mailadres hebt ingevoerd.';
        case 'network-request-failed':
          throw 'Netwerkverbinding mislukt. Controleer je internetverbinding en probeer het opnieuw.';
        default:
          throw 'Inloggen mislukt: ${e.message ?? "Onbekende fout"}';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error during sign in: $e');
      }
      throw 'Er is een onverwachte fout opgetreden. Probeer het later opnieuw.';
    }
  }
  
  // Sign in anonymously
  Future<User?> signInAnonymously() async {
    try {
      UserCredential result = await _auth.signInAnonymously();
      User? user = result.user;
      
      if (user != null) {
        // Create user document in Firestore
        try {
          await _createUserDocument(user, isAnonymous: true);
        } catch (e) {
          if (kDebugMode) {
            print('Error creating anonymous user document: $e');
          }
          // Continue even if document creation fails
        }
      }
      
      notifyListeners();
      return user;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Firebase Auth Error: ${e.code} - ${e.message}');
      }
      throw 'Anoniem inloggen mislukt. Probeer het later opnieuw.';
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error during anonymous sign in: $e');
      }
      throw 'Er is een onverwachte fout opgetreden. Probeer het later opnieuw.';
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error signing out: $e');
      }
      throw 'Uitloggen mislukt. Probeer het later opnieuw.';
    }
  }
  
  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Firebase Auth Error: ${e.code} - ${e.message}');
      }
      
      switch (e.code) {
        case 'invalid-email':
          throw 'Ongeldig e-mailadres. Controleer of je het juiste e-mailadres hebt ingevoerd.';
        case 'user-not-found':
          throw 'Geen gebruiker gevonden met dit e-mailadres. Controleer je e-mailadres of maak een nieuw account aan.';
        case 'network-request-failed':
          throw 'Netwerkverbinding mislukt. Controleer je internetverbinding en probeer het opnieuw.';
        default:
          throw 'Wachtwoord resetten mislukt: ${e.message ?? "Onbekende fout"}';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error during password reset: $e');
      }
      throw 'Er is een onverwachte fout opgetreden. Probeer het later opnieuw.';
    }
  }
  
  // Convert anonymous account to permanent account
  Future<User?> convertAnonymousUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      if (currentUser == null) {
        if (kDebugMode) {
          print('No user currently signed in');
        }
        throw 'Je bent niet ingelogd. Log eerst in om een account aan te maken.';
      }
      
      if (!currentUser!.isAnonymous) {
        if (kDebugMode) {
          print('User is not anonymous: ${currentUser!.uid}, isAnonymous: ${currentUser!.isAnonymous}');
        }
        // If user is already a non-anonymous user, just return it without trying to convert
        return currentUser;
      }
      
      if (kDebugMode) {
        print('Converting anonymous user to permanent account: ${currentUser!.uid}');
      }
      
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      
      UserCredential result = await currentUser!.linkWithCredential(credential);
      
      if (kDebugMode) {
        print('Successfully linked credential, updating user document');
      }
      
      // Update user document in Firestore
      try {
        await _updateUserDocument(result.user!, isAnonymous: false);
      } catch (e) {
        if (kDebugMode) {
          print('Error updating user document after conversion: $e');
        }
        // Continue even if document update fails
      }
      
      notifyListeners();
      return result.user;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Firebase Auth Error during conversion: ${e.code} - ${e.message}');
      }
      
      switch (e.code) {
        case 'email-already-in-use':
          throw 'Dit e-mailadres is al in gebruik. Log in met dit e-mailadres of gebruik een ander e-mailadres.';
        case 'invalid-credential':
          throw 'Ongeldige gegevens. Controleer je e-mailadres en wachtwoord.';
        case 'weak-password':
          throw 'Het wachtwoord is te zwak. Kies een sterker wachtwoord.';
        case 'operation-not-allowed':
          throw 'Deze functie is momenteel niet beschikbaar. Probeer het later opnieuw.';
        case 'provider-already-linked':
          throw 'Dit account is al gekoppeld aan een e-mailadres.';
        case 'network-request-failed':
          throw 'Netwerkverbinding mislukt. Controleer je internetverbinding en probeer het opnieuw.';
        default:
          throw 'Account converteren mislukt: ${e.message ?? "Onbekende fout"}';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error during account conversion: $e');
      }
      throw 'Er is een onverwachte fout opgetreden. Probeer het later opnieuw.';
    }
  }
  
  // Create user document in Firestore
  Future<void> _createUserDocument(User user, {bool isAnonymous = false}) async {
    try {
      if (kDebugMode) {
        print('Creating user document for: ${user.uid}, isAnonymous: $isAnonymous');
      }
      
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email ?? '',
        'anonymous': isAnonymous,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'profileData': {
          'favoriteCategories': [],
          'username': user.email?.split('@').first ?? 'Gebruiker',
        },
      }, SetOptions(merge: true));
      
      if (kDebugMode) {
        print('User document created successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating user document: $e');
      }
      throw 'Gebruikersprofiel aanmaken mislukt. Je kunt nog steeds inloggen, maar sommige functies werken mogelijk niet correct.';
    }
  }
  
  // Update user document in Firestore
  Future<void> _updateUserDocument(User user, {bool? isAnonymous}) async {
    try {
      Map<String, dynamic> data = {
        'lastLogin': FieldValue.serverTimestamp(),
      };
      
      if (isAnonymous != null) {
        data['anonymous'] = isAnonymous;
      }
      
      if (user.email != null) {
        data['email'] = user.email;
      }
      
      if (data.isNotEmpty) {
        if (kDebugMode) {
          print('Updating user document: ${user.uid} with data: $data');
        }
        
        await _firestore.collection('users').doc(user.uid).update(data);
        
        if (kDebugMode) {
          print('User document updated successfully');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user document: $e');
      }
      // Non-critical error, don't throw
    }
  }
  
  // Update user profile data
  // Update user profile with better error handling and more fields
  Future<void> updateUserProfile(Map<String, dynamic> profileData) async {
    try {
      if (currentUser == null) {
        throw Exception('Je bent niet ingelogd');
      }
      
      // Validate data
      if (profileData.containsKey('username') && (profileData['username'] == null || profileData['username'].isEmpty)) {
        throw Exception('Gebruikersnaam mag niet leeg zijn');
      }
      
      // Get current profile data first
      DocumentSnapshot doc = await _firestore.collection('users').doc(currentUser!.uid).get();
      Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
      Map<String, dynamic> currentProfileData = userData.containsKey('profileData') ? 
          (userData['profileData'] as Map<String, dynamic>) : {};
          
      // Merge new profile data with existing data
      Map<String, dynamic> updatedProfileData = {
        ...currentProfileData,
        ...profileData,
      };
      
      // Update the user document
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'profileData': updatedProfileData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      notifyListeners();
      
      if (kDebugMode) {
        print('User profile updated successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user profile: $e');
      }
      throw Exception('Fout bij het bijwerken van je profiel: ${e.toString()}');
    }
  }
  
  // Update user email
  Future<void> updateEmail(String newEmail, String password) async {
    try {
      if (currentUser == null) {
        throw 'Je bent niet ingelogd.';
      }
      
      // Re-authenticate user first
      AuthCredential credential = EmailAuthProvider.credential(
        email: currentUser!.email!, 
        password: password
      );
      
      await currentUser!.reauthenticateWithCredential(credential);
      
      // Update email
      await currentUser!.updateEmail(newEmail);
      
      // Update user document in Firestore
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'email': newEmail,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Firebase Auth Error during email update: ${e.code} - ${e.message}');
      }
      
      switch (e.code) {
        case 'requires-recent-login':
          throw 'Je moet opnieuw inloggen om je e-mailadres te wijzigen. Log uit en dan weer in.';
        case 'invalid-credential':
          throw 'Onjuist wachtwoord. Controleer je wachtwoord.';
        case 'email-already-in-use':
          throw 'Dit e-mailadres is al in gebruik. Kies een ander e-mailadres.';
        case 'invalid-email':
          throw 'Ongeldig e-mailadres. Controleer of je het juiste e-mailadres hebt ingevoerd.';
        default:
          throw 'E-mailadres bijwerken mislukt: ${e.message ?? "Onbekende fout"}';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error during email update: $e');
      }
      throw 'Er is een onverwachte fout opgetreden. Probeer het later opnieuw.';
    }
  }
  
  // Update user password
  Future<void> updatePassword(String currentPassword, String newPassword) async {
    try {
      if (currentUser == null || currentUser!.email == null) {
        throw 'Je bent niet ingelogd of gebruikt een anoniem account.';
      }
      
      // Re-authenticate user first
      AuthCredential credential = EmailAuthProvider.credential(
        email: currentUser!.email!, 
        password: currentPassword
      );
      
      await currentUser!.reauthenticateWithCredential(credential);
      
      // Update password
      await currentUser!.updatePassword(newPassword);
      
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Firebase Auth Error during password update: ${e.code} - ${e.message}');
      }
      
      switch (e.code) {
        case 'requires-recent-login':
          throw 'Je moet opnieuw inloggen om je wachtwoord te wijzigen. Log uit en dan weer in.';
        case 'invalid-credential':
          throw 'Onjuist wachtwoord. Controleer je huidige wachtwoord.';
        case 'weak-password':
          throw 'Het nieuwe wachtwoord is te zwak. Kies een sterker wachtwoord.';
        default:
          throw 'Wachtwoord bijwerken mislukt: ${e.message ?? "Onbekende fout"}';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error during password update: $e');
      }
      throw 'Er is een onverwachte fout opgetreden. Probeer het later opnieuw.';
    }
  }
  
  // Check if email is already in use
  Future<bool> isEmailAlreadyInUse(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking if email is in use: $e');
      }
      return false; // Default to false on error to allow registration attempt
    }
  }

  // These methods should be added to the AuthService class in lib/services/auth_service.dart

  // Get user profile data
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      if (currentUser == null) {
        throw Exception('Je bent niet ingelogd');
      }
      
      DocumentSnapshot doc = await _firestore.collection('users').doc(currentUser!.uid).get();
      
      if (!doc.exists) {
        // Create default profile if it doesn't exist
        await _createUserDocument(currentUser!, isAnonymous: currentUser!.isAnonymous);
        doc = await _firestore.collection('users').doc(currentUser!.uid).get();
      }
      
      Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
      
      // Ensure profileData exists
      if (!userData.containsKey('profileData') || userData['profileData'] == null) {
        userData['profileData'] = {
          'username': currentUser!.email?.split('@').first ?? 'Gebruiker',
          'favoriteCategories': [],
          'interests': [],
          'bio': '',
          'profileImage': null,
        };
        
        // Update user document with default profile data
        await _firestore.collection('users').doc(currentUser!.uid).update({
          'profileData': userData['profileData'],
        });
      }
      
      // Return profile data with defaults for missing fields
      Map<String, dynamic> profileData = userData['profileData'] as Map<String, dynamic>;
      
      return {
        'username': profileData['username'] ?? currentUser!.email?.split('@').first ?? 'Gebruiker',
        'favoriteCategories': List<String>.from(profileData['favoriteCategories'] ?? []),
        'interests': List<String>.from(profileData['interests'] ?? []),
        'bio': profileData['bio'] ?? '',
        'profileImage': profileData['profileImage'],
        'email': currentUser!.email,
        'isAnonymous': currentUser!.isAnonymous,
        'createdAt': userData['createdAt'],
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user profile: $e');
      }
      throw Exception('Fout bij het ophalen van je profiel: ${e.toString()}');
    }
  }
  
  
  
  // Get user favorite categories
  Future<List<String>> getFavoriteCategories() async {
    try {
      if (currentUser == null) {
        return [];
      }
      
      DocumentSnapshot doc = await _firestore.collection('users').doc(currentUser!.uid).get();
      
      if (!doc.exists) {
        return [];
      }
      
      Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
      
      if (!userData.containsKey('profileData') || 
          !(userData['profileData'] is Map) || 
          !userData['profileData'].containsKey('favoriteCategories')) {
        return [];
      }
      
      return List<String>.from(userData['profileData']['favoriteCategories']);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting favorite categories: $e');
      }
      return [];
    }
  }
  
  // Toggle favorite category
  Future<void> toggleFavoriteCategory(String categoryId) async {
    try {
      if (currentUser == null) {
        throw Exception('Je bent niet ingelogd');
      }
      
      // Get current favorites
      List<String> favorites = await getFavoriteCategories();
      
      // Toggle category
      if (favorites.contains(categoryId)) {
        favorites.remove(categoryId);
      } else {
        favorites.add(categoryId);
      }
      
      // Update in Firestore
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'profileData.favoriteCategories': favorites,
      });
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error toggling favorite category: $e');
      }
      throw Exception('Fout bij het bijwerken van je favorieten: ${e.toString()}');
    }
  }
  
  // Update user interests
  Future<void> updateUserInterests(List<String> interests) async {
    try {
      if (currentUser == null) {
        throw Exception('Je bent niet ingelogd');
      }
      
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'profileData.interests': interests,
      });
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user interests: $e');
      }
      throw Exception('Fout bij het bijwerken van je interesses: ${e.toString()}');
    }
  }
}