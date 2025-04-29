import 'package:flutter/material.dart';
import 'package:jongerenpunt_app/constants/app_theme.dart';
import 'package:jongerenpunt_app/services/chat_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();
  bool _isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _initChatService();
  }
  
  Future<void> _initChatService() async {
    try {
      await _chatService.loadChatHistory();
      
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing chat service: $e');
      }
      
      // Initialize even if loading fails
      setState(() {
        _isInitialized = true;
      });
    }
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    _messageController.clear();
    await _chatService.sendMessage(text);
    
    // Scroll to bottom after sending message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  void _showResetChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chat wissen'),
        content: const Text('Weet je zeker dat je het chatgesprek wilt wissen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _chatService.clearChat();
            },
            child: const Text('Wissen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Assistent', style : TextStyle(color : Colors.white)),
        backgroundColor: AppColors.primaryStart,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white,),
            onPressed: _showResetChatDialog,
            tooltip: 'Chat wissen',
          ),
        ],
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: AnimatedBuilder(
                    animation: _chatService,
                    builder: (context, _) {
                      final messages = _chatService.messages;
                      
                      // If no messages, show welcome empty state
                      if (messages.isEmpty) {
                        return _buildEmptyChat();
                      }
                      
                      // Handle automatic scrolling to bottom when new messages arrive
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollController.hasClients) {
                          _scrollController.animateTo(
                            _scrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        }
                      });
                      
                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          return _buildMessageBubble(message);
                        },
                      );
                    },
                  ),
                ),
                
                // Typing indicator
                AnimatedBuilder(
                  animation: _chatService,
                  builder: (context, _) {
                    return _chatService.isLoading
                        ? Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            alignment: Alignment.center,
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Assistent typt...'),
                              ],
                            ),
                          )
                        : const SizedBox.shrink();
                  },
                ),
                
                // Message input
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: 'Typ een bericht...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          onSubmitted: (_) => _sendMessage(),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        color: AppColors.primaryStart,
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
  
  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline, 
            size: 80, 
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          const Text(
            'Je chat met de Jongerenpunt assistent',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Stel vragen over financiën, studie, werk, gezondheid, wonen, en meer!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              _messageController.text = "Hallo! Kun je me helpen?";
              _sendMessage();
            },
            icon: const Icon(Icons.chat),
            label: const Text('Start een gesprek'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryStart,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    const showTimestamp = true; // Could be a setting
    
    final formattedTime = DateFormat('HH:mm').format(message.timestamp);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              backgroundColor: AppColors.primaryStart,
              radius: 16,
              child: Icon(
                Icons.smart_toy,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.primaryStart : Colors.grey[200],
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomRight: isUser ? const Radius.circular(0) : null,
                      bottomLeft: !isUser ? const Radius.circular(0) : null,
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : AppColors.text,
                      fontSize: 16,
                    ),
                  ),
                ),
                
                if (showTimestamp)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      formattedTime,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.grey[300],
              radius: 16,
              child: const Icon(
                Icons.person,
                size: 18,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}