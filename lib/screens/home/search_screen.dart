import 'package:flutter/material.dart';
import 'package:jongerenpunt_app/constants/app_theme.dart';
import 'package:jongerenpunt_app/models/category.dart';
import 'package:jongerenpunt_app/models/subcategory.dart';
import 'package:jongerenpunt_app/screens/category/category_screen.dart';
import 'package:jongerenpunt_app/screens/category/subcategory_detail_screen.dart';
import 'package:jongerenpunt_app/services/firestore_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  
  List<Category> _categories = [];
  List<Subcategory> _subcategories = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_searchController.text.isEmpty) {
        setState(() {
          _categories = [];
          _subcategories = [];
          _hasSearched = false;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });
    
    try {
      final results = await _firestoreService.searchContent(query);
      
      setState(() {
        _categories = results['categories'] as List<Category>;
        _subcategories = results['subcategories'] as List<Subcategory>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Zoeken mislukt: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zoeken', style : TextStyle(color : Colors.white)),
        backgroundColor: AppColors.primaryStart,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Zoek op onderwerp...',
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
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
            ),
          ),
          
          // Loading indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          
          // Search results
          Expanded(
            child: _hasSearched
                ? _buildSearchResults()
                : _buildSearchSuggestions(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchResults() {
    if (_categories.isEmpty && _subcategories.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Geen resultaten gevonden voor "${_searchController.text}"',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Categories results
        if (_categories.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Categorieën',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ..._categories.map(_buildCategoryItem).toList(),
          const SizedBox(height: 16),
        ],
        
        // Subcategories results
        if (_subcategories.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Onderwerpen',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ..._subcategories.map(_buildSubcategoryItem).toList(),
        ],
      ],
    );
  }
  
  Widget _buildCategoryItem(Category category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryStart.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.category,
            color: AppColors.primaryStart,
          ),
        ),
        title: Text(category.title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CategoryScreen(category: category),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildSubcategoryItem(Subcategory subcategory) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryStart.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.article,
            color: AppColors.primaryStart,
          ),
        ),
        title: Text(subcategory.title),
        subtitle: subcategory.description != null && subcategory.description!.isNotEmpty
            ? Text(
                subcategory.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => SubcategoryDetailScreen(subcategory: subcategory),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildSearchSuggestions() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Populaire onderwerpen',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSearchChip('Financiën'),
              _buildSearchChip('Wonen'),
              _buildSearchChip('Gezondheid'),
              _buildSearchChip('Werk'),
              _buildSearchChip('Opleiding'),
              _buildSearchChip('Vrije tijd'),
              _buildSearchChip('18 worden'),
              _buildSearchChip('Schulden'),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchChip(String label) {
    return ActionChip(
      label: Text(label),
      backgroundColor: Colors.grey[200],
      onPressed: () {
        _searchController.text = label;
        _search(label);
      },
    );
  }
}