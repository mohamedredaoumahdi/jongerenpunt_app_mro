import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? get currentUser => _auth.currentUser;
  Stream<User?> get userStream => _auth.authStateChanges();
  bool get isAuthenticated => currentUser != null;
  bool get isAnonymous => currentUser?.isAnonymous ?? true;
  
  // Register with email and password
  Future<User?> registerWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      User? user = result.user;
      
      if (user != null) {
        // Create user document in Firestore with more comprehensive error handling
        await _createUserDocument(user, isAnonymous: false);
      }
      
      notifyListeners();
      return user;
    } on FirebaseAuthException catch (e) {
      // More specific error handling
      switch (e.code) {
        case 'weak-password':
          throw 'Het wachtwoord is te zwak. Kies een sterker wachtwoord.';
        case 'email-already-in-use':
          throw 'Dit e-mailadres is al in gebruik.';
        case 'invalid-email':
          throw 'Ongeldig e-mailadres.';
        default:
          throw 'Registratie mislukt. Probeer het opnieuw.';
      }
    } catch (e) {
      throw 'Er is een onverwachte fout opgetreden.';
    }
  }
  
  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      notifyListeners();
      return result.user;
    } on FirebaseAuthException catch (e) {
      // More specific error handling
      switch (e.code) {
        case 'user-not-found':
          throw 'Geen gebruiker gevonden met dit e-mailadres.';
        case 'wrong-password':
          throw 'Ongeldig wachtwoord.';
        case 'too-many-requests':
          throw 'Te veel inlogpogingen. Probeer het later opnieuw.';
        default:
          throw 'Inloggen mislukt. Controleer je gegevens.';
      }
    } catch (e) {
      throw 'Er is een onverwachte fout opgetreden.';
    }
  }
  
  // Sign in anonymously
  Future<User?> signInAnonymously() async {
    try {
      UserCredential result = await _auth.signInAnonymously();
      User? user = result.user;
      
      if (user != null) {
        // Create user document in Firestore
        await _createUserDocument(user, isAnonymous: true);
      }
      
      notifyListeners();
      return user;
    } on FirebaseAuthException catch (e) {
      throw 'Anoniem inloggen mislukt: ${e.message ?? 'Onbekende fout'}';
    } catch (e) {
      throw 'Er is een onverwachte fout opgetreden.';
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }
  
  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          throw 'Ongeldig e-mailadres.';
        case 'user-not-found':
          throw 'Geen gebruiker gevonden met dit e-mailadres.';
        default:
          throw 'Wachtwoord resetten mislukt. Probeer het opnieuw.';
      }
    } catch (e) {
      throw 'Er is een onverwachte fout opgetreden.';
    }
  }
  
  // Convert anonymous account to permanent account
  Future<User?> convertAnonymousUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      
      UserCredential result = await currentUser!.linkWithCredential(credential);
      
      // Update user document in Firestore
      await _updateUserDocument(result.user!, isAnonymous: false);
      
      notifyListeners();
      return result.user;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw 'Dit e-mailadres is al in gebruik.';
        case 'invalid-credential':
          throw 'Ongeldige referenties.';
        case 'operation-not-allowed':
          throw 'Deze bewerking is niet toegestaan.';
        default:
          throw 'Account converteren mislukt.';
      }
    } catch (e) {
      throw 'Er is een onverwachte fout opgetreden.';
    }
  }
  
  // Create user document in Firestore
  Future<void> _createUserDocument(User user, {bool isAnonymous = false}) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email ?? '',
        'anonymous': isAnonymous,
        'createdAt': FieldValue.serverTimestamp(),
        'profileData': {
          'favoriteCategories': [],
        },
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error creating user document: $e');
      throw 'Gebruikersdocument aanmaken mislukt.';
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
        await _firestore.collection('users').doc(user.uid).update(data);
      }
    } catch (e) {
      print('Error updating user document: $e');
      throw 'Gebruikersdocument bijwerken mislukt.';
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
      print('Error updating user profile: $e');
      throw 'Profiel bijwerken mislukt.';
    }
  }
}