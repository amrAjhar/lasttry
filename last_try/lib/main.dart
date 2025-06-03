import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'firebase_options.dart';
import 'supabase_service.dart';
import 'login_page.dart';
import 'text_conversion_page.dart';
import 'profile_page.dart';
import 'tools_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('[main.dart] Firebase initialized successfully');
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      print('[main.dart] Firebase already initialized');
    } else {
      print('[main.dart] !!! Firebase initialization ERROR: $e');
      rethrow;
    }
  }

  try {
    await SupabaseServiceInitializer.initialize();
    print('[main.dart] Supabase initialization call completed.');
  } catch (e) {
    print('[main.dart] !!! Supabase initialization ERROR from Initializer: $e');
    return;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Text Converter App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue)
            .copyWith(error: Colors.red[700]),
      ),
      home: StreamBuilder<fb_auth.User?>(
        stream: fb_auth.FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            print("[MyApp] User is logged in: ${snapshot.data!.uid}. Navigating to TextConversionPage.");
            return const TextConversionPage();
          }
          print("[MyApp] User is not logged in. Navigating to LoginPage.");
          return const LoginPage();
        },
      ),
      routes: {
        '/login': (context) => const LoginPage(),
        '/text_conversion': (context) => const TextConversionPage(),
        '/profile': (context) => const ProfilePage(),
        '/tools': (context) => const ToolsPage(),
      },
    );
  }
}
