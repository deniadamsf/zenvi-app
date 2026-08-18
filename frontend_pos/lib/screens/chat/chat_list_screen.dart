import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import 'chat_room_screen.dart';
import '../../widgets/zenvi_header.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chat = Provider.of<ChatProvider>(context, listen: false);
      chat.fetchMessages();
      chat.fetchContacts();
    });
  }

  void _refreshMessages() {
    Provider.of<ChatProvider>(context, listen: false).fetchMessages();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          ZenviHeader.sliver(
            title: 'pesan_internal_14'.tr(context: context),
            subtitle: 'grup_karyawan_obrolan_pribadi_31'.tr(context: context),
            showBackButton: Navigator.of(context).canPop(),
            actions: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(Icons.forum_rounded, color: theme.colorScheme.primary, size: 20),
              ),
            ],
          ),
          
          SliverPadding(
            padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 120.0),
            sliver: Consumer<ChatProvider>(
              builder: (context, chat, child) {
                if (chat.isLoading && chat.messages.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    )),
                  );
                }

                final lastMessage = chat.messages.isNotEmpty ? chat.messages.last.message : 'belum_ada_pesan_15'.tr(context: context);
                final lastTime = chat.messages.isNotEmpty 
                    ? '${chat.messages.last.createdAt.hour.toString().padLeft(2, '0')}:${chat.messages.last.createdAt.minute.toString().padLeft(2, '0')}'
                    : '';

                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final myId = authProvider.user?.id;
                final contacts = chat.contacts.where((c) => c.id != myId).toList();
                final companyLogo = authProvider.user?.company?['logo_url']?.toString();
                final companyName = authProvider.user?.company?['name']?.toString() ?? 'toko_4'.tr(context: context);

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == 0) {
                        // Group Chat Item
                        return _buildChatBubbleCard(
                          context: context,
                          theme: theme,
                          title: 'Grup Internal $companyName',
                          subtitle: lastMessage,
                          time: lastTime,
                          isGroup: true,
                          logoUrl: companyLogo,
                          unreadCount: 0, // Placeholder if unread count logic added later
                          onTap: () {
                            Navigator.push(
                              context, 
                              MaterialPageRoute(
                                builder: (_) => ChatRoomScreen(
                                  contactName: 'Grup Internal $companyName',
                                  contactRole: 'Semua Karyawan',
                                  isOnline: true,
                                  receiverId: null,
                                )
                              )
                            ).then((_) => _refreshMessages());
                          }
                        ).animate().fade(delay: 50.ms).slideY(begin: 0.1, end: 0);
                      }

                      final contact = contacts[index - 1];
                      final isOwner = contact.role.toLowerCase() == 'owner';
                      final contactLastTime = contact.lastMessageTime != null 
                          ? '${contact.lastMessageTime!.hour.toString().padLeft(2, '0')}:${contact.lastMessageTime!.minute.toString().padLeft(2, '0')}'
                          : '';

                      return _buildChatBubbleCard(
                        context: context,
                        theme: theme,
                        title: contact.name,
                        subtitle: contact.lastMessage,
                        time: contactLastTime,
                        isGroup: false,
                        isOwner: isOwner,
                        logoUrl: companyLogo, // Only used if owner
                        unreadCount: 0,
                        onTap: () {
                          Navigator.push(
                            context, 
                            MaterialPageRoute(
                              builder: (_) => ChatRoomScreen(
                                contactName: contact.name,
                                contactRole: contact.role,
                                isOnline: true, // Mock online status
                                receiverId: contact.id,
                              )
                            )
                          ).then((_) => _refreshMessages());
                        }
                      ).animate().fade(delay: (50 + (index * 20)).ms).slideY(begin: 0.1, end: 0);
                    },
                    childCount: contacts.length + 1, // +1 for the group chat
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubbleCard({
    required BuildContext context,
    required ThemeData theme,
    required String title,
    required String subtitle,
    required String time,
    required bool isGroup,
    bool isOwner = false,
    String? logoUrl,
    int unreadCount = 0,
    required VoidCallback onTap,
  }) {
    final avatarColor = isGroup 
        ? theme.colorScheme.primary 
        : (isOwner ? theme.colorScheme.primary : theme.colorScheme.secondary);
        
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ]
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Avatar / Bubble Profile
                Stack(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: avatarColor.withValues(alpha: 0.1),
                        border: Border.all(
                          color: avatarColor.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: ClipOval(
                        child: _buildAvatarImage(isGroup, isOwner, logoUrl, title, avatarColor),
                      ),
                    ),
                    if (!isGroup) // Online indicator for direct messages
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981), // Modern green
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.colorScheme.surface, width: 2.5),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                
                // Chat Info (Bubble Content)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (time.isNotEmpty)
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: 12, 
                                fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                color: unreadCount > 0 ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: unreadCount > 0 ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant, 
                                fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                                fontSize: 14
                              ),
                            ),
                          ),
                          if (unreadCount > 0)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                unreadCount.toString(),
                                style: TextStyle(
                                  color: theme.colorScheme.onPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
      ),
    );
  }

  Widget _buildAvatarImage(bool isGroup, bool isOwner, String? logoUrl, String name, Color avatarColor) {
    if (isGroup) {
      if (logoUrl != null && logoUrl.isNotEmpty) {
        return Image.network(
          logoUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Icon(Icons.storefront_rounded, color: avatarColor, size: 28),
        );
      }
      return Icon(Icons.groups_rounded, color: avatarColor, size: 28);
    } else {
      if (isOwner && logoUrl != null && logoUrl.isNotEmpty) {
        return Image.network(
          logoUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Center(
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: TextStyle(color: avatarColor, fontWeight: FontWeight.bold, fontSize: 20)),
          ),
        );
      }
      return Center(
        child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: TextStyle(color: avatarColor, fontWeight: FontWeight.bold, fontSize: 20)),
      );
    }
  }
}
