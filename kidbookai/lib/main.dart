import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'landing_page.dart';
import 'signup_page.dart';
import 'signin_page.dart';
import 'profile_page.dart';

//pages import
import 'toolkits/custom_agent_page.dart';
import 'toolkits/ai_slides_page.dart';
import 'toolkits/ai_docs_page.dart';
import 'toolkits/ai_developer_page.dart';
import 'toolkits/ai_designer_page.dart';
import 'toolkits/clip_genius_page.dart';
import 'toolkits/resume_roast/resume_roast.dart';
import 'toolkits/ai_image_page.dart';
import 'toolkits/ai_video_page.dart';
import 'toolkits/ai_meeting_notes_page.dart';
import 'toolkits/book_generation/book_generation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyBFp8R1cOJvOzwj7-wtAIM5C2Vdb1heRj8",
        authDomain: "kidbookai-7352c.firebaseapp.com",
        projectId: "kidbookai-7352c",
        storageBucket: "kidbookai-7352c.firebasestorage.app",
        messagingSenderId: "851966187384",
        appId: "1:851966187384:web:1dca7b2f446ee6b6a7da8d",
      ),
    );
    print('✅ Firebase initialized successfully!');
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    // Listen to auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      setState(() {
        _currentUser = user;
      });
    });
  }

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KiddoBookAI',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,

      /// 🌞 LIGHT THEME
      theme: ThemeData(
        useMaterial3: false,
        brightness: Brightness.light,
        primaryColor: Colors.orange,
        colorScheme: const ColorScheme.light(
          primary: Colors.orange,
          secondary: Colors.orange,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey.shade800,
            side: BorderSide(color: Colors.grey.shade400),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),

      /// 🌙 DARK THEME
      darkTheme: ThemeData(
        useMaterial3: false,
        brightness: Brightness.dark,
        primaryColor: Colors.orange,
        colorScheme: const ColorScheme.dark(
          primary: Colors.orange,
          secondary: Colors.orange,
        ),
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey.shade300,
            side: BorderSide(color: Colors.grey.shade700),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),

      // Routes
      initialRoute: '/',
      routes: {
        '/': (context) =>
            LandingPage(onToggleTheme: toggleTheme, currentUser: _currentUser),
        '/home': (context) =>
            LandingPage(onToggleTheme: toggleTheme, currentUser: _currentUser),
        '/signin': (context) => SignInPage(
          onToggleTheme: toggleTheme,
          onSignInSuccess: () {
            Navigator.pushReplacementNamed(context, '/home');
          },
        ),
        '/signup': (context) => SignUpPage(
          onToggleTheme: toggleTheme,
          onSignUpSuccess: () {
            Navigator.pushReplacementNamed(context, '/home');
          },
        ),
        '/profile': (context) =>
            ProfilePage(onToggleTheme: toggleTheme, currentUser: _currentUser),

        // Feature page routes
        '/custom-agent': (context) =>
            CustomAgentPage(onToggleTheme: toggleTheme),
        '/ai-slides': (context) => AISlidesPage(onToggleTheme: toggleTheme),
        '/ai-docs': (context) => AIDocsPage(onToggleTheme: toggleTheme),
        '/ai-developer': (context) =>
            AIDeveloperPage(onToggleTheme: toggleTheme),
        '/ai-designer': (context) => AIDesignerPage(onToggleTheme: toggleTheme),
        '/clip-genius': (context) => ClipGeniusPage(onToggleTheme: toggleTheme),
        '/Resume-Roast': (context) => ResumeAnalysisPage(
          onToggleTheme: toggleTheme,
          backendUrl: 'http://127.0.0.1:5000',
        ),
        '/ai-image': (context) => AIImagePage(onToggleTheme: toggleTheme),
        '/ai-video': (context) => AIVideoPage(onToggleTheme: toggleTheme),
        '/ai-meeting-notes': (context) =>
            AIMeetingNotesPage(onToggleTheme: toggleTheme),
        '/BookGeneration': (context) => BookGeneration(
          onToggleTheme: toggleTheme,
          backendUrl: 'http://127.0.0.1:5000',
        ),
      },
    );
  }
}
