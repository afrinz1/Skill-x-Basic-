import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'SkillSelectionPage.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? user;
  late Future<Map<String, dynamic>> _userFuture;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    _userFuture = _fetchUserData();
  }

  /// Fetches user data including name and skills
  Future<Map<String, dynamic>> _fetchUserData() async {
    Map<String, dynamic> userData = {
      "username": "No Name",
      "email": user?.email ?? "No Email",
      "skills": [],
    };

    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(user!.uid)
            .get();
        DocumentSnapshot skillDoc = await FirebaseFirestore.instance
            .collection("userskillset")
            .doc(user!.uid)
            .get();

        if (userDoc.exists) {
          userData["username"] = userDoc["username"] ?? "No Name";
        }
        if (skillDoc.exists && skillDoc.data() != null) {
          userData["skills"] = List<String>.from(skillDoc["skills"] ?? []);
        }
      } catch (e) {
        print("Error fetching user data: $e");
      }
    }
    return userData;
  }

  /// Navigate to skill selection and refresh profile after update
  Future<void> _editSkills() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SkillSelectionPage()),
    );
    setState(() {
      _userFuture = _fetchUserData(); // Refresh user data
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.robotoMono(fontSize: 22, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.blue));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                'Error loading profile',
                style: GoogleFonts.robotoMono(color: Colors.red, fontSize: 18),
              ),
            );
          }

          final userData = snapshot.data!;
          final String username = userData["username"];
          final String email = userData["email"];
          final List<String> skills = userData["skills"];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Centers content vertically
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Aligns content to center
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blue,
                  child: Text(
                    username.isNotEmpty ? username[0].toUpperCase() : '?',
                    style: GoogleFonts.robotoMono(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  username,
                  style: GoogleFonts.robotoMono(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  email,
                  style: GoogleFonts.robotoMono(
                      fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 20),
                Text(
                  'Your Skills',
                  style: GoogleFonts.robotoMono(
                    color: Colors.black,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: skills.isNotEmpty
                      ? ListView.builder(
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          itemCount: skills.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Center(
                                child: Chip(
                                  label: Text(skills[index]),
                                  backgroundColor: Colors.white,
                                  shape: const StadiumBorder(
                                    side: BorderSide(color: Colors.black45),
                                  ),
                                  labelStyle: GoogleFonts.robotoMono(
                                    color: Colors.black,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Text(
                            'No skills selected',
                            style: GoogleFonts.robotoMono(
                              color: Colors.grey,
                              fontSize: 18,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _editSkills,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    'Edit Skills',
                    style: GoogleFonts.robotoMono(
                        fontSize: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}
