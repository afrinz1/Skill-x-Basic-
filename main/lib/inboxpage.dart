import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'ChatPage.dart';

class InboxPage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  InboxPage({Key? key}) : super(key: key);

  Stream<List<Map<String, dynamic>>> getRecentChats() {
    return _firestore
        .collection("chats")
        .where("participants", arrayContains: _auth.currentUser!.uid)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> conversations = [];

      for (var doc in snapshot.docs) {
        String chatId = doc.id;
        List<dynamic> participants = doc["participants"];

        QuerySnapshot messageSnapshot = await _firestore
            .collection("chats")
            .doc(chatId)
            .collection("messages")
            .orderBy("timestamp", descending: true)
            .limit(1)
            .get();

        if (messageSnapshot.docs.isNotEmpty) {
          var lastMessage = messageSnapshot.docs.first;
          String senderId = lastMessage["senderId"];
          String receiverId = lastMessage["receiverId"];

          // Determine the chat partner and message type
          bool isMessageSentByMe = senderId == _auth.currentUser!.uid;
          String chatPartnerId = isMessageSentByMe ? receiverId : senderId;

          // Fetch the chat partner's username
          DocumentSnapshot userDoc =
              await _firestore.collection("users").doc(chatPartnerId).get();
          String chatPartnerName =
              userDoc.exists ? userDoc["username"] : "Unknown";

          conversations.add({
            "chatId": chatId,
            "chatPartnerId": chatPartnerId,
            "chatPartnerName": chatPartnerName,
            "lastMessage": lastMessage["message"],
            "timestamp": lastMessage["timestamp"],
            "isMessageSentByMe": isMessageSentByMe,
          });
        }
      }

      // Sort conversations by timestamp (most recent first)
      conversations.sort((a, b) =>
          (b["timestamp"] as Timestamp).compareTo(a["timestamp"] as Timestamp));
      return conversations;
    });
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    DateTime dateTime = timestamp.toDate();
    return DateFormat('MMM d, HH:mm')
        .format(dateTime); // More detailed timestamp
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Inbox",
            style: GoogleFonts.robotoMono(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: getRecentChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.white));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error loading chats: ${snapshot.error}",
                style: GoogleFonts.robotoMono(color: Colors.redAccent),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                "No conversations yet",
                style: GoogleFonts.robotoMono(color: Colors.white),
              ),
            );
          }

          var conversations = snapshot.data!;

          return ListView.separated(
            itemCount: conversations.length,
            separatorBuilder: (context, index) => const Divider(
              color: Colors.white24,
              height: 1,
            ),
            itemBuilder: (context, index) {
              var chat = conversations[index];

              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Row(
                  children: [
                    Text(
                      chat["chatPartnerName"],
                      style: GoogleFonts.robotoMono(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    // Message direction indicator
                    Icon(
                      chat["isMessageSentByMe"]
                          ? Icons.send_outlined
                          : Icons.mark_email_read_outlined,
                      color: chat["isMessageSentByMe"]
                          ? Colors.blue
                          : Colors.green,
                      size: 16,
                    )
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chat["lastMessage"],
                      style: GoogleFonts.robotoMono(
                          color: Colors.grey,
                          fontStyle: chat["isMessageSentByMe"]
                              ? FontStyle.italic
                              : FontStyle.normal),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(chat["timestamp"]),
                      style: GoogleFonts.robotoMono(
                          color: Colors.white54, fontSize: 10),
                    ),
                  ],
                ),
                leading: CircleAvatar(
                  backgroundColor: chat["isMessageSentByMe"]
                      ? Colors.blue[200]
                      : Colors.green[200],
                  child: Icon(
                    chat["isMessageSentByMe"] ? Icons.send : Icons.mail,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: chat["isMessageSentByMe"]
                          ? Colors.blue[50]
                          : Colors.green[50],
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    chat["isMessageSentByMe"] ? "Sent" : "Received",
                    style: GoogleFonts.robotoMono(
                        color: chat["isMessageSentByMe"]
                            ? Colors.blue
                            : Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        receiverId: chat["chatPartnerId"],
                        receiverName: chat["chatPartnerName"],
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
