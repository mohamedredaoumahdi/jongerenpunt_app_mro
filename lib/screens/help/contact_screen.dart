import 'package:flutter/material.dart';
import 'package:jongerenpunt_app/constants/app_theme.dart';
import 'package:jongerenpunt_app/services/auth_service.dart';
import 'package:jongerenpunt_app/services/contact_service.dart';
import 'package:jongerenpunt_app/widgets/custom_widgets.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({Key? key}) : super(key: key);

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSubmitted = false;
  String? _errorMessage;
  
  // List of available subjects
  final List<String> _subjects = [
    'Vraag over de app',
    'Technisch probleem',
    'Suggestie',
    'Onjuiste informatie',
    'Account probleem',
    'Andere vraag',
  ];
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      
      if (user != null && !user.isAnonymous) {
        // Get user profile data
        final userData = await authService.getUserProfile();
        
        if (!mounted) return;
        
        setState(() {
          _nameController.text = userData['username'] ?? '';
          _emailController.text = user.email ?? '';
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user data: $e');
      }
      // Continue without pre-filled data
    }
  }
  
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final contactService = Provider.of<ContactService>(context, listen: false);
      
      // Submit contact form
      await contactService.submitContactForm(
        name: _nameController.text,
        email: _emailController.text,
        subject: _subjectController.text,
        message: _messageController.text,
      );
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _isSubmitted = true;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error submitting contact form: $e');
      }
      
      if (mounted) {
        setState(() {
          _errorMessage = 'Er is een fout opgetreden bij het verzenden van het formulier: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _openEmailApp() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'info@jongerenpuntovervecht.nl',
      queryParameters: {
        'subject': 'Contact via Jongerenpunt App',
        'body': 'Beste Jongerenpunt team,\n\n',
      },
    );
    
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kon de e-mail app niet openen'),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error opening email app: $e');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Er is een fout opgetreden bij het openen van de e-mail app'),
        ),
      );
    }
  }
  
  Future<void> _openPhoneApp() async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: '+31612345678',
    );
    
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kon de telefoon app niet openen'),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error opening phone app: $e');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Er is een fout opgetreden bij het openen van de telefoon app'),
        ),
      );
    }
  }
  
  void _resetForm() {
    setState(() {
      _isSubmitted = false;
      _subjectController.clear();
      _messageController.clear();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryStart,
        foregroundColor: Colors.white,
      ),
      body: _isSubmitted
          ? _buildSuccessScreen()
          : _buildContactForm(),
    );
  }
  
  Widget _buildSuccessScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 80,
              ),
            ),
            
            const SizedBox(height: 32),
            
            const Text(
              'Bericht verstuurd!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              'Bedankt voor je bericht. We nemen zo snel mogelijk contact met je op via het opgegeven e-mailadres.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 32),
            
            PrimaryButton(
              text: 'Nieuw bericht',
              onPressed: _resetForm,
              icon: Icons.edit,
            ),
            
            const SizedBox(height: 16),
            
            SecondaryButton(
              text: 'Terug naar help',
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: Icons.arrow_back,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildContactForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Introduction text
            const Text(
              'Heb je een vraag of opmerking? Vul het onderstaande formulier in en we nemen zo snel mogelijk contact met je op.',
              style: TextStyle(fontSize: 16),
            ),
            
            const SizedBox(height: 24),
            
            // Alternative contact methods
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Direct contact',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Email option
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryStart.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.email,
                          color: AppColors.primaryStart,
                        ),
                      ),
                      title: const Text('E-mail'),
                      subtitle: const Text('info@jongerenpuntovervecht.nl'),
                      onTap: _openEmailApp,
                    ),
                    
                    const Divider(),
                    
                    // // Phone option
                    // ListTile(
                    //   leading: Container(
                    //     padding: const EdgeInsets.all(8),
                    //     decoration: BoxDecoration(
                    //       color: AppColors.primaryStart.withOpacity(0.1),
                    //       borderRadius: BorderRadius.circular(8),
                    //     ),
                    //     child: const Icon(
                    //       Icons.phone,
                    //       color: AppColors.primaryStart,
                    //     ),
                    //   ),
                    //   title: const Text('Telefoon'),
                    //   subtitle: const Text('+31 6 12345678'),
                    //   onTap: _openPhoneApp,
                    // ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Contact form title
            const Text(
              'Contactformulier',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Error message
            if (_errorMessage != null)
              ErrorMessage(
                message: _errorMessage!,
                onDismiss: () {
                  setState(() {
                    _errorMessage = null;
                  });
                },
              ),
            
            // Name field
            CustomTextField(
              controller: _nameController,
              labelText: 'Naam',
              hintText: 'Jouw naam',
              prefixIcon: Icons.person,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Voer je naam in';
                }
                return null;
              },
            ),
            
            // Email field
            EmailTextField(
              controller: _emailController,
              labelText: 'E-mailadres',
              hintText: 'jouw@email.nl',
            ),
            
            // Subject dropdown
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Onderwerp',
                  prefixIcon: Icon(Icons.subject),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
                value: _subjectController.text.isEmpty ? null : _subjectController.text,
                items: _subjects.map((subject) {
                  return DropdownMenuItem<String>(
                    value: subject,
                    child: Text(subject),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    _subjectController.text = value;
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Selecteer een onderwerp';
                  }
                  return null;
                },
                isExpanded: true,
              ),
            ),
            
            // Message field
            CustomTextField(
              controller: _messageController,
              labelText: 'Bericht',
              hintText: 'Jouw vraag of opmerking...',
              prefixIcon: Icons.message,
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Voer een bericht in';
                }
                if (value.length < 10) {
                  return 'Je bericht moet minimaal 10 tekens bevatten';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Submit button
            PrimaryButton(
              text: 'Verzenden',
              onPressed: _submitForm,
              isLoading: _isLoading,
              icon: Icons.send,
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}