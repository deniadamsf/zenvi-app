import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/notification_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/zenvi_header.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
  }

  void _loadNotifications() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final notifProvider = Provider.of<NotificationProvider>(context, listen: false);
    notifProvider.fetchNotifications(token: auth.token);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final notifProvider = Provider.of<NotificationProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      body: RefreshIndicator(
        onRefresh: () async {
          await notifProvider.fetchNotifications(token: auth.token);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            ZenviHeader.sliver(
              title: 'pusat_notifikasi_16'.tr(context: context),
              showBackButton: true,
              actions: [
                if (notifProvider.unreadCount > 0)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      notifProvider.markAllAsRead(token: auth.token);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('semua_notifikasi_ditandai_dibaca_218'.tr(context: context)),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: Icon(Icons.done_all, size: 16, color: theme.colorScheme.primary),
                    label: Text(
                      'baca_semua_10'.tr(context: context),
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
              ],
            ),
            
            // Filter Chips
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                child: _buildFilterChips(notifProvider),
              ),
            ),

            // Notification List
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 40),
              sliver: notifProvider.isLoading
                  ? const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    )
                  : notifProvider.filteredNotifications.isEmpty
                      ? SliverToBoxAdapter(child: _buildEmptyState(notifProvider.selectedFilter))
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final notification = notifProvider.filteredNotifications[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                child: _buildNotificationCard(notification, notifProvider, auth.token),
                              );
                            },
                            childCount: notifProvider.filteredNotifications.length,
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(NotificationProvider provider) {
    final filters = [
      {'key': 'all', 'label': 'semua_5'.tr(context: context), 'icon': Icons.notifications_none},
      {'key': 'shift', 'label': 'shift_5'.tr(context: context), 'icon': Icons.access_time_rounded},
      {'key': 'stock', 'label': 'stok_rendah_11'.tr(context: context), 'icon': Icons.inventory_2_outlined},
      {'key': 'leave', 'label': 'cuti_izin_11'.tr(context: context), 'icon': Icons.event_busy_outlined},
      {'key': 'chat', 'label': 'chat_4'.tr(context: context), 'icon': Icons.chat_bubble_outline},
      {'key': 'reservation', 'label': 'reservasi_9'.tr(context: context), 'icon': Icons.calendar_month_outlined},
    ];

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final isSelected = provider.selectedFilter == f['key'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                showCheckmark: false,
                avatar: Icon(
                  f['icon'] as IconData,
                  size: 16,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
                label: Text(
                  f['label'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                  ),
                ),
                selected: isSelected,
                selectedColor: const Color(0xFF0D9488),
                backgroundColor: const Color(0xFFF1F5F9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF0D9488) : Colors.transparent,
                  ),
                ),
                onSelected: (selected) {
                  if (selected) {
                    provider.setFilter(f['key'] as String);
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    InAppNotificationModel notification,
    NotificationProvider provider,
    String? token,
  ) {
    final typeConfig = _getTypeConfig(notification.type);
    final timeStr = _formatTimestamp(notification.createdAt);

    return Dismissible(
      key: Key('notif_${notification.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      onDismissed: (direction) {
        provider.deleteNotification(notification.id, token: token);
      },
      child: InkWell(
        onTap: () {
          if (!notification.isRead) {
            provider.markAsRead(notification.id, token: token);
          }
          _handleAction(notification);
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: notification.isRead ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: notification.isRead
                  ? const Color(0xFFE2E8F0)
                  : const Color(0xFF99F6E4),
              width: notification.isRead ? 1 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: notification.isRead ? 0.02 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type Icon Badge
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: typeConfig.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(typeConfig.icon, color: typeConfig.color, size: 22),
              ),
              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w700,
                              fontSize: 14,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF0D9488),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: const Color(0xFF475569),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          timeStr,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_hasActionRoute(notification))
                          Row(
                            children: [
                              Text(
                                'open_btn'.tr(context: context),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: typeConfig.color,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(Icons.chevron_right, size: 16, color: typeConfig.color),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildEmptyState(String filter) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              size: 40,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'no_notifications_yet'.tr(context: context),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            filter == 'all'
                ? 'all_important_activities_here'.tr(context: context)
                : 'no_notifications_category'.tr(context: context),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasActionRoute(InAppNotificationModel notification) {
    final type = notification.type;
    return type.startsWith('shift') ||
        type == 'stock' ||
        type == 'low_stock' ||
        type.startsWith('permission') ||
        type == 'leave' ||
        type.startsWith('chat') ||
        type.startsWith('reservation');
  }

  void _handleAction(InAppNotificationModel notification) {
    final type = notification.type;
    final payload = notification.dataPayload;
    final route = payload?['route']?.toString();

    if (route == '/chat' || type.startsWith('chat')) {
      Navigator.of(context).pushNamed('/chat');
    } else if (route == '/shifts' || type.startsWith('shift')) {
      Navigator.of(context).pushNamed('/shifts');
    } else if (route == '/stock' || type == 'stock' || type == 'low_stock') {
      Navigator.of(context).pushNamed('/stock');
    } else if (route == '/permissions' || type.startsWith('permission') || type == 'leave') {
      Navigator.of(context).pushNamed('/permissions');
    } else if (route == '/reservations' || type.startsWith('reservation')) {
      Navigator.of(context).pushNamed('/reservations');
    }
  }

  _TypeConfig _getTypeConfig(String type) {
    if (type == 'shift' || type.startsWith('shift')) {
      return _TypeConfig(Icons.access_time_filled_rounded, const Color(0xFF6366F1));
    } else if (type == 'stock' || type == 'low_stock') {
      return _TypeConfig(Icons.warning_amber_rounded, const Color(0xFFF59E0B));
    } else if (type == 'leave' || type.startsWith('permission')) {
      return _TypeConfig(Icons.event_note_rounded, const Color(0xFFEC4899));
    } else if (type == 'chat' || type.startsWith('chat')) {
      return _TypeConfig(Icons.chat_bubble_rounded, const Color(0xFF0D9488));
    } else if (type == 'reservation' || type.startsWith('reservation')) {
      return _TypeConfig(Icons.calendar_month_rounded, const Color(0xFF3B82F6));
    }
    return _TypeConfig(Icons.notifications_rounded, const Color(0xFF64748B));
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'just_now'.tr(context: context);
    if (diff.inMinutes < 60) return 'minutes_ago'.tr(context: context, args: [diff.inMinutes.toString()]);
    if (diff.inHours < 24) return 'hours_ago'.tr(context: context, args: [diff.inHours.toString()]);
    if (diff.inDays == 1) return 'yesterday_at'.tr(context: context, args: [DateFormat('hhmm_5'.tr(context: context)).format(dt)]);
    if (diff.inDays < 7) return 'days_ago'.tr(context: context, args: [diff.inDays.toString()]);
    return DateFormat('dd MMM yyyy, HH:mm').format(dt);
  }
}

class _TypeConfig {
  final IconData icon;
  final Color color;
  _TypeConfig(this.icon, this.color);
}

