import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ChatPage.dart'; // Import the chat page

class SkillUsersPage extends StatelessWidget {
  final String skill;

  SkillUsersPage({required this.skill});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$skill Experts',
          style: GoogleFonts.robotoMono(),
        ),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection("userskillset")
            .where("skills", arrayContains: skill)
            .get(),
        builder: (context, skillSnapshot) {
          if (skillSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.blue));
          }

          if (!skillSnapshot.hasData || skillSnapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No users found with this skill',
                style:
                    GoogleFonts.robotoMono(color: Colors.white, fontSize: 18),
              ),
            );
          }

          final userIds =
              skillSnapshot.data!.docs.map((doc) => doc.id).toList();

          List<Future<QuerySnapshot>> userQueries = [];
          for (var i = 0; i < userIds.length; i += 10) {
            var batchIds = userIds.sublist(
                i, i + 10 > userIds.length ? userIds.length : i + 10);
            userQueries.add(FirebaseFirestore.instance
                .collection("users")
                .where(FieldPath.documentId, whereIn: batchIds)
                .get());
          }

          return FutureBuilder<List<QuerySnapshot>>(
            future: Future.wait(userQueries),
            builder: (context, userSnapshots) {
              if (userSnapshots.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              List<DocumentSnapshot> allUsers = [];
              for (var snapshot in userSnapshots.data ?? []) {
                allUsers.addAll(snapshot.docs);
              }

              if (allUsers.isEmpty) {
                return Center(
                  child: Text(
                    'No users found with this skill',
                    style: GoogleFonts.robotoMono(
                        color: Colors.white, fontSize: 18),
                  ),
                );
              }

              return ListView.builder(
                itemCount: allUsers.length,
                itemBuilder: (context, index) {
                  final userData =
                      allUsers[index].data() as Map<String, dynamic>?;

                  if (userData == null) {
                    return SizedBox.shrink();
                  }

                  String userId = allUsers[index].id;
                  String username = userData["username"] ?? "No Username";
                  String email = userData["email"] ?? "No Email";
                  String initials =
                      username.isNotEmpty ? username[0].toUpperCase() : "?";

                  return Card(
                    color: Colors.grey[900],
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Text(
                          initials,
                          style: GoogleFonts.robotoMono(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        '@$username',
                        style: GoogleFonts.robotoMono(
                            color: Colors.blue, fontSize: 18),
                      ),
                      subtitle: Text(
                        email,
                        style: GoogleFonts.robotoMono(
                            color: Colors.grey, fontSize: 14),
                      ),
                      trailing: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatPage(
                                receiverId: userId,
                                receiverName: username,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.chat,
                            size: 18, color: Colors.white),
                        label: Text(
                          'Chat',
                          style: GoogleFonts.robotoMono(
                              fontSize: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
