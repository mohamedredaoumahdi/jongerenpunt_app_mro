import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jongerenpunt_app/constants/app_theme.dart';
import 'package:jongerenpunt_app/constants/category_helper.dart';
import 'package:jongerenpunt_app/models/category.dart' as categorys;
import 'package:flutter/foundation.dart';

class CategoryCard extends StatelessWidget {
  final categorys.Category category;
  final VoidCallback onTap;

  // Static set to track which image errors have already been logged
  // This prevents multiple logs for the same image URL
  static final Set<String> _loggedImageErrors = <String>{};

  const CategoryCard({
    Key? key,
    required this.category,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.0),
            child: Stack(
              children: [
                // Use immediate fallback if we know image is problematic
                Positioned.fill(
                  child: _shouldUseDirectFallback(category.image)
                      ? _buildFallbackContainer(category)
                      : _buildCategoryImage(category),
                ),
                
                // Gradient overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Category title and icon
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Category icon
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryStart.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      CategoryHelper.getCategoryIconData(category.icon),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Check if we should skip trying to load the image
  bool _shouldUseDirectFallback(String imageUrl) {
    // If image URL is empty, use fallback
    if (imageUrl.isEmpty) {
      return true;
    }
    
    // If we've already seen this error, use fallback immediately
    if (_loggedImageErrors.contains(imageUrl)) {
      return true;
    }
    
    return false;
  }
  
  Widget _buildCategoryImage(categorys.Category category) {
    return CachedNetworkImage(
      imageUrl: category.image,
      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      errorWidget: (context, url, error) {
        // Only log the error once per URL
        if (!_loggedImageErrors.contains(url)) {
          if (kDebugMode) {
            print('Error loading image for category ${category.title}: $error - Will use fallback');
          }
          _loggedImageErrors.add(url);
        }
        
        return _buildFallbackContainer(category);
      },
      fit: BoxFit.cover,
    );
  }

  // Helper method to create a fallback container with consistent styling
  Widget _buildFallbackContainer(categorys.Category category) {
    Color fallbackColor = CategoryHelper.getCategoryFallbackColor(category.title);
    
    return Container(
      color: fallbackColor,
      child: Center(
        child: Icon(
          CategoryHelper.getCategoryIconData(category.icon),
          color: Colors.white.withOpacity(0.3),
          size: 48,
        ),
      ),
    );
  }
}