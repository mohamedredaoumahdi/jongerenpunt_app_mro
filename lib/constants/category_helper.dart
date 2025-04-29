import 'package:flutter/material.dart';

/// Helper class for category-related utilities
class CategoryHelper {
  /// Get a consistent color based on category title
  static Color getCategoryFallbackColor(String categoryTitle) {
    // Simple hash function to generate a consistent number from a string
    int hash = 0;
    for (var i = 0; i < categoryTitle.length; i++) {
      hash = categoryTitle.codeUnitAt(i) + ((hash << 5) - hash);
    }
    
    // Convert to RGB color with a more muted palette based on the primary color
    final int r = ((hash & 0xFF0000) >> 16) % 100 + 40;  // 40-140 range for red
    final int g = ((hash & 0x00FF00) >> 8) % 100 + 50;   // 50-150 range for green
    final int b = (hash & 0x0000FF) % 100 + 70;          // 70-170 range for blue
    
    return Color.fromRGBO(r, g, b, 1.0);
  }
  
  /// Map category IDs to their respective placeholder images
  static final Map<String, String> _categoryPlaceholders = {
    'financien': 'https://images.unsplash.com/photo-1567427017947-545c5f96d209?auto=format&fit=crop&w=800&q=80',
    'gezondheid': 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?auto=format&fit=crop&w=800&q=80',
    'studie_stage': 'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?auto=format&fit=crop&w=800&q=80',
    'vrije_tijd': 'https://images.unsplash.com/photo-1533107862482-0e6974b06ec4?auto=format&fit=crop&w=800&q=80',
    'wonen': 'https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&w=800&q=80',
    'juridisch': 'https://images.unsplash.com/photo-1589994965851-a8f479c573a9?auto=format&fit=crop&w=800&q=80',
    'ondernemen': 'https://images.unsplash.com/photo-1519389950473-47ba0277781c?auto=format&fit=crop&w=800&q=80',
    'veiligheid': 'https://images.unsplash.com/photo-1503551723145-6c040742065b?auto=format&fit=crop&w=800&q=80',
    'discriminatie': 'https://images.unsplash.com/photo-1566997694904-6502f9a95811?auto=format&fit=crop&w=800&q=80',
    '18_worden': 'https://images.unsplash.com/photo-1513151233558-d860c5398176?auto=format&fit=crop&w=800&q=80',
  };
  
  /// Default placeholder image for all categories
  static const String _defaultPlaceholder = 'https://images.unsplash.com/photo-1507608616759-54f48f0af0ee?auto=format&fit=crop&w=800&q=80';
  
  /// Get reliable placeholder images - uses local assets as fallback
  static String getCategoryPlaceholderImage(String categoryId) {
    // First normalize the category ID to handle inconsistencies
    final normalizedId = _normalizeId(categoryId);

    
    // Return placeholder from map or default if not found
    return _categoryPlaceholders[normalizedId] ?? _defaultPlaceholder;
  }
  
  /// Normalize category ID to handle format variations
  static String _normalizeId(String categoryId) {
    // Convert to lowercase
    String id = categoryId.toLowerCase();
    
    // Handle common variations
    if (id.contains('vrije') || id.contains('leisure')) {
      return 'vrije_tijd';
    } else if (id.contains('finan')) {
      return 'financien';
    } else if (id.contains('gezond') || id.contains('health')) {
      return 'gezondheid';
    } else if (id.contains('stud') || id.contains('school')) {
      return 'studie_stage';
    } else if (id.contains('wonen') || id.contains('hous')) {
      return 'wonen';
    } else if (id.contains('juri') || id.contains('legal')) {
      return 'juridisch';
    } else if (id.contains('ondernemen') || id.contains('business')) {
      return 'ondernemen';
    } else if (id.contains('veilig') || id.contains('safe')) {
      return 'veiligheid';
    } else if (id.contains('discr')) {
      return 'discriminatie';
    } else if (id.contains('18') || id.contains('volwassen')) {
      return '18_worden';
    }
    
    // Return original if no match
    return id;
  }
  
  /// Get appropriate icon data for a category
  static IconData getCategoryIconData(String iconName) {
    // Map icon string names from Firestore to Flutter IconData
    switch (iconName.toLowerCase()) {
      case 'money':
        return Icons.attach_money;
      case 'health':
        return Icons.favorite;
      case 'school':
        return Icons.school;
      case 'leisure':
        return Icons.sports_soccer;
      case 'work':
        return Icons.work;
      case 'housing':
        return Icons.home;
      case 'legal':
        return Icons.gavel;
      case 'business':
        return Icons.business;
      case 'safety':
        return Icons.security;
      case 'discrimination':
        return Icons.pan_tool;
      case 'general':
        return Icons.info;
      case 'turning18':
        return Icons.cake;
      default:
        return Icons.category;
    }
  }
}