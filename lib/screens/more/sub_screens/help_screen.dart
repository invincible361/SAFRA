import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import 'settings_screen.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [
    {"sender": "robot", "text": "Hi! I'm SAFRA HelpBot 🤖. I can answer common questions about the app. Ask me about **SOS**, **Safety Tips**, or **Settings**."},
  ];
  bool _isThinking = false;

  // Simple function to mock the robot's logic and response
  void _getRobotResponse(String userQuery) {
    String response;
    final lowerQuery = userQuery.toLowerCase();

    // Show thinking state
    setState(() {
      _isThinking = true;
    });
    _scrollToBottom();

    if (lowerQuery.contains("sos") || lowerQuery.contains("emergency button")) {
      response = "The **SOS Button** is for emergencies. Hold it for 3 seconds to immediately alert your emergency contacts, police (if enabled), and share your live location. Use it only when truly necessary!";
    } else if (lowerQuery.contains("safety tips") || lowerQuery.contains("security")) {
      response = "We provide structured advice on **Personal Safety**, **Travel**, **Public Transport**, and **Digital Security**. You can find all the tips in the dedicated 'Safety Tips' menu.";
    } else if (lowerQuery.contains("settings") || lowerQuery.contains("privacy")) {
      response = "Opening Settings for you... 📱";
      // Navigate to settings after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          );
        }
      });
    } else if (lowerQuery.contains("founder") || lowerQuery.contains("about")) {
      response = "SAFRA was created in 2024 by a dedicated team. Check the **About** screen for the full mission, features, and team details.";
    } else if (lowerQuery.contains("contact support")) {
      response = "For non-emergencies, please email us at **support@safra-app.com**. For emergencies, always use the SOS feature or call the local police number **100**.";
    } else {
      response = "I'm still learning! Could you please ask a different question related to SAFRA's features or safety? E.g., 'How to add contacts?'";
    }

    // Add robot response after a short delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      setState(() {
        _isThinking = false;
        _messages.add({"sender": "robot", "text": response});
      });
      _scrollToBottom();
    });
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    final userMessage = _controller.text.trim();

    setState(() {
      _messages.add({"sender": "user", "text": userMessage});
    });
    _controller.clear();
    _scrollToBottom();
    _getRobotResponse(userMessage);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, "HelpBot Chat"),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_isThinking ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isThinking && index == _messages.length) {
                      return _buildThinkingIndicator();
                    }
                    final message = _messages[index];
                    return _buildMessageBubble(message["text"]!, message["sender"] == "user");
                  },
                ),
              ),
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThinkingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
        decoration: BoxDecoration(
          color: AppColors.glassBackground,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft: const Radius.circular(0),
          ),
          border: Border.all(color: AppColors.glassBorder, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.smart_toy, color: AppColors.primaryAccent, size: 20),
            const SizedBox(width: 12),
            const Text(
              "Thinking",
              style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
            ),
            const SizedBox(width: 8),
            Row(
              children: List.generate(3, (index) => Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent,
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(),
              )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primaryAccent : AppColors.glassBackground,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(0),
          ),
          border: isUser ? null : Border.all(color: AppColors.glassBorder, width: 1),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : AppColors.textPrimary,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.glassBackground.withOpacity(0.8),
        border: Border(top: BorderSide(color: AppColors.glassBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: "Type your question here...",
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                border: InputBorder.none,
                filled: false,
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: AppColors.primaryAccent),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}