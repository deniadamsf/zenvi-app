import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  List<InAppNotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String _selectedFilter = 'all'; // all, shift, stock, leave, chat, reservation

  List<InAppNotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String get selectedFilter => _selectedFilter;

  List<InAppNotificationModel> get filteredNotifications {
    if (_selectedFilter == 'all') {
      return _notifications;
    }
    return _notifications.where((n) {
      if (_selectedFilter == 'shift') {
        return n.type == 'shift' || n.type.startsWith('shift');
      } else if (_selectedFilter == 'stock') {
        return n.type == 'stock' || n.type == 'low_stock';
      } else if (_selectedFilter == 'leave') {
        return n.type == 'leave' || n.type.startsWith('permission');
      } else if (_selectedFilter == 'chat') {
        return n.type == 'chat' || n.type.startsWith('chat');
      } else if (_selectedFilter == 'reservation') {
        return n.type == 'reservation' || n.type.startsWith('reservation');
      }
      return n.type == _selectedFilter;
    }).toList();
  }

  NotificationProvider() {
    // Bind callback from NotificationService when foreground message arrives
    NotificationService.onNotificationReceived = () {
      fetchNotifications(silent: true);
    };
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  /// Fetch notifications from backend
  Future<void> fetchNotifications({String? token, bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/notifications');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['data'] is List) {
          final List list = decoded['data'];
          _notifications = list.map((item) => InAppNotificationModel.fromJson(item)).toList();
          _unreadCount = decoded['unread_count'] is int ? decoded['unread_count'] : 0;
        }
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      if (!silent) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  /// Mark specific notification as read
  Future<void> markAsRead(int id, {String? token}) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true, readAt: DateTime.now());
      if (_unreadCount > 0) _unreadCount--;
      notifyListeners();

      try {
        final url = Uri.parse('${ApiConfig.baseUrl}/notifications/$id/read');
        await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
          },
        );
      } catch (e) {
        debugPrint('Error marking notification as read: $e');
      }
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead({String? token}) async {
    if (_unreadCount == 0) return;

    _notifications = _notifications.map((n) => n.copyWith(isRead: true, readAt: DateTime.now())).toList();
    _unreadCount = 0;
    notifyListeners();

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/notifications/read-all');
      await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(int id, {String? token}) async {
    final matches = _notifications.where((n) => n.id == id);
    if (matches.isNotEmpty) {
      final removed = matches.first;
      if (!removed.isRead && _unreadCount > 0) {
        _unreadCount--;
      }
    }
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/notifications/$id');
      await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }
}
