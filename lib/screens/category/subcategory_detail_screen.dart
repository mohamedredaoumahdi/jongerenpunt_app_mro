import 'package:flutter/material.dart';
import 'package:jongerenpunt_app/constants/app_theme.dart';
import 'package:jongerenpunt_app/models/subcategory.dart';
import 'package:jongerenpunt_app/services/firestore_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubcategoryDetailScreen extends StatefulWidget {
  final Subcategory subcategory;

  const SubcategoryDetailScreen({
    Key? key,
    required this.subcategory,
  }) : super(key: key);

  @override
  State<SubcategoryDetailScreen> createState() => _SubcategoryDetailScreenState();
}

class _SubcategoryDetailScreenState extends State<SubcategoryDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  String? _errorMessage;
  Subcategory? _subcategoryData;

  @override
  void initState() {
    super.initState();
    _loadSubcategoryDetails();
  }

  Future<void> _loadSubcategoryDetails() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Debug info
      if (kDebugMode) {
        print('Loading details for subcategory ID: ${widget.subcategory.id}');
        print('Initial subcategory data: ${widget.subcategory.title}, description: ${widget.subcategory.description}');
      }
      
      // Direct Firestore query - more reliable than going through service for troubleshooting
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('subcategories')
          .doc(widget.subcategory.id)
          .get();
      
      if (!mounted) return;
      
      if (!doc.exists) {
        throw Exception('Subcategory niet gevonden');
      }
      
      final data = doc.data() as Map<String, dynamic>;
      final subcategoryData = Subcategory.fromMap(data, doc.id);
      
      // Debug info
      if (kDebugMode) {
        print('Loaded subcategory data: ${subcategoryData.title}');
        print('Description: ${subcategoryData.description}');
        print('Let op: ${subcategoryData.letOp}');
        print('CTA: ${subcategoryData.ctaText}, URL: ${subcategoryData.ctaUrl}');
      }
      
      setState(() {
        _subcategoryData = subcategoryData;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading subcategory details: $e');
      }
      
      if (mounted) {
        setState(() {
          _errorMessage = 'Er is een fout opgetreden bij het laden van de details: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  void _retryLoading() {
    _loadSubcategoryDetails();
  }

  Future<void> _launchURL(BuildContext context, String url) async {
    try {
      // Check if URL needs a scheme (e.g., adding https:// if missing)
      Uri uri;
      if (url.startsWith('mailto:')) {
        uri = Uri.parse(url);
      } else if (!url.startsWith('http://') && !url.startsWith('https://')) {
        uri = Uri.parse('https://$url');
      } else {
        uri = Uri.parse(url);
      }
      
      // Try to launch the URL
      final bool canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (kDebugMode) {
          print('Could not launch: $url (Uri: $uri)');
        }
        _showErrorSnackbar(context, 'Kon de link niet openen: $url');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error launching URL: $e');
      }
      _showErrorSnackbar(context, 'Fout bij het openen van de link');
    }
  }
  
  void _showErrorSnackbar(BuildContext context, String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  void _shareContent(BuildContext context, Subcategory subcategoryData) {
    final String title = subcategoryData.title;
    final String description = subcategoryData.description ?? '';
    final String? url = subcategoryData.ctaUrl;
    
    String shareText = title;
    if (description.isNotEmpty) {
      shareText += '\n\n$description';
    }
    if (url != null && url.isNotEmpty) {
      shareText += '\n\nMeer info: $url';
    }
    
    shareText += '\n\nGedeeld via de Jongerenpunt App';
    
    Share.share(shareText, subject: 'Info over $title');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.subcategory.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primaryStart,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color : Colors.white),
            onPressed: _subcategoryData != null 
                ? () => _shareContent(context, _subcategoryData!)
                : null,
            tooltip: 'Delen',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
  
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage != null) {
      return Center(
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
              onPressed: _retryLoading,
              icon: const Icon(Icons.refresh),
              label: const Text('Opnieuw proberen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryStart,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
    
    // If no data was fetched but no error either, use the initial subcategory data
    final subcategoryData = _subcategoryData ?? widget.subcategory;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main content card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subtitle
                  const Text(
                    'Informatie',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryStart,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Description
                  if (subcategoryData.description != null && subcategoryData.description!.isNotEmpty)
                    Text(
                      subcategoryData.description!,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    )
                  else
                    const Text(
                      'Geen beschrijving beschikbaar',
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: AppColors.lightText,
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Warning section
          if (subcategoryData.letOp != null && subcategoryData.letOp!.isNotEmpty)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: AppColors.warning.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.warning,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Let op',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Text(
                      subcategoryData.letOp!,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 24),
          
          // Related links section
          if (subcategoryData.ctaText != null && 
              subcategoryData.ctaText!.isNotEmpty && 
              subcategoryData.ctaUrl != null &&
              subcategoryData.ctaUrl!.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nuttige links',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Link card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () => _launchURL(context, subcategoryData.ctaUrl!),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.link,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  subcategoryData.ctaText!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  subcategoryData.ctaUrl!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.lightText,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.open_in_new,
                            color: AppColors.accent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          
          const SizedBox(height: 24),
          
          // Call to action button
          if (subcategoryData.ctaText != null && 
              subcategoryData.ctaText!.isNotEmpty && 
              subcategoryData.ctaUrl != null &&
              subcategoryData.ctaUrl!.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _launchURL(context, subcategoryData.ctaUrl!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryStart,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  subcategoryData.ctaText!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          
          // Bottom spacing
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}