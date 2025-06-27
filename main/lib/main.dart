import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:main/SkillSelectionPage.dart';

import 'home_page.dart';
import 'login_page.dart';
import 'SkillSelectionPage.dart'; // Make sure to import your SkillSelectionPage

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await initializeFirebase();
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }

  runApp(const SkillExchangeApp());
}

// 🔹 Firebase Initialization Function
Future<void> initializeFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyBEuxVAIyLAV_8_u2lmax2pnQ0rxg_KI9I",
        authDomain: "skill-swap-x.firebaseapp.com",
        projectId: "skill-swap-x",
        storageBucket: "skill-swap-x.appspot.com",
        messagingSenderId: "515487126722",
        appId: "1:515487126722:web:cd2d5443e1f34f1c2dd75b",
        measurementId: "G-357YH5RHQ2",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
}

class SkillExchangeApp extends StatelessWidget {
  const SkillExchangeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Skill Exchange',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.grey,
        textTheme: TextTheme(
          bodyLarge: GoogleFonts.robotoMono(color: Colors.white),
          bodyMedium: GoogleFonts.robotoMono(color: Colors.white),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

// 🔹 Handles user authentication state and first-time skill selection
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late Future<void> _firebaseInit;

  @override
  void initState() {
    super.initState();
    _firebaseInit = initializeFirebase();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _firebaseInit,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Error initializing Firebase",
                    style: GoogleFonts.robotoMono(color: Colors.red),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _firebaseInit = initializeFirebase();
                      });
                    },
                    child: const Text("Retry"),
                  ),
                ],
              ),
            ),
          );
        }

        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // If user is logged in, check for first-time skill selection
            if (snapshot.hasData) {
              return FirstTimeSkillCheckPage();
            }

            // If no user is logged in, show login page
            return LoginPage();
          },
        );
      },
    );
  }
}

// 🔹 Check if user has completed first-time skill selection
class FirstTimeSkillCheckPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return LoginPage();
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection("userskillset")
          .doc(user.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Check if first-time setup is completed
        if (!snapshot.hasData ||
            !snapshot.data!.exists ||
            (snapshot.data!.data()
                    as Map<String, dynamic>?)?['firstTimeSetupCompleted'] !=
                true) {
          // If not completed, show skill selection page
          return SkillSelectionPage();
        }

        // If completed, show home page
        return HomePage();
      },
    );
  }
}
