import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/enhanced_language_service.dart';
import '../widgets/translated_text.dart';
// Removed DigiLocker imports for now

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  final bool _isLoading = false;
  bool _isTyping = false;
  String? _currentUserId;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      _currentUser = Supabase.instance.client.auth.currentUser;
      _currentUserId = _currentUser?.id;
      
      if (_currentUserId != null) {
        await _loadMessages();
        _setupRealtimeSubscription();
      }
    } catch (e) {
      print('Error initializing chat: $e');
    }
  }

  Future<void> _loadMessages() async {
    try {
      print('Loading messages...');
      final response = await Supabase.instance.client
          .from('community_messages')
          .select('*')
          .order('created_at', ascending: true)
          .limit(100); // Increased limit to show more messages

      print('Messages loaded: ${response.length}');
      print('Response data: $response'); // Debug the actual data
      
      setState(() {
        _messages = (response as List)
            .map((msg) => ChatMessage.fromJson(msg))
            .toList();
      });

      print('Messages in state: ${_messages.length}');
      print('Evidence messages: ${_messages.where((m) => m.isEvidence).length}'); // Count evidence messages
      _scrollToBottom();
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  void _setupRealtimeSubscription() {
    print('Setting up realtime subscription...');
    Supabase.instance.client
        .from('community_messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .listen((data) {
      print('Realtime update received: ${data.length} messages');
      print('Realtime data: $data'); // Debug the realtime data
      setState(() {
        _messages = data.map((msg) => ChatMessage.fromJson(msg)).toList();
      });
      print('Evidence messages after realtime update: ${_messages.where((m) => m.isEvidence).length}');
      _scrollToBottom();
    }, onError: (error) {
      print('Realtime subscription error: $error');
    });
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _currentUserId == null) return;

    print('Sending message: $messageText');
    
    try {
      final message = {
        'user_id': _currentUserId,
        'user_email': _currentUser?.email ?? 'Unknown',
        'user_name': _currentUser?.userMetadata?['full_name'] ?? 'Anonymous',
        'message': messageText,
        'created_at': DateTime.now().toIso8601String(),
      };

      print('Message data: $message');
      
      final response = await Supabase.instance.client
          .from('community_messages')
          .insert(message);
      
      print('Message sent successfully: $response');

      _messageController.clear();
      setState(() => _isTyping = false);
      
      // Force reload messages to ensure they appear
      await _loadMessages();
      
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageService = context.watch<EnhancedLanguageService>();
    
    return Scaffold(
      backgroundColor: const Color(0xFF111416),
      appBar: AppBar(
        title: TranslatedText(
          text: 'Community Chat',
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF1A1D21),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info, color: Colors.blue),
            onPressed: () => _showCommunityInfo(),
            tooltip: 'Community Info',
          ),
        ],
      ),
      body: Column(
        children: [
          // Community Info Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1D21),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.group, color: Color(0xFFCAE3F2)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TranslatedText(
                        text: 'SAFRA Community',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TranslatedText(
                        text: 'Connect with verified users',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green),
                  ),
                  child: TranslatedText(
                    text: '${_messages.length} members',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        TranslatedText(
                          text: 'Welcome to SAFRA Community!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TranslatedText(
                          text: 'Start the conversation below',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMe = message.userId == _currentUserId;
                      print('Building message $index: ${message.message} (isMe: $isMe)');
                      return _buildMessageBubble(message, isMe);
                    },
                  ),
          ),

          // Typing Indicator
          if (_isTyping)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(width: 40),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.grey[400]!,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TranslatedText(
                          text: 'Someone is typing...',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Message Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1D21),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    onChanged: (value) {
                      setState(() {
                        _isTyping = value.isNotEmpty;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFCAE3F2),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFCAE3F2),
              child: Text(
                message.userName.isNotEmpty 
                    ? message.userName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFFCAE3F2) : Colors.grey[800],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(
                      message.userName,
                      style: TextStyle(
                        color: isMe ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  const SizedBox(height: 4),
                  // Evidence indicator if this is an evidence post
                  if (message.isEvidence)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.assignment, color: Colors.orange, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Evidence: ${message.evidenceCategory ?? "Unknown"}',
                            style: TextStyle(
                              color: isMe ? Colors.orange[800] : Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (message.evidenceSeverity != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              'Severity: ${message.evidenceSeverity!.toStringAsFixed(1)}/5',
                              style: TextStyle(
                                color: isMe ? Colors.orange[700] : Colors.orange[300],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isMe ? Colors.black : Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  // Display evidence photos if available
                  if (message.isEvidence && message.evidencePhotoUrls != null && message.evidencePhotoUrls!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildEvidencePhotos(message.evidencePhotoUrls!, isMe),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      color: isMe ? Colors.black54 : Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFCAE3F2),
              child: Text(
                _currentUser?.userMetadata?['full_name']?[0]?.toUpperCase() ?? 'U',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Widget _buildEvidencePhotos(List<String> photoUrls, bool isMe) {
    if (photoUrls.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (photoUrls.length == 1)
            // Single photo - display larger
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                photoUrls.first,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  );
                },
              ),
            )
          else
            // Multiple photos - display in grid
            SizedBox(
              height: 150,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                  childAspectRatio: 1.5,
                ),
                itemCount: photoUrls.length > 4 ? 4 : photoUrls.length,
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          photoUrls[index],
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[800],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[800],
                              child: const Icon(Icons.broken_image, color: Colors.grey),
                            );
                          },
                        ),
                        if (index == 3 && photoUrls.length > 4)
                          Container(
                            color: Colors.black.withOpacity(0.6),
                            child: Center(
                              child: Text(
                                '+${photoUrls.length - 4}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showCommunityInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D21),
        title: TranslatedText(
          text: 'Community Info',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TranslatedText(
              text: 'Welcome to SAFRA Community!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TranslatedText(
              text: '• Chat with other SAFRA users',
              style: const TextStyle(color: Colors.white),
            ),
            TranslatedText(
              text: '• Share safety tips and experiences',
              style: const TextStyle(color: Colors.white),
            ),
            TranslatedText(
              text: '• Get help from the community',
              style: const TextStyle(color: Colors.white),
            ),
            TranslatedText(
              text: '• Stay connected and informed',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            TranslatedText(
              text: 'Be respectful and helpful to fellow community members!',
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCAE3F2),
              foregroundColor: Colors.black,
            ),
            child: TranslatedText(
              text: 'Got it!',
              style: const TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String id;
  final String userId;
  final String userEmail;
  final String userName;
  final String message;
  final DateTime createdAt;
  final bool isEvidence;
  final String? evidenceCategory;
  final double? evidenceSeverity;
  final String? evidenceLocation;
  final DateTime? evidenceDate;
  final int? evidenceMediaCount;
  final List<String>? evidenceTags;
  final String? evidenceNotes;
  final List<String>? evidencePhotoUrls;
  final List<String>? evidenceVideoUrls;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.message,
    required this.createdAt,
    this.isEvidence = false,
    this.evidenceCategory,
    this.evidenceSeverity,
    this.evidenceLocation,
    this.evidenceDate,
    this.evidenceMediaCount,
    this.evidenceTags,
    this.evidenceNotes,
    this.evidencePhotoUrls,
    this.evidenceVideoUrls,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      userId: json['user_id'] ?? '',
      userEmail: json['user_email'] ?? '',
      userName: json['user_name'] ?? '',
      message: json['message'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      isEvidence: json['is_evidence'] ?? false,
      evidenceCategory: json['evidence_category'],
      evidenceSeverity: json['evidence_severity']?.toDouble(),
      evidenceLocation: json['evidence_location'],
      evidenceDate: json['evidence_date'] != null ? DateTime.parse(json['evidence_date']) : null,
      evidenceMediaCount: json['evidence_media_count'],
      evidenceTags: json['evidence_tags'] != null ? List<String>.from(json['evidence_tags']) : null,
      evidenceNotes: json['evidence_notes'],
      evidencePhotoUrls: json['evidence_photo_urls'] != null ? List<String>.from(json['evidence_photo_urls']) : null,
      evidenceVideoUrls: json['evidence_video_urls'] != null ? List<String>.from(json['evidence_video_urls']) : null,
    );
  }
}