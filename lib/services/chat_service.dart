import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:jongerenpunt_app/constants/app_constants.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  
  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  // Convert message to JSON for storage or API requests
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
  
  // Create message from JSON (for storage or API responses)
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'],
      isUser: json['isUser'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    );
  }
}

class ChatService extends ChangeNotifier {
  List<ChatMessage> messages = [];
  bool isLoading = false;
  
  // URL for OpenAI API
  final String _apiUrl = 'https://api.openai.com/v1/chat/completions';
  
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
      // Call OpenAI API to get response
      final response = await _getOpenAIResponse(message);
      
      // Add AI response
      final aiMessage = ChatMessage(
        text: response,
        isUser: false,
      );
      
      messages.add(aiMessage);
      
      // Keep chat history within limits
      if (messages.length > AppConstants.maxChatHistory * 2) {
        // Remove oldest messages (keep pairs of user + AI messages)
        messages.removeRange(0, 2);
      }
      
      // Save chat history
      _saveChatHistory();
    } catch (e) {
      if (kDebugMode) {
        print('Error generating response: $e');
      }
      
      // Handle error
      final errorMessage = ChatMessage(
        text: "Sorry, er is een fout opgetreden. Probeer het later opnieuw.",
        isUser: false,
      );
      
      messages.add(errorMessage);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
  
  // Call OpenAI API to get response
  Future<String> _getOpenAIResponse(String userMessage) async {
    try {
      // Check if API key is set
      if (AppConstants.openAIApiKey == 'YOUR_OPENAI_API_KEY_HERE') {
        return "De OpenAI API-sleutel is niet geconfigureerd. Contacteer de applicatiebeheerder.";
      }
      
      // Prepare the messages to send to API
      final apiMessages = _prepareMessagesForAPI();
      
      // Request headers
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AppConstants.openAIApiKey}',
      };
      
      // Request body
      final body = jsonEncode({
        'model': AppConstants.openAIModel,
        'messages': apiMessages,
        'max_tokens': AppConstants.openAIMaxTokens,
        'temperature': AppConstants.openAITemperature,
      });
      
      // Make HTTP request with timeout
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: headers,
        body: body,
      ).timeout(AppConstants.chatTimeout);
      
      // Check response status
      if (response.statusCode != 200) {
        if (kDebugMode) {
          print('API Error: ${response.statusCode} - ${response.body}');
        }
        return "Er is een fout opgetreden bij het genereren van een antwoord. Statuscode: ${response.statusCode}";
      }
      
      // Parse response
      final jsonResponse = jsonDecode(response.body);
      final content = jsonResponse['choices'][0]['message']['content'];
      
      return content.trim();
    } catch (e) {
      if (kDebugMode) {
        print('Error in OpenAI API call: $e');
      }
      throw Exception('Fout bij het communiceren met de AI-service: $e');
    }
  }
  
  // Prepare messages for OpenAI API format
  List<Map<String, String>> _prepareMessagesForAPI() {
    // Start with system message to set context
    final apiMessages = <Map<String, String>>[
      {
        'role': 'system',
        'content': AppConstants.chatSystemPrompt,
      }
    ];
    
    // Add conversation history (limit to last 10 messages for context window size)
    final historyToSend = messages.length > 10 ? messages.sublist(messages.length - 10) : messages;
    
    for (final message in historyToSend) {
      apiMessages.add({
        'role': message.isUser ? 'user' : 'assistant',
        'content': message.text,
      });
    }
    
    return apiMessages;
  }
  
  // Fall back to local response if API fails
  String _generateLocalFallbackResponse(String userMessage) {
    // Convert message to lowercase for case-insensitive matching
    final lowerMessage = userMessage.toLowerCase();
    
    // Simple keyword-based responses as fallback
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
    
    // Default response if no keywords match
    return 'Dank voor je vraag. Bij Jongerenpunt kun je informatie vinden over verschillende onderwerpen zoals financiën, gezondheid, studie, werk, wonen en meer. Kies een categorie in de app om meer specifieke informatie te vinden of stel een meer specifieke vraag.';
  }
  
  // Clear chat history
  Future<void> clearChat() async {
    messages.clear();
    _saveChatHistory();
    
    // Add welcome message
    final welcomeMessage = ChatMessage(
      text: 'Hallo! Ik ben de Jongerenpunt assistent. Hoe kan ik je vandaag helpen? Je kunt me vragen stellen over financiën, gezondheid, studie, werk, wonen, vrije tijd, en meer!',
      isUser: false,
    );
    
    messages.add(welcomeMessage);
    notifyListeners();
  }
  
  // Load chat history from storage
  Future<void> loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? chatHistoryJson = prefs.getString(AppConstants.storageChatHistory);
      
      if (chatHistoryJson != null) {
        final List<dynamic> jsonList = jsonDecode(chatHistoryJson);
        messages = jsonList.map((json) => ChatMessage.fromJson(json)).toList();
        
        notifyListeners();
      } else {
        // Add welcome message if no history exists
        _addWelcomeMessage();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading chat history: $e');
      }
      // If loading fails, just start with a welcome message
      _addWelcomeMessage();
    }
  }
  
  // Add welcome message
  void _addWelcomeMessage() {
    messages.add(
      ChatMessage(
        text: 'Hallo! Ik ben de Jongerenpunt assistent. Hoe kan ik je vandaag helpen? Je kunt me vragen stellen over financiën, gezondheid, studie, werk, wonen, vrije tijd, en meer!',
        isUser: false,
      ),
    );
    
    notifyListeners();
  }
  
  // Save chat history to storage using JSON
  Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert messages to JSON
      final List<Map<String, dynamic>> jsonList = messages.map((m) => m.toJson()).toList();
      final String chatHistoryJson = jsonEncode(jsonList);
      
      // Save to SharedPreferences
      await prefs.setString(AppConstants.storageChatHistory, chatHistoryJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving chat history: $e');
      }
      // Continue even if saving fails
    }
  }
}