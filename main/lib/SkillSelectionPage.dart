import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_page.dart';
import 'home_page.dart';

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

class FirstTimeSkillCheckPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return LoginPage();
    }

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection("users").doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Explicitly check for first-time setup
        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        bool hasCompletedSetup = userData?['skillsSetupComplete'] == true;

        if (!hasCompletedSetup) {
          return SkillSelectionPage();
        }

        return HomePage();
      },
    );
  }
}

class SkillSelectionPage extends StatefulWidget {
  @override
  _SkillSelectionPageState createState() => _SkillSelectionPageState();
}

class _SkillSelectionPageState extends State<SkillSelectionPage> {
  final List<String> _skills = [
    'Editing',
    'Photography',
    'Teaching',
    'Designing',
    'Marketing',
    'Coding',
    'Cooking',
    'Writing',
    'Music',
    'Fitness',
    'Public Speaking',
    'Translation',
    'Painting',
    'Singing',
    'Acting',
    'Dancing',
    'Crafting',
    'Gaming',
    'Videography',
    'Tutoring'
  ];

  final Set<String> _selectedSkills = {};
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const int maxSkills = 3;

  void _toggleSkill(String skill) {
    setState(() {
      if (_selectedSkills.contains(skill)) {
        _selectedSkills.remove(skill);
      } else if (_selectedSkills.length < maxSkills) {
        _selectedSkills.add(skill);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("You can only select up to $maxSkills skills.")),
        );
      }
    });
  }

  Future<void> _saveSkillsAndProceed() async {
    final user = _auth.currentUser;
    if (user != null && _selectedSkills.isNotEmpty) {
      await _firestore.collection("users").doc(user.uid).set(
          {"skills": _selectedSkills.toList(), "skillsSetupComplete": true},
          SetOptions(merge: true));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one skill.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Pick up to $maxSkills skills",
                textAlign: TextAlign.center,
                style: GoogleFonts.robotoMono(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _skills.length,
                  itemBuilder: (context, index) {
                    final skill = _skills[index];
                    final isSelected = _selectedSkills.contains(skill);
                    return GestureDetector(
                      onTap: () => _toggleSkill(skill),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.black : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.black45,
                          ),
                          boxShadow: [
                            if (!isSelected)
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(2, 2),
                              ),
                          ],
                        ),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          skill,
                          style: GoogleFonts.robotoMono(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed:
                    _selectedSkills.isNotEmpty ? _saveSkillsAndProceed : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  disabledBackgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
                ),
                child: Text("Continue",
                    style: GoogleFonts.robotoMono(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
