import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventory_management/provider/chat_provider.dart';
import 'package:inventory_management/provider/support_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'Custom-Files/colors.dart';

class Message {
  final String id;
  final String sender;
  final String text;
  final DateTime timestamp;
  final bool isPending;
  final String userRole;

  Message({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    required this.userRole,
    this.isPending = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'sender': sender,
      'text': text,
      'timestamp': timestamp,
      'userRole': userRole,
    };
  }
}

class ChatScreen extends StatefulWidget {
  // final String orderId;
  // final String currentUserEmail;
  // final String currentUserRole;

  const ChatScreen({
    Key? key,
    // required this.orderId,
    // required this.currentUserEmail,
    // required this.currentUserRole,
  }) : super(key: key);

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToBottom = false;
  List<Message> _localMessages = [];
  late ChatProvider chatProvider;
  late SupportProvider supportProvider;
  String? userName;

  @override
  void initState() {
    chatProvider = Provider.of<ChatProvider>(context, listen: false);
    supportProvider = Provider.of<SupportProvider>(context, listen: false);
    userName = supportProvider.currentUserEmail?.split('@')[0] ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializeChat(supportProvider.orderId ?? '', supportProvider.currentUserEmail ?? '', supportProvider.currentUserRole ?? '');
    });

    _scrollController.addListener(() {
      setState(() {
        _showScrollToBottom = _scrollController.offset > 100;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void initializeChat(String orderId, String userEmail, String userRole) {
    chatProvider.initializeChat(orderId, userEmail, userRole);
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _handleSendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final pendingMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: supportProvider.currentUserEmail ?? '',
      text: text,
      timestamp: DateTime.now(),
      userRole: supportProvider.currentUserRole ?? '',
      isPending: true,
    );

    setState(() {
      _localMessages.insert(0, pendingMessage);
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      await Provider.of<ChatProvider>(context, listen: false).sendMessage(text);

      setState(() {
        _localMessages.removeWhere((msg) => msg.id == pendingMessage.id);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: const Text('Failed to send message'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _handleSendMessage(),
          ),
        ),
      );
    }
  }

  void _showDeleteMenu(BuildContext context, Offset position, String messageId) {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(position, position),
        Offset.zero & overlay.size,
      ),
      items: [
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: const [
              Icon(Icons.delete, color: Colors.red),
              SizedBox(width: 10),
              Text('Delete Message'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'delete') {
        _deleteMessage(messageId);
      }
    });
  }

  void _deleteMessage(String messageId) async {
    try {
      await Provider.of<ChatProvider>(context, listen: false).deleteMessage(messageId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete message: $e')),
      );
    }
  }

  @override
  // Widget build(BuildContext context) {
  //   return SelectionArea(
  //     child: Scaffold(
  //       appBar: AppBar(
  //         elevation: 2,
  //         backgroundColor: AppColors.primaryBlue,
  //         leadingWidth: 40,
  //         leading: BackButton(
  //           color: Colors.white,
  //           onPressed: () => Navigator.of(context).pop(),
  //         ),
  //         title: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(
  //               supportProvider.orderId,
  //               style: const TextStyle(
  //                 color: Colors.white,
  //                 fontWeight: FontWeight.w600,
  //                 fontSize: 18,
  //               ),
  //             ),
  //             Row(
  //               children: [
  //                 Container(
  //                   width: 8,
  //                   height: 8,
  //                   margin: const EdgeInsets.only(right: 6),
  //                   decoration: const BoxDecoration(
  //                     color: Colors.greenAccent,
  //                     shape: BoxShape.circle,
  //                   ),
  //                 ),
  //                 Text(
  //                   "$userName • ${supportProvider.currentUserRole}",
  //                   style: const TextStyle(
  //                     color: Colors.white70,
  //                     fontSize: 13,
  //                     fontWeight: FontWeight.normal,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ],
  //         ),
  //       ),
  //       body: Container(
  //         color: Colors.grey[50],
  //         child: Column(
  //           children: [
  //             _chatHeader(),
  //             Expanded(
  //               child: GestureDetector(
  //                 onTap: () => FocusScope.of(context).unfocus(),
  //                 child: _buildMessageList(),
  //               ),
  //             ),
  //             _buildMessageInput(),
  //           ],
  //         ),
  //       ),
  //       floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
  //       floatingActionButton: AnimatedOpacity(
  //         opacity: _showScrollToBottom ? 1.0 : 0.0,
  //         duration: const Duration(milliseconds: 200),
  //         child: _showScrollToBottom
  //             ? FloatingActionButton(
  //                 tooltip: 'Scroll to bottom',
  //                 backgroundColor: Colors.white,
  //                 elevation: 4,
  //                 onPressed: _scrollToBottom,
  //                 child: const Icon(Icons.keyboard_arrow_down, color: AppColors.primaryBlue),
  //               )
  //             : null,
  //       ),
  //     ),
  //   );
  // }

  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.4,
      child: SelectionArea(
        child: Column(
          children: [
            _chatHeader(),
            Expanded(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: _buildMessageList(),
              ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .doc(supportProvider.orderId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData && _localMessages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading messages...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        List<Message> allMessages = [];

        if (snapshot.hasData) {
          final firebaseMessages = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Message(
              id: doc.id,
              sender: data['sender'],
              text: data['text'],
              timestamp: data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate() : DateTime.now(),
              userRole: data['userRole'] ?? 'User',
            );
          }).toList();

          allMessages.addAll(firebaseMessages);
        }

        allMessages.insertAll(0, _localMessages);

        if (allMessages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No messages yet',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start the conversation by sending a message',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          itemCount: allMessages.length,
          itemBuilder: (context, index) {
            final message = allMessages[index];
            final bool isMe = message.sender == supportProvider.currentUserEmail;
            final DateTime istTime = message.timestamp.toLocal().add(const Duration(hours: 5, minutes: 30));
            final String time = DateFormat('hh:mm a').format(istTime);
            final String username = message.sender.split('@')[0];

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isMe ? 'You' : username,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Text(
                          ' • ',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          message.userRole,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isMe ? AppColors.primaryBlue : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: Radius.circular(isMe ? 20 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 20),
                            ),
                            boxShadow: [
                              BoxShadow(
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                                color: Colors.black.withValues(alpha: 0.1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.text,
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black87,
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    time,
                                    style: TextStyle(
                                      color: isMe ? Colors.white70 : Colors.grey[600],
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (isMe)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: Icon(
                                        message.isPending ? Icons.access_time : Icons.done_all,
                                        size: 14,
                                        color: Colors.white70,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            blurRadius: 8,
            color: Colors.black.withValues(alpha: 0.06),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.grey[50],
                  border: Border.all(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 5,
                  minLines: 1,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.4,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _handleSendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(0, 2),
                    blurRadius: 6,
                    color: AppColors.primaryBlue.withValues(alpha: 0.3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(25),
                  onTap: _handleSendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chatHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.support_agent, color: Colors.blue.shade700, size: 24),
              const SizedBox(width: 8),
              Text(
                "Order Support Chat",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Use this chat to discuss and resolve order-related issues.",
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.orange.shade800),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "This chat is monitored by administrators. Please keep the discussion focused on order-related issues only.",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade900,
                      height: 1.3,
                    ),
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
