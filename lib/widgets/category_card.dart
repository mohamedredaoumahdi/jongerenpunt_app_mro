import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jongerenpunt_app/constants/app_theme.dart';
import 'package:jongerenpunt_app/constants/category_helper.dart';
import 'package:jongerenpunt_app/models/category.dart' as categorys;
import 'package:flutter/foundation.dart';

class CategoryCard extends StatelessWidget {
  final categorys.Category category;
  final VoidCallback onTap;

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
                // Category image - Using a fallback image or color if image fails to load
                Positioned.fill(
                  child: _buildCategoryImage(category),
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
  
  Widget _buildCategoryImage( categorys.Category category) {
    // Using a replacement color and icon for fallback
    Color fallbackColor = CategoryHelper.getCategoryFallbackColor(category.title);
    
    // If the image URL is empty, directly use the fallback
    if (category.image.isEmpty) {
      return Container(
        color: fallbackColor,
        child: Center(
          child: Icon(
            CategoryHelper.getCategoryIconData(category.icon),
            color: Colors.white.withOpacity(0.2),
            size: 48,
          ),
        ),
      );
    }
    
    // Try to use the original URL first
    return CachedNetworkImage(
      imageUrl: category.image,
      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      errorWidget: (context, url, error) {
        if (kDebugMode) {
          print('Error loading image for category ${category.title}: $error');
        }
        
        // Try using a placeholder image if the original fails
        String placeholderUrl = CategoryHelper.getCategoryPlaceholderImage(category.id);
        
        return CachedNetworkImage(
          imageUrl: placeholderUrl,
          placeholder: (context, url) => Container(
            color: fallbackColor,
            child: Center(
              child: Icon(
                CategoryHelper.getCategoryIconData(category.icon),
                color: Colors.white.withOpacity(0.2),
                size: 48,
              ),
            ),
          ),
          errorWidget: (context, url, error) {
            // If both image sources fail, use a colored fallback
            if (kDebugMode) {
              print('Error loading placeholder image for category ${category.title}: $error');
            }
            
            return Container(
              color: fallbackColor,
              child: Center(
                child: Icon(
                  CategoryHelper.getCategoryIconData(category.icon),
                  color: Colors.white.withOpacity(0.2),
                  size: 48,
                ),
              ),
            );
          },
          fit: BoxFit.cover,
        );
      },
      fit: BoxFit.cover,
    );
  }
}