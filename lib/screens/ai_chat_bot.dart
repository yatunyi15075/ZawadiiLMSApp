import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Chat Message Model
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

// Helper widget to format text like in the webapp
class FormattedText extends StatelessWidget {
  final String text;
  const FormattedText({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Split text by ** markers
    final parts = text.split(RegExp(r'(\*\*.*?\*\*)'));

    return Wrap(
      children: parts.map((part) {
        if (part.startsWith("**") && part.endsWith("**")) {
          final cleanText = part.substring(2, part.length - 2);

          if (cleanText.startsWith("Core Function:")) {
            return Text(
              "\n$cleanText\n",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
                fontSize: 16,
              ),
            );
          } else {
            return Text(
              cleanText,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.blueAccent,
              ),
            );
          }
        } else {
          return Text(
            part,
            style: const TextStyle(
              color: Colors.black, // Ensure bot response text is visible
              fontSize: 16,
            ),
          );
        }
      }).toList(),
    );
  }
}

// AI Chat Screen
class AIChatScreen extends StatefulWidget {
  const AIChatScreen({Key? key}) : super(key: key);

  @override
  _AIChatScreenState createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // Colors
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color surfaceColor = Color(0xFFF8FAFC);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _messages.add(ChatMessage(
      text: "Hello! I'm Asiko AI your assistant. How can I help you today?",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _generateAIResponse(String userMessage) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://zawadi-lms.onrender.com/api/zawadii-bot/generate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'message': userMessage}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        setState(() {
          _messages.add(ChatMessage(
            text: responseData['message'],
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
      } else {
        _addErrorMessage();
      }
    } catch (error) {
      _addErrorMessage();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addErrorMessage() {
    _messages.add(ChatMessage(
      text: "I'm sorry, but I encountered an error. Could you please try again?",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();

    setState(() {
      _messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
    });

    _generateAIResponse(userMessage);
    _messageController.clear();
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _messages.add(ChatMessage(
        text: "Chat cleared. How can I help you?",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cardColor,
        foregroundColor: textPrimary,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.psychology_rounded,
                  color: primaryColor, size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Asiko AI',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: textPrimary,
                  ),
                ),
                Text(
                  'Professional Assistant',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _clearChat,
            icon: const Icon(Icons.delete_forever, color: Colors.red),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildLoadingBubble();
                }
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Row(
      children: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.smart_toy, color: primaryColor, size: 18),
        ),
        const Text("Thinking...",
            style: TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Column(
      crossAxisAlignment:
          message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
              message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!message.isUser)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.smart_toy, color: primaryColor, size: 18),
              ),
            Flexible(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: message.isUser ? primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: message.isUser
                    ? Text(
                        message.text,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      )
                    : FormattedText(text: message.text),
              ),
            ),
            if (message.isUser)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.person, color: primaryColor, size: 18),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 40, right: 40, top: 4),
          child: Text(
            "${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}",
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        )
      ],
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))
      ]),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(
                color: Colors.black, // Fix: typed text is now black
                fontSize: 16,
              ),
              decoration: const InputDecoration(
                hintText: "Type your message...",
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            onPressed: _isLoading ? null : _sendMessage,
            icon: const Icon(Icons.send, color: primaryColor),
          )
        ],
      ),
    );
  }
}
