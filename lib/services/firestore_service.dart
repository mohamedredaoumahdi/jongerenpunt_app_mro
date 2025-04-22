import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jongerenpunt_app/models/category.dart';
import 'package:jongerenpunt_app/models/subcategory.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get all categories
  Stream<List<Category>> getCategories() {
    return _firestore
        .collection('categories')
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Category.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }
  
  // Get specific category by ID
  Future<Category> getCategoryById(String categoryId) async {
    DocumentSnapshot doc = await _firestore.collection('categories').doc(categoryId).get();
    return Category.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }
  
  // Get subcategories for a specific category
  Stream<List<Subcategory>> getSubcategoriesByCategory(String categoryId) {
    return _firestore
        .collection('subcategories')
        .where('categoryId', isEqualTo: categoryId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Subcategory.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }
  
  // Get specific subcategory by ID
  Future<Subcategory> getSubcategoryById(String subcategoryId) async {
    DocumentSnapshot doc = await _firestore.collection('subcategories').doc(subcategoryId).get();
    return Subcategory.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }
  
  // Search categories and subcategories
  Future<Map<String, dynamic>> searchContent(String query) async {
    query = query.toLowerCase();
    
    // Search categories
    QuerySnapshot categorySnapshot = await _firestore
        .collection('categories')
        .get();
    
    List<Category> matchingCategories = categorySnapshot.docs
        .map((doc) => Category.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .where((category) => 
            category.title.toLowerCase().contains(query))
        .toList();
    
    // Search subcategories
    QuerySnapshot subcategorySnapshot = await _firestore
        .collection('subcategories')
        .get();
    
    List<Subcategory> matchingSubcategories = subcategorySnapshot.docs
        .map((doc) => Subcategory.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .where((subcategory) => 
            subcategory.title.toLowerCase().contains(query) || 
            (subcategory.description != null && 
             subcategory.description!.toLowerCase().contains(query)))
        .toList();
    
    return {
      'categories': matchingCategories,
      'subcategories': matchingSubcategories,
    };
  }
  
  // Save user preferences
  Future<void> saveUserPreferences(String userId, List<String> favoriteCategories) async {
    await _firestore.collection('users').doc(userId).update({
      'profileData.favoriteCategories': favoriteCategories,
    });
  }
  
  // Get user preferences
  Future<List<String>> getUserPreferences(String userId) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    if (data.containsKey('profileData') && 
        data['profileData'] is Map && 
        data['profileData'].containsKey('favoriteCategories')) {
      return List<String>.from(data['profileData']['favoriteCategories']);
    }
    
    return [];
  }
}