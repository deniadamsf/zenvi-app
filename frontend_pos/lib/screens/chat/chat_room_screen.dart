import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/zenvi_header.dart';

class ChatRoomScreen extends StatefulWidget {
  final String contactName;
  final String contactRole;
  final bool isOnline;
  final int? receiverId;

  const ChatRoomScreen({
    super.key,
    required this.contactName,
    required this.contactRole,
    required this.isOnline,
    this.receiverId,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false).fetchMessages(receiverId: widget.receiverId);
    });
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    _messageController.clear();
    final success = await Provider.of<ChatProvider>(context, listen: false).sendMessage(text, receiverId: widget.receiverId);
    
    if (success) {
      // Auto scroll to bottom
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final companyLogo = authProvider.user?.company?['logo_url']?.toString();
    final isGroupChat = widget.receiverId == null;
    final isContactOwner = widget.contactRole.toLowerCase() == 'owner';
    final showCompanyLogoInHeader = (isGroupChat || isContactOwner) && companyLogo != null && companyLogo.isNotEmpty;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: ZenviHeader(
        showBackButton: true,
        titleWidget: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: ClipOval(
                child: showCompanyLogoInHeader
                    ? Image.network(
                        companyLogo,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Text(
                            widget.contactName.isNotEmpty ? widget.contactName[0].toUpperCase() : 'Z',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          widget.contactName.isNotEmpty ? widget.contactName[0].toUpperCase() : 'Z',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.contactName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.isOnline ? 'Online • ${widget.contactRole}' : 'Offline • ${widget.contactRole}',
                    style: TextStyle(
                      fontSize: 11,
                      color: widget.isOnline ? AppColors.successText : theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Consumer2<ChatProvider, AuthProvider>(
        builder: (context, chat, auth, child) {
          if (chat.isLoading && chat.messages.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentUser = auth.user;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
                    left: 16,
                    right: 16,
                    bottom: 16,
                  ),
                  itemCount: chat.messages.length,
                  itemBuilder: (context, index) {
                    final msg = chat.messages[chat.messages.length - 1 - index];
                    final isMe = currentUser != null && msg.senderId == currentUser.id;
                    final isSenderOwner = msg.senderRole.toLowerCase() == 'owner';
                    final showSenderLogo = isSenderOwner && companyLogo != null && companyLogo.isNotEmpty;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isMe) ...[
                            Container(
                              width: 32,
                              height: 32,
                              margin: const EdgeInsets.only(right: 8, bottom: 2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (isSenderOwner ? theme.colorScheme.primary : theme.colorScheme.secondary).withValues(alpha: 0.1),
                                border: Border.all(
                                  color: (isSenderOwner ? theme.colorScheme.primary : theme.colorScheme.secondary).withValues(alpha: 0.25),
                                  width: 1,
                                ),
                              ),
                              child: ClipOval(
                                child: showSenderLogo
                                    ? Image.network(
                                        companyLogo,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Center(
                                          child: Text(
                                            msg.senderName.isNotEmpty ? msg.senderName[0].toUpperCase() : '?',
                                            style: TextStyle(
                                              color: theme.colorScheme.primary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          msg.senderName.isNotEmpty ? msg.senderName[0].toUpperCase() : '?',
                                          style: TextStyle(
                                            color: isSenderOwner ? theme.colorScheme.primary : theme.colorScheme.secondary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ],
                          Flexible(
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.72,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isMe ? theme.colorScheme.primary : theme.colorScheme.surface,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(20),
                                  topRight: const Radius.circular(20),
                                  bottomLeft: Radius.circular(isMe ? 20 : 0),
                                  bottomRight: Radius.circular(isMe ? 0 : 20),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.shadowColor.withValues(alpha: 0.05),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  if (!isMe && isGroupChat)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 2),
                                      child: Text(
                                        '${msg.senderName} (${msg.senderRole})',
                                        style: TextStyle(
                                          color: isSenderOwner ? theme.colorScheme.primary : theme.colorScheme.secondary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  Text(
                                    msg.message,
                                    style: TextStyle(
                                      color: isMe ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('hhmm_5'.tr(context: context)).format(msg.createdAt),
                                    style: TextStyle(
                                      color: isMe ? Colors.white70 : theme.colorScheme.onSurfaceVariant,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          
          // Chat Input Area
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withValues(alpha: 0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ]
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: 'chat_message_hint'.tr(context: context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
        },
      ),
    );
  }
}
