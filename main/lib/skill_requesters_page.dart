import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:main/login_page.dart';
import 'ChatPage.dart'; // Import the chat page

class SkillRequestersPage extends StatefulWidget {
  final String skill;

  SkillRequestersPage({required this.skill});

  @override
  _SkillRequestersPageState createState() => _SkillRequestersPageState();
}

class _SkillRequestersPageState extends State<SkillRequestersPage> {
  Future<List<Map<String, dynamic>>> _fetchRequesters(String skill) async {
    if (FirebaseAuth.instance.currentUser == null) {
      throw Exception('You must be logged in to view requesters');
    }

    try {
      String skillId = skill.toLowerCase().replaceAll(' ', '_');
      DocumentSnapshot skillDoc = await FirebaseFirestore.instance
          .collection('skills_in_demand')
          .doc(skillId)
          .get();

      if (!skillDoc.exists) {
        print('Skill document does not exist for skillId: $skillId');
        return [];
      }

      Map<String, dynamic> data = skillDoc.data() as Map<String, dynamic>;
      List<dynamic> requesters = data['requesters'] ?? [];
      print('Found ${requesters.length} requesters for skill: $skill');

      List<Map<String, dynamic>> requesterDetails = [];
      for (var requester in requesters) {
        if (requester is Map<String, dynamic> && requester['userId'] != null) {
          String userId = requester['userId'];
          print('Processing requester with userId: $userId');

          // Use the username stored in skills_in_demand
          String userName = requester['userName'] ?? 'Unknown User ($userId)';
          print('Username from skills_in_demand: $userName');

          // Fetch skills from 'userskillset' collection
          DocumentSnapshot userSkillsDoc = await FirebaseFirestore.instance
              .collection('userskillset')
              .doc(userId)
              .get();

          List<String> skills = [];
          if (userSkillsDoc.exists) {
            var userData = userSkillsDoc.data() as Map<String, dynamic>;
            skills = List<String>.from(userData['skills'] ?? []);
            print('Skills for $userId: $skills');
          } else {
            print('No skills document found for $userId');
          }

          requesterDetails.add({
            'userName': userName,
            'skills': skills,
            'userId': userId, // Include userId for chat navigation
          });
        } else {
          print('Invalid requester format: $requester');
        }
      }
      return requesterDetails;
    } catch (e) {
      print('Error fetching requesters: $e');
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          '"${widget.skill}" Requesters',
          style: GoogleFonts.robotoMono(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchRequesters(widget.skill),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    snapshot.error.toString().contains('logged in')
                        ? 'Please log in to view requesters'
                        : 'Error loading requesters',
                    style: GoogleFonts.robotoMono(color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (FirebaseAuth.instance.currentUser == null) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()),
                        );
                      } else {
                        setState(() {});
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                    child: Text(
                      FirebaseAuth.instance.currentUser == null
                          ? 'Login'
                          : 'Retry',
                      style: GoogleFonts.robotoMono(),
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No requesters found',
                style: GoogleFonts.robotoMono(color: Colors.white70),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var requester = snapshot.data![index];
              String initials = requester['userName'].isNotEmpty
                  ? requester['userName'][0].toUpperCase()
                  : "?";

              return Card(
                color: Colors.white10,
                elevation: 0,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white24,
                        child: Text(
                          initials,
                          style: GoogleFonts.robotoMono(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              requester['userName'],
                              style: GoogleFonts.robotoMono(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: (requester['skills'] as List<String>)
                                  .map((skill) => Chip(
                                        label: Text(
                                          skill,
                                          style: GoogleFonts.robotoMono(
                                              color: Colors.white),
                                        ),
                                        backgroundColor: Colors.white12,
                                        padding: EdgeInsets.zero,
                                      ))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatPage(
                                receiverId: requester['userId'],
                                receiverName: requester['userName'],
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        icon: const Icon(Icons.chat,
                            size: 18, color: Colors.black),
                        label: Text(
                          'Chat',
                          style: GoogleFonts.robotoMono(
                              fontSize: 14, color: Colors.black),
                        ),
                      ),
                    ],
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
