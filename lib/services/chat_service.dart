import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  
  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ChatService extends ChangeNotifier {
  List<ChatMessage> messages = [];
  bool isLoading = false;
  
  // Add a user message and get AI response
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;
    
    // Add user message
    final userMessage = ChatMessage(
      text: message,
      isUser: true,
    );
    
    messages.add(userMessage);
    isLoading = true;
    notifyListeners();
    
    try {
      // Generate a simple AI-like response based on keywords - no API needed
      final response = await _generateLocalResponse(message);
      
      // Add AI response
      final aiMessage = ChatMessage(
        text: response,
        isUser: false,
      );
      
      messages.add(aiMessage);
      
      // Save chat history
      _saveChatHistory();
    } catch (e) {
      if (kDebugMode) {
        print('Error generating response: $e');
      }
      
      // Handle error
      final errorMessage = ChatMessage(
        text: "Sorry, ik kon geen antwoord genereren. Probeer het later opnieuw.",
        isUser: false,
      );
      
      messages.add(errorMessage);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
  
  // Generate a local rule-based response without needing an API
  Future<String> _generateLocalResponse(String userMessage) async {
    // Simulate a network delay for a more realistic experience
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Convert message to lowercase for case-insensitive matching
    final lowerMessage = userMessage.toLowerCase();
    
    // Simple keyword-based responses
    if (lowerMessage.contains('hallo') || lowerMessage.contains('hoi') || lowerMessage.contains('hey')) {
      return 'Hallo! Hoe kan ik je vandaag helpen?';
    }
    
    if (lowerMessage.contains('dank') || lowerMessage.contains('bedankt')) {
      return 'Graag gedaan! Kan ik je nog ergens anders mee helpen?';
    }
    
    // Topic-based responses
    if (lowerMessage.contains('geld') || 
        lowerMessage.contains('financiën') || 
        lowerMessage.contains('financien') || 
        lowerMessage.contains('schuld')) {
      return 'Het Jongerenpunt biedt informatie over financiën, zoals omgaan met geld, schulden, belastingen en zorgverzekering. Ga naar de Financiën categorie in de app om meer informatie te vinden.';
    }
    
    if (lowerMessage.contains('gezond') || 
        lowerMessage.contains('mentaal') || 
        lowerMessage.contains('stress') || 
        lowerMessage.contains('lichaam')) {
      return 'Bij het Jongerenpunt vind je informatie over mentale en lichamelijke gezondheid. We hebben tips en contactgegevens voor ondersteuning. Bekijk de categorie Gezondheid voor meer details.';
    }
    
    if (lowerMessage.contains('studie') || 
        lowerMessage.contains('school') || 
        lowerMessage.contains('opleiding') || 
        lowerMessage.contains('studeren')) {
      return 'Voor informatie over studie, studiekeuze of inschrijving kun je naar de categorie Studie, Stage & Werk gaan. Daar vind je tips en handige links.';
    }
    
    if (lowerMessage.contains('woon') ||
        lowerMessage.contains('huis') || 
        lowerMessage.contains('kamer') ||
        lowerMessage.contains('huren')) {
      return 'Het Jongerenpunt kan je helpen met informatie over wonen, zoals het zoeken naar een woning, urgentie aanvragen en voor het eerst gaan huren. Bekijk de categorie Wonen voor meer details.';
    }
    
    if (lowerMessage.contains('werk') || 
        lowerMessage.contains('baan') || 
        lowerMessage.contains('solliciteren') ||
        lowerMessage.contains('cv')) {
      return 'Voor hulp bij het zoeken naar werk of het maken van een CV kun je terecht in de categorie Studie, Stage & Werk. Daar vind je tips en handige links naar organisaties die je kunnen helpen.';
    }
    
    if (lowerMessage.contains('juridisch') || 
        lowerMessage.contains('recht') || 
        lowerMessage.contains('wet') ||
        lowerMessage.contains('straf')) {
      return 'Voor juridische vragen zoals bezwaarschriften, VOG of strafblad kun je terecht in de categorie Juridische zaken. Je kunt ook het Juridisch Loket bezoeken voor gratis advies als je een laag inkomen hebt.';
    }
    
    if (lowerMessage.contains('discriminatie') || 
        lowerMessage.contains('ongelijk') || 
        lowerMessage.contains('racisme')) {
      return 'Als je te maken hebt met discriminatie op school, werk of bij het zoeken naar een woning, vind je informatie in de categorie Discriminatie. Discriminatie kan gemeld worden via de link in de app.';
    }
    
    if (lowerMessage.contains('18') || 
        lowerMessage.contains('achttien') || 
        lowerMessage.contains('volwassen')) {
      return 'Als je 18 wordt, verandert er veel. Je wordt officieel volwassen en krijgt meer rechten maar ook plichten. In de categorie "18 worden" vind je informatie over wat er allemaal verandert en waar je op moet letten.';
    }
    
    // Default response if no keywords match
    return 'Dank voor je vraag. Bij Jongerenpunt kun je informatie vinden over verschillende onderwerpen zoals financiën, gezondheid, studie, werk, wonen en meer. Kies een categorie in de app om meer specifieke informatie te vinden of stel een meer specifieke vraag.';
  }
  
  // Clear chat history
  void clearChat() {
    messages.clear();
    _saveChatHistory();
    notifyListeners();
  }
  
  // Load chat history from storage
  Future<void> loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? savedMessages = prefs.getStringList('chat_messages');
      final List<String>? userFlags = prefs.getStringList('chat_is_user');
      final List<String>? timestamps = prefs.getStringList('chat_timestamps');
      
      if (savedMessages != null && userFlags != null && timestamps != null &&
          savedMessages.length == userFlags.length && 
          savedMessages.length == timestamps.length) {
        messages = List.generate(
          savedMessages.length,
          (index) => ChatMessage(
            text: savedMessages[index],
            isUser: userFlags[index] == '1',
            timestamp: DateTime.fromMillisecondsSinceEpoch(
              int.parse(timestamps[index]),
            ),
          ),
        );
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading chat history: $e');
      }
      // If loading fails, just start with an empty chat
    }
  }
  
  // Save chat history to storage
  Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setStringList(
        'chat_messages',
        messages.map((m) => m.text).toList(),
      );
      
      await prefs.setStringList(
        'chat_is_user',
        messages.map((m) => m.isUser ? '1' : '0').toList(),
      );
      
      await prefs.setStringList(
        'chat_timestamps',
        messages.map((m) => m.timestamp.millisecondsSinceEpoch.toString()).toList(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error saving chat history: $e');
      }
      // Continue even if saving fails
    }
  }
}