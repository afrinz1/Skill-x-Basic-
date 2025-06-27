import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  ChatPage({required this.receiverId, required this.receiverName});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();

  String get _chatId {
    List<String> ids = [_auth.currentUser!.uid, widget.receiverId];
    ids.sort();
    return ids.join("_");
  }

  // Initialize the chat document when the page loads
  Future<void> _initializeChatDocument() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print("No authenticated user found");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication required',
                style: GoogleFonts.robotoMono()),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      DocumentReference chatDocRef =
          _firestore.collection("chats").doc(_chatId);

      // Explicitly create the document with a try-catch to handle permissions
      await chatDocRef.set({
        "participants": [currentUser.uid, widget.receiverId],
        "lastMessage": "Chat started",
        "lastMessageTimestamp": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).catchError((error) {
        print("Detailed Error Setting Chat Document: $error");

        // More detailed error handling
        if (error is FirebaseException) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Firestore Error: ${error.code} - ${error.message}',
                style: GoogleFonts.robotoMono(),
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      });

      // Additional logging for debugging
      DocumentSnapshot chatDoc = await chatDocRef.get();
      print("Chat Document After Creation: ${chatDoc.data()}");
    } catch (e) {
      print("Comprehensive Initialization Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Initialization Failed: $e',
              style: GoogleFonts.robotoMono()),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print("No authenticated user found");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication required',
                style: GoogleFonts.robotoMono()),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      DocumentReference chatDocRef =
          _firestore.collection("chats").doc(_chatId);

      // Ensure document exists with merge option
      await chatDocRef.set({
        "participants": [currentUser.uid, widget.receiverId],
        "lastMessage": _messageController.text.trim(),
        "lastMessageTimestamp": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _firestore
          .collection("chats")
          .doc(_chatId)
          .collection("messages")
          .add({
        "senderId": currentUser.uid,
        "receiverId": widget.receiverId,
        "message": _messageController.text.trim(),
        "timestamp": FieldValue.serverTimestamp(),
      });

      _messageController.clear();
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      print("Comprehensive Send Message Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Message Send Failed: $e', style: GoogleFonts.robotoMono()),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    DateTime dateTime = timestamp.toDate();
    return DateFormat('HH:mm').format(dateTime);
  }

  @override
  void initState() {
    super.initState();
    // Call the initialization when the page loads
    _initializeChatDocument();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print(
        "Building ChatPage - User UID: ${_auth.currentUser?.uid}, Chat ID: $_chatId, Receiver ID: ${widget.receiverId}");

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chat with ${widget.receiverName}',
          style: GoogleFonts.robotoMono(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection("chats")
                  .doc(_chatId)
                  .collection("messages")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print("Stream error: ${snapshot.error}");
                  return Center(
                    child: Text(
                      'Error loading messages: ${snapshot.error}',
                      style: GoogleFonts.robotoMono(color: Colors.redAccent),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.white));
                }

                if (snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet. Start the conversation!',
                      style: GoogleFonts.robotoMono(color: Colors.white70),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var msg = snapshot.data!.docs[index];
                    bool isMe = msg["senderId"] == _auth.currentUser!.uid;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.white24 : Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg["message"],
                              style:
                                  GoogleFonts.robotoMono(color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTimestamp(msg["timestamp"]),
                              style: GoogleFonts.robotoMono(
                                  color: Colors.white54, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: GoogleFonts.robotoMono(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      hintStyle: GoogleFonts.robotoMono(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: Colors.white, width: 2),
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
