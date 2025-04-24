import 'package:flutter/material.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  
  // Initialize OpenAI API key
  Future<void> initialize(String apiKey) async {
    // Use the actual API key from the project
    OpenAI.apiKey = "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";
  }
  
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
      // Generate response from OpenAI
      final response = await _generateAIResponse(message);
      
      // Add AI response
      final aiMessage = ChatMessage(
        text: response,
        isUser: false,
      );
      
      messages.add(aiMessage);
      
      // Save chat history
      _saveChatHistory();
    } catch (e) {
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
  
  // Generate response from OpenAI
  Future<String> _generateAIResponse(String userMessage) async {
    // Create chat completion
    final chatCompletion = await OpenAI.instance.chat.create(
      model: "gpt-4o-mini", // Updated to use the model from the API key documentation
      messages: [
        OpenAIChatCompletionChoiceMessageModel(
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(
              "You are a helpful assistant for the Jongerenpunt app, which helps young people find information about finance, health, education, housing, and other topics relevant to youth in the Netherlands. Answer questions in Dutch, provide accurate information, and direct users to the appropriate categories in the app when relevant. Be concise, friendly, and supportive."
            ),
          ],
          role: OpenAIChatMessageRole.system,
        ),
        OpenAIChatCompletionChoiceMessageModel(
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(userMessage),
          ],
          role: OpenAIChatMessageRole.user,
        ),
      ],
      temperature: 0.7,
      maxTokens: 500,
    );
    
    return chatCompletion.choices.first.message.content!.first.text!;
  }
  
  // Clear chat history
  void clearChat() {
    messages.clear();
    _saveChatHistory();
    notifyListeners();
  }
  
  // Load chat history from storage
  Future<void> loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedMessages = prefs.getStringList('chat_messages');
    final List<String>? userFlags = prefs.getStringList('chat_is_user');
    final List<String>? timestamps = prefs.getStringList('chat_timestamps');
    
    if (savedMessages != null && userFlags != null && timestamps != null) {
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
  }
  
  // Save chat history to storage
  Future<void> _saveChatHistory() async {
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
  }
}