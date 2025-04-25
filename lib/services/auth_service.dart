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
      
      // More specific error handling
      switch (e.code) {
        case 'weak-password':
          throw 'Het wachtwoord is te zwak. Kies een sterker wachtwoord.';
        case 'email-already-in-use':
          throw 'Dit e-mailadres is al in gebruik.';
        case 'invalid-email':
          throw 'Ongeldig e-mailadres.';
        case 'operation-not-allowed':
          throw 'E-mail/wachtwoord accounts zijn niet ingeschakeld.';
        case 'network-request-failed':
          throw 'Netwerkverbinding mislukt. Controleer je internetverbinding.';
        default:
          throw 'Registratie mislukt: ${e.message ?? e.code}';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error during registration: $e');
      }
      throw 'Er is een onverwachte fout opgetreden: $e';
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
      
      // More specific error handling
      switch (e.code) {
        case 'user-not-found':
          throw 'Geen gebruiker gevonden met dit e-mailadres.';
        case 'wrong-password':
          throw 'Ongeldig wachtwoord.';
        case 'user-disabled':
          throw 'Deze gebruiker is uitgeschakeld.';
        case 'too-many-requests':
          throw 'Te veel inlogpogingen. Probeer het later opnieuw.';
        case 'operation-not-allowed':
          throw 'E-mail/wachtwoord accounts zijn niet ingeschakeld.';
        case 'invalid-email':
          throw 'Ongeldig e-mailadres.';
        case 'network-request-failed':
          throw 'Netwerkverbinding mislukt. Controleer je internetverbinding.';
        default:
          throw 'Inloggen mislukt: ${e.message ?? e.code}';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error during sign in: $e');
      }
      throw 'Er is een onverwachte fout opgetreden: $e';
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
      throw 'Anoniem inloggen mislukt: ${e.message ?? 'Onbekende fout'}';
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error during anonymous sign in: $e');
      }
      throw 'Er is een onverwachte fout opgetreden: $e';
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
      throw 'Uitloggen mislukt: $e';
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
          throw 'Ongeldig e-mailadres.';
        case 'user-not-found':
          throw 'Geen gebruiker gevonden met dit e-mailadres.';
        case 'network-request-failed':
          throw 'Netwerkverbinding mislukt. Controleer je internetverbinding.';
        default:
          throw 'Wachtwoord resetten mislukt: ${e.message ?? e.code}';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error during password reset: $e');
      }
      throw 'Er is een onverwachte fout opgetreden: $e';
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
        throw 'Geen gebruiker ingelogd om te converteren.';
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
          throw 'Dit e-mailadres is al in gebruik.';
        case 'invalid-credential':
          throw 'Ongeldige referenties.';
        case 'weak-password':
          throw 'Het wachtwoord is te zwak. Kies een sterker wachtwoord.';
        case 'operation-not-allowed':
          throw 'Deze bewerking is niet toegestaan.';
        case 'provider-already-linked':
          throw 'Account is al gekoppeld aan een andere provider.';
        case 'network-request-failed':
          throw 'Netwerkverbinding mislukt. Controleer je internetverbinding.';
        default:
          throw 'Account converteren mislukt: ${e.message ?? e.code}';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error during account conversion: $e');
      }
      throw 'Er is een onverwachte fout opgetreden bij het converteren: $e';
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
        'profileData': {
          'favoriteCategories': [],
        },
      }, SetOptions(merge: true));
      
      if (kDebugMode) {
        print('User document created successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating user document: $e');
      }
      throw 'Gebruikersdocument aanmaken mislukt: $e';
    }
  }
  
  // Update user document in Firestore
  Future<void> _updateUserDocument(User user, {bool? isAnonymous}) async {
    try {
      Map<String, dynamic> data = {};
      
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
      throw 'Gebruikersdocument bijwerken mislukt: $e';
    }
  }
  
  // Update user profile data
  Future<void> updateUserProfile(Map<String, dynamic> profileData) async {
    try {
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser!.uid).update({
          'profileData': profileData,
        });
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user profile: $e');
      }
      throw 'Profiel bijwerken mislukt: $e';
    }
  }
}