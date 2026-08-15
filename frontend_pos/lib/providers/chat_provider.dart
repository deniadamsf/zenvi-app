import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ChatContact {
  final int id;
  final String name;
  final String role;
  final bool isOnline; // Simplification, maybe always true or false for now
  final String lastMessage;
  final DateTime? lastMessageTime;

  ChatContact({
    required this.id,
    required this.name,
    required this.role,
    this.isOnline = true,
    this.lastMessage = 'Mulai Percakapan',
    this.lastMessageTime,
  });

  factory ChatContact.fromJson(Map<String, dynamic> json) {
    return ChatContact(
      id: json['id'],
      name: json['name'],
      role: json['role'],
      lastMessage: json['last_message'] ?? 'Mulai Percakapan',
      lastMessageTime: json['last_message_time'] != null ? DateTime.parse(json['last_message_time']).toLocal() : null,
    );
  }
}

class ChatMessage {
  final int id;
  final int senderId;
  final String senderName;
  final String senderRole;
  final String message;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      senderId: json['sender_id'],
      senderName: json['sender']['name'],
      senderRole: json['sender']['role'],
      message: json['message'],
      createdAt: DateTime.parse(json['created_at']).toLocal(),
    );
  }
}

class ChatProvider extends ChangeNotifier {
  List<ChatMessage> _messages = [];
  List<ChatContact> _contacts = [];
  bool _isLoading = false;

  List<ChatMessage> get messages => _messages;
  List<ChatContact> get contacts => _contacts;
  bool get isLoading => _isLoading;

  static const String _apiUrl = ApiConfig.baseUrl;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> fetchContacts() async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/companies/employees/active'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _contacts = data.map((json) => ChatContact.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetch contacts: $e');
    }
  }

  Future<void> fetchMessages({int? receiverId}) async {
    final token = await _getToken();
    if (token == null) return;

    _isLoading = true;
    _messages = [];
    notifyListeners();

    try {
      String url = '$_apiUrl/chat';
      if (receiverId != null) {
        url += '?receiver_id=$receiverId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _messages = data.map((json) => ChatMessage.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error fetch chat: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> sendMessage(String text, {int? receiverId}) async {
    final token = await _getToken();
    if (token == null) return false;

    try {
      final bodyData = <String, dynamic>{'message': text};
      if (receiverId != null) {
        bodyData['receiver_id'] = receiverId;
      }

      final response = await http.post(
        Uri.parse('$_apiUrl/chat'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(bodyData),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _messages.add(ChatMessage.fromJson(data));
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error send chat: $e');
    }
    return false;
  }
}
