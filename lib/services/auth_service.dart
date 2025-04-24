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
        // Create user document in Firestore
        await _createUserDocument(user);
      }
      
      notifyListeners();
      return user;
    } on FirebaseAuthException {
      rethrow;
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
    } on FirebaseAuthException {
      rethrow;
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
    } on FirebaseAuthException {
      rethrow;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }
  
  // Reset password
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
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
    } on FirebaseAuthException {
      rethrow;
    }
  }
  
  // Create user document in Firestore
  Future<void> _createUserDocument(User user, {bool isAnonymous = false}) async {
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email ?? '',
      'anonymous': isAnonymous,
      'createdAt': Timestamp.now(),
      'profileData': {},
    });
  }
  
  // Update user document in Firestore
  Future<void> _updateUserDocument(User user, {bool? isAnonymous}) async {
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
  }
  
  // Update user profile data
  Future<void> updateUserProfile(Map<String, dynamic> profileData) async {
    if (currentUser != null) {
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'profileData': profileData,
      });
      notifyListeners();
    }
  }
}