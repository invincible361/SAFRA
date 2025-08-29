import 'package:flutter/material.dart';
import '../config/app_colors.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final List<Map<String, String>> posts = [
    {
      "username": "Aakansha",
      "content": "Just completed my first safe night walk feeling confident!",
      "time": "2h ago"
    },
    {
      "username": "Priya",
      "content": "Does anyone know safe routes from MG Road to Connaught Place?",
      "time": "5h ago"
    },
    {
      "username": "Riya",
      "content": "Tip: Always share your live location with friends during night travel.",
      "time": "1d ago"
    },
  ];

  final TextEditingController _postController = TextEditingController();

  void _addPost() {
    if (_postController.text.trim().isNotEmpty) {
      setState(() {
        posts.insert(0, {
          "username": "You",
          "content": _postController.text.trim(),
          "time": "Just now"
        });
      });
      _postController.clear();
    }
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
              // App Bar
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Community",
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Column(
                  children: [
                    // ======== Post Input Box ========
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.glassBackground,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.glassBorder,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: CircleAvatar(
                                backgroundColor: AppColors.primaryAccent,
                                child: Icon(Icons.person, color: AppColors.textPrimary),
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _postController,
                                style: const TextStyle(color: AppColors.textPrimary),
                                decoration: const InputDecoration(
                                  hintText: "Share something with the community...",
                                  hintStyle: TextStyle(color: AppColors.textSecondary),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _addPost,
                              icon: const Icon(Icons.send, color: AppColors.primaryAccent),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ======== Community Feed ========
                    Expanded(
                      child: ListView.builder(
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          final post = posts[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.glassBackground,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.glassBorder,
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Username + Time
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: AppColors.primaryAccent.withOpacity(0.2),
                                        child: Icon(Icons.person,
                                            color: AppColors.primaryAccent),
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            post["username"]!,
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            post["time"]!,
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  // Post Content
                                  Text(
                                    post["content"]!,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Like & Comment Buttons
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () {},
                                        icon: const Icon(Icons.thumb_up_alt_outlined,
                                            color: AppColors.textSecondary, size: 20),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () {},
                                        icon: const Icon(Icons.comment_outlined,
                                            color: AppColors.textSecondary, size: 20),
                                      ),
                                    ],
                                  ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
