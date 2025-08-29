import 'package:flutter/material.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({Key? key}) : super(key: key);

  final List<Map<String, dynamic>> moreOptions = const [
    {"icon": Icons.help_outline, "title": "Help"},
    {"icon": Icons.safety_check_outlined, "title": "Safety Tips"},
    {"icon": Icons.settings, "title": "Settings"},
    {"icon": Icons.info_outline, "title": "About"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("More"),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: ListView.builder(
        itemCount: moreOptions.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Icon(moreOptions[index]["icon"], color: Colors.white),
            title: Text(
              moreOptions[index]["title"],
              style: const TextStyle(color: Colors.white),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SubOptionScreen(
                    title: moreOptions[index]["title"],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class SubOptionScreen extends StatelessWidget {
  final String title;
  const SubOptionScreen({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
