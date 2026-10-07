import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/api_config.dart';

class ChatMessage {
  final String content;
  final String role; // "user" or "model"
  final DateTime timestamp;

  ChatMessage({required this.content, required this.role, required this.timestamp});
}

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  Map<String, dynamic>? _userContext;

  @override
  void initState() {
    super.initState();
    _loadUserContext();
    // Initial greeting
    _messages.add(ChatMessage(
      content: "Hello! I'm your Elite Pace Coach. How can I help you with your training today?",
      role: "model",
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _loadUserContext() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Fetch user profile
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      // Fetch latest predictions
      final predictionsQuery = await FirebaseFirestore.instance
          .collection('predictions')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(4)
          .get();

      Map<String, dynamic> context = {};
      if (userDoc.exists) {
        final profileData = Map<String, dynamic>.from(userDoc.data()!);
        // Convert any timestamps in profile
        profileData.forEach((key, value) {
          if (value is Timestamp) {
            profileData[key] = value.toDate().toIso8601String();
          }
        });
        context['profile'] = profileData;
      }
      
      if (predictionsQuery.docs.isNotEmpty) {
        context['latest_predictions'] = predictionsQuery.docs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data());
          // Convert any timestamps in prediction docs
          data.forEach((key, value) {
            if (value is Timestamp) {
              data[key] = value.toDate().toIso8601String();
            }
          });
          return data;
        }).toList();
      }

      setState(() {
        _userContext = context;
      });
    }
  }

  void _scrollToBottom() {
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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        content: text,
        role: "user",
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
      _messageController.clear();
    });
    _scrollToBottom();

    try {
      final url = Uri.parse(ApiConfig.coachUrl);
      print("Attempting to connect to: $url");
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "message": text,
          "history": _messages.sublist(0, _messages.length - 1).map((m) => {
            "role": m.role,
            "content": m.content,
          }).toList(),
          "user_context": _userContext,
        }),
      );

      print("Response status: ${response.statusCode}");
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _messages.add(ChatMessage(
            content: data['response'],
            role: "model",
            timestamp: DateTime.now(),
          ));
        });
      } else {
        print("Backend Error: ${response.body}");
        setState(() {
          _messages.add(ChatMessage(
            content: "Sorry, I'm having trouble connecting right now (Error ${response.statusCode}).",
            role: "model",
            timestamp: DateTime.now(),
          ));
        });
      }
    } catch (e) {
      print("Connection Exception: $e");
      setState(() {
        _messages.add(ChatMessage(
          content: "Connection error: $e",
          role: "model",
          timestamp: DateTime.now(),
        ));
      });
    } finally {
      setState(() => _isTyping = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Running Coach'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add(ChatMessage(
                  content: "Chat cleared. How can I help you start fresh?",
                  role: "model",
                  timestamp: DateTime.now(),
                ));
              });
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message.role == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser ? theme.colorScheme.primary : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 0),
                        bottomRight: Radius.circular(isUser ? 0 : 16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      message.content,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Coach is thinking...",
                  style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Ask about your training...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
