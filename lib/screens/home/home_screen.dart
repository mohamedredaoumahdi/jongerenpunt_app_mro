import 'package:flutter/material.dart';
import 'package:jongerenpunt_app/constants/app_theme.dart';
import 'package:jongerenpunt_app/models/category.dart';
import 'package:jongerenpunt_app/screens/category/category_screen.dart';
import 'package:jongerenpunt_app/screens/chat/chat_screen.dart';
import 'package:jongerenpunt_app/screens/home/search_screen.dart';
import 'package:jongerenpunt_app/screens/profile/profile_screen.dart';
import 'package:jongerenpunt_app/services/auth_service.dart';
import 'package:jongerenpunt_app/services/firestore_service.dart';
import 'package:provider/provider.dart';
import 'package:jongerenpunt_app/widgets/category_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryStart,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profiel',
          ),
        ],
      ),
    );
  }
  
  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return const ChatScreen();
      case 2:
        return const ProfileScreen();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          expandedHeight: 150.0,
          floating: false,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
            ),
            title: const Text(
              'Jongerenpunt',
              style: TextStyle(color: Colors.white),
            ),
            centerTitle: true,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SearchScreen()),
                );
              },
            ),
          ],
        ),
        
        // Welcome message
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welkom bij Jongerenpunt',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Vind informatie over alles wat voor jou belangrijk is',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.lightText,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Categorieën',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Categories list
        StreamBuilder<List<Category>>(
          stream: _firestoreService.getCategories(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              );
            }
            
            if (snapshot.hasError) {
              return SliverFillRemaining(
                child: Center(child: Text('Error: ${snapshot.error}')),
              );
            }
            
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SliverFillRemaining(
                child: Center(child: Text('Geen categorieën gevonden')),
              );
            }
            
            final categories = snapshot.data!;
            
            return SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final category = categories[index];
                    return CategoryCard(
                      category: category,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => CategoryScreen(category: category),
                          ),
                        );
                      },
                    );
                  },
                  childCount: categories.length,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}