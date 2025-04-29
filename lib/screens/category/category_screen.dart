import 'package:flutter/material.dart';
import 'package:jongerenpunt_app/constants/app_theme.dart';
import 'package:jongerenpunt_app/constants/category_helper.dart';
import 'package:jongerenpunt_app/models/category.dart' as ctegories;
import 'package:jongerenpunt_app/models/subcategory.dart';
import 'package:jongerenpunt_app/screens/category/subcategory_detail_screen.dart';
import 'package:jongerenpunt_app/services/firestore_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryScreen extends StatefulWidget {
  final ctegories.Category category;

  const CategoryScreen({
    Key? key,
    required this.category,
  }) : super(key: key);

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  List<Subcategory> _allSubcategories = [];
  List<Subcategory> _filteredSubcategories = [];
  bool _isSearching = false;
  bool _isLoading = true;
  String? _errorMessage;
  
  // Track if we've already logged image errors to prevent repeats
  bool _hasLoggedImageError = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterSubcategories);
    
    // Fetch subcategories when screen initializes
    _fetchSubcategories();
  }
  
  Future<void> _fetchSubcategories() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Debug info
      if (kDebugMode) {
        print('Fetching subcategories for category ID: ${widget.category.id}');
      }
      
      // Check if category ID is valid
      if (widget.category.id.isEmpty) {
        throw Exception('Category ID is empty');
      }
      
      // Direct Firestore query - more reliable than stream for troubleshooting
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('subcategories')
          .where('categoryId', isEqualTo: widget.category.id)
          .get();
      
      if (!mounted) return;
      
      // Process results
      if (snapshot.docs.isEmpty) {
        if (kDebugMode) {
          print('No subcategories found for category: ${widget.category.id}');
        }
        
        setState(() {
          _allSubcategories = [];
          _filteredSubcategories = [];
          _isLoading = false;
        });
      } else {
        // Convert to subcategory objects
        final subcategories = snapshot.docs
            .map((doc) => Subcategory.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
        
        if (kDebugMode) {
          print('Found ${subcategories.length} subcategories');
          // Print first subcategory for debugging
          if (subcategories.isNotEmpty) {
            print('Sample subcategory: ${subcategories.first.title}, categoryId: ${subcategories.first.categoryId}');
          }
        }
        
        setState(() {
          _allSubcategories = subcategories;
          _filteredSubcategories = subcategories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching subcategories: $e');
      }
      
      if (mounted) {
        setState(() {
          _errorMessage = 'Er is een fout opgetreden bij het laden van de onderwerpen: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterSubcategories() {
    final query = _searchController.text.toLowerCase();
    
    if (!mounted) return;
    
    setState(() {
      if (query.isEmpty) {
        _filteredSubcategories = _allSubcategories;
        _isSearching = false;
      } else {
        _isSearching = true;
        _filteredSubcategories = _allSubcategories.where((subcategory) {
          return subcategory.title.toLowerCase().contains(query) ||
              (subcategory.description?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }
  
  void _retryFetch() {
    _fetchSubcategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Flexible app bar with category image
          SliverAppBar(
            expandedHeight: 200.0,
            pinned: true,
            stretch: true,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.category.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Category image with fallback
                  _buildCategoryImage(),
                  
                  // Gradient overlay for better text visibility
                  Container(
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
                ],
              ),
            ),
          ),
          
          // Search bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Zoeken in ${widget.category.title}',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
            ),
          ),
          
          // Content based on state: loading, error, or subcategories
          if (_isLoading) 
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _retryFetch,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Opnieuw proberen'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryStart,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_allSubcategories.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.category_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Geen onderwerpen gevonden',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_isSearching && _filteredSubcategories.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'Geen resultaten voor "${_searchController.text}"',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final subcategory = _filteredSubcategories[index];
                  return _buildSubcategoryItem(subcategory);
                },
                childCount: _filteredSubcategories.length,
              ),
            ),
          
          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryImage() {
    // Fallback color based on category title
    Color fallbackColor = CategoryHelper.getCategoryFallbackColor(widget.category.title);
    
    // If the image URL is empty, directly use the fallback
    if (widget.category.image.isEmpty) {
      return _buildFallbackContainer(fallbackColor);
    }
    
    // Use CachedNetworkImage with improved error handling
    return CachedNetworkImage(
      imageUrl: widget.category.image,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[300],
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      errorWidget: (context, url, error) {
        // Log error only once per screen
        if (!_hasLoggedImageError) {
          if (kDebugMode) {
            print('Error loading image for category ${widget.category.title}: $error - Will use fallback');
          }
          _hasLoggedImageError = true;
        }
        
        return _buildFallbackContainer(fallbackColor);
      },
    );
  }
  
  // Helper method for fallback container
  Widget _buildFallbackContainer(Color backgroundColor) {
    return Container(
      color: backgroundColor,
      child: Center(
        child: Icon(
          CategoryHelper.getCategoryIconData(widget.category.icon),
          color: Colors.white.withOpacity(0.3),
          size: 64,
        ),
      ),
    );
  }
  
  Widget _buildSubcategoryItem(Subcategory subcategory) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => SubcategoryDetailScreen(subcategory: subcategory),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primaryStart.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getSubcategoryIcon(subcategory.title),
                  color: AppColors.primaryStart,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subcategory.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subcategory.description != null && subcategory.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          subcategory.description!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.lightText,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    
                    // Let op tag if present
                    if (subcategory.letOp != null && subcategory.letOp!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: AppColors.warning.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.warning,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Let op',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.lightText,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  IconData _getSubcategoryIcon(String title) {
    final lowerTitle = title.toLowerCase();
    
    if (lowerTitle.contains('geld') || lowerTitle.contains('financiën') || lowerTitle.contains('belasting')) {
      return Icons.attach_money;
    } else if (lowerTitle.contains('mentaal') || lowerTitle.contains('hoofd')) {
      return Icons.psychology;
    } else if (lowerTitle.contains('licha') || lowerTitle.contains('gewicht')) {
      return Icons.fitness_center;
    } else if (lowerTitle.contains('seks')) {
      return Icons.favorite;
    } else if (lowerTitle.contains('drugs')) {
      return Icons.no_drinks;
    } else if (lowerTitle.contains('studie') || lowerTitle.contains('school')) {
      return Icons.school;
    } else if (lowerTitle.contains('werk')) {
      return Icons.work;
    } else if (lowerTitle.contains('switch') || lowerTitle.contains('veranderen')) {
      return Icons.swap_horiz;
    } else if (lowerTitle.contains('sport')) {
      return Icons.sports_soccer;
    } else if (lowerTitle.contains('kunst') || lowerTitle.contains('cultuur')) {
      return Icons.palette;
    } else if (lowerTitle.contains('woning') || lowerTitle.contains('huis')) {
      return Icons.home;
    } else if (lowerTitle.contains('urgent')) {
      return Icons.priority_high;
    } else if (lowerTitle.contains('juridisch') || lowerTitle.contains('recht')) {
      return Icons.gavel;
    } else if (lowerTitle.contains('ondernemen') || lowerTitle.contains('business')) {
      return Icons.business;
    } else if (lowerTitle.contains('veilig')) {
      return Icons.security;
    } else if (lowerTitle.contains('discriminatie')) {
      return Icons.pan_tool;
    } else if (lowerTitle.contains('18')) {
      return Icons.cake;
    }
    
    // Default icon
    return Icons.article;
  }
}