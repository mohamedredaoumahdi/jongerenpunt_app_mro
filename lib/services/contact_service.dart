import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ContactService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Submit contact form
  Future<void> submitContactForm({
    required String name,
    required String email,
    required String subject,
    required String message,
  }) async {
    try {
      // Validate inputs
      if (name.isEmpty || email.isEmpty || subject.isEmpty || message.isEmpty) {
        throw Exception('Alle velden zijn verplicht');
      }
      
      // Store the message in Firestore
      await _firestore.collection('contact_messages').add({
        'name': name,
        'email': email,
        'subject': subject,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'unread',
      });
      
      // Optionally, send an email notification to admin
      // This would typically be handled by a Cloud Function or backend service
      // For demo purposes, we're just logging it
      if (kDebugMode) {
        print('Contact form submitted:');
        print('Name: $name');
        print('Email: $email');
        print('Subject: $subject');
        print('Message: $message');
      }
      
      // For a real app, you might want to implement email sending via a backend service
      // await _sendEmailNotification(name, email, subject, message);
    } catch (e) {
      if (kDebugMode) {
        print('Error submitting contact form: $e');
      }
      throw Exception('Er is een fout opgetreden bij het verzenden van het formulier: $e');
    }
  }
  
  // Example of how you might implement email notification via a backend API
  Future<void> _sendEmailNotification(
    String name,
    String email,
    String subject,
    String message,
  ) async {
    try {
      // This is just an example - you would need a real backend endpoint
      const String apiUrl = 'https://your-backend-api.com/send-notification';
      
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'subject': subject,
          'message': message,
        }),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to send notification: ${response.body}');
      }
    } catch (e) {
      // If notification fails, we just log it but don't fail the whole submission
      if (kDebugMode) {
        print('Error sending email notification: $e');
      }
    }
  }
  
  // Get all contact messages (for admin panel)
  Future<List<Map<String, dynamic>>> getContactMessages() async {
    try {
      final snapshot = await _firestore
          .collection('contact_messages')
          .orderBy('timestamp', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting contact messages: $e');
      }
      throw Exception('Er is een fout opgetreden bij het ophalen van berichten: $e');
    }
  }
  
  // Mark a message as read
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _firestore.collection('contact_messages').doc(messageId).update({
        'status': 'read',
        'readTimestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error marking message as read: $e');
      }
      throw Exception('Er is een fout opgetreden bij het markeren van het bericht: $e');
    }
  }
}