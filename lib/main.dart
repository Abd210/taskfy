import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ui/app_theme.dart';
import 'ui/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/task_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const TaskfyApp());
}

class TaskfyApp extends StatelessWidget {
  const TaskfyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        final user = authSnap.data;
        if (user == null) {
          // Logged out: default theme
          return ThemeProvider(
            themeKey: 'white',
            child: MaterialApp(
              title: 'Taskfy',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.themeFor('white'),
              home: const AuthWrapper(),
            ),
          );
        }

        // Logged in: listen to userSettings for theme changes
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('userSettings')
              .doc(user.uid)
              .snapshots(),
          builder: (context, settingsSnap) {
            String themeKey = 'white';
            if (settingsSnap.hasData && settingsSnap.data?.data() != null) {
              final data = settingsSnap.data!.data()!;
              themeKey = (data['theme']?.toString() ?? 'white');
            }
            return ThemeProvider(
              themeKey: themeKey,
              child: MaterialApp(
                title: 'Taskfy',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.themeFor(themeKey),
                home: const AuthWrapper(),
              ),
            );
          },
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (snapshot.hasData) {
          return const TaskScreen();
        } else {
          return const AuthScreen();
        }
      },
    );
  }
}