import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/api_config.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: "assets/.env");
    print("Successfully loaded .env file");
    // Test if we can access the API key
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    if (apiKey != null && apiKey.isNotEmpty) {
      print("API key loaded successfully: ${apiKey.substring(0, 10)}...");
      ApiConfig.setApiKey(apiKey);
    } else {
      print("Warning: API key is empty or null");
    }
  } catch (e) {
    print("Warning: Could not load .env file: $e");
    print("Make sure to create a .env file in the assets folder");
  }
  
  await Supabase.initialize(
    url: 'https://fjsrzduddrgciuytkrad.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZqc3J6ZHVkZHJnY2l1eXRrcmFkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA5MjAyNTUsImV4cCI6MjA2NjQ5NjI1NX0.LwyrVqvWKxLmoZZc7uzC8vvIkiYz9tjbN1f-zVXzR5g',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SAFRA App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF111416),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFCAE3F2),
          brightness: Brightness.dark,
        ),
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
        Locale('kn'),
      ],
      home: const LoginScreen(),
    );
  }
}
