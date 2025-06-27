import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_page.dart';
import 'ProfilePage.dart';
import 'skill_users_page.dart';
import 'inboxpage.dart';
import 'skill_requesters_page.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _needSkillController = TextEditingController();
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
  List<String> _filteredSkills = [];
  List<Map<String, dynamic>> _neededSkills = [];
  List<Map<String, dynamic>> _recentlyAddedSkills = [];
  List<String> _userSkills = [];
  bool _isLoading = false;
  String? _selectedSkill;

  @override
  void initState() {
    super.initState();
    _filteredSkills = List.from(_skills);
    _loadUserSkills();
    _loadNeededSkills();
    _loadRecentlyAddedSkills();
  }

  void _filterSkills(String query) {
    setState(() {
      _filteredSkills = _skills
          .where((skill) => skill.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _addNeededSkill() async {
    String neededSkill = _selectedSkill ?? _needSkillController.text.trim();
    if (neededSkill.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter or select a skill')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You must be logged in to add skills')),
        );
        return;
      }

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      String userName = 'User_${currentUser.uid.substring(0, 8)}';
      if (userDoc.exists && userDoc.data() is Map<String, dynamic>) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        if (userData['username'] != null && userData['username'].isNotEmpty) {
          userName = userData['username'];
        }
      }

      String skillId = neededSkill.toLowerCase().replaceAll(' ', '_');

      DocumentSnapshot skillDoc = await FirebaseFirestore.instance
          .collection('skills_in_demand')
          .doc(skillId)
          .get();

      int newCount = 1;
      if (skillDoc.exists) {
        Map<String, dynamic> data = skillDoc.data() as Map<String, dynamic>;
        newCount = (data['count'] ?? 0) + 1;

        await FirebaseFirestore.instance
            .collection('skills_in_demand')
            .doc(skillId)
            .update({
          'requesters': FieldValue.arrayUnion([
            {
              'userId': currentUser.uid,
              'userName': userName,
              'timestamp': Timestamp.now()
            }
          ]),
          'count': newCount,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        await FirebaseFirestore.instance
            .collection('skills_in_demand')
            .doc(skillId)
            .set({
          'skill': neededSkill,
          'requesters': [
            {
              'userId': currentUser.uid,
              'userName': userName,
              'timestamp': Timestamp.now()
            }
          ],
          'count': 1,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      await FirebaseFirestore.instance.collection('recently_added_skills').add({
        'skill': neededSkill,
        'userId': currentUser.uid,
        'userName': userName,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _needSkillController.clear();
      setState(() {
        _selectedSkill = null;
      });

      _loadNeededSkills();
      _loadRecentlyAddedSkills();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Skill "$neededSkill" added to demand!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding skill need: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadNeededSkills() async {
    if (FirebaseAuth.instance.currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('skills_in_demand')
          .orderBy('count', descending: true)
          .orderBy('lastUpdated', descending: true)
          .limit(10)
          .get();

      List<Map<String, dynamic>> skills = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String skillName = data['skill'];
        int count = data['count'] ?? 0;

        List<dynamic> requesters = data['requesters'] ?? [];
        User? currentUser = FirebaseAuth.instance.currentUser;
        bool userRequested = currentUser != null &&
            requesters.any((r) => r['userId'] == currentUser.uid);

        skills.add({
          'id': doc.id,
          'skill': skillName,
          'count': count,
          'userRequested': userRequested,
        });
      }

      setState(() {
        _neededSkills = skills;
      });
    } catch (e) {
      print('Error loading needed skills: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadRecentlyAddedSkills() async {
    if (FirebaseAuth.instance.currentUser == null) return;

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('recently_added_skills')
          .orderBy('timestamp', descending: true)
          .get();

      Map<String, Map<String, dynamic>> groupedSkills = {};

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String skillName = data['skill'];

        if (!groupedSkills.containsKey(skillName)) {
          groupedSkills[skillName] = {
            'skill': skillName,
            'count': 0,
            'latestTimestamp': data['timestamp'] as Timestamp,
            'docs': [],
          };
        }

        groupedSkills[skillName]!['count'] =
            groupedSkills[skillName]!['count'] + 1;
        groupedSkills[skillName]!['docs'].add({
          'id': doc.id,
          'userId': data['userId'],
          'userName': data['userName'] ?? 'Unknown User',
          'timestamp': data['timestamp'] as Timestamp,
        });

        if ((data['timestamp'] as Timestamp).millisecondsSinceEpoch >
            groupedSkills[skillName]!['latestTimestamp']
                .millisecondsSinceEpoch) {
          groupedSkills[skillName]!['latestTimestamp'] = data['timestamp'];
        }
      }

      List<Map<String, dynamic>> recentSkills = groupedSkills.values
          .map((skill) => {
                'skill': skill['skill'],
                'count': skill['count'],
                'timestamp': skill['latestTimestamp'].toDate(),
                'docs': skill['docs'],
              })
          .toList()
        ..sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

      setState(() {
        _recentlyAddedSkills = recentSkills;
      });
    } catch (e) {
      print('Error loading recently added skills: $e');
    }
  }

  void _removeSkillRequest(String skillId) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      DocumentSnapshot skillDoc = await FirebaseFirestore.instance
          .collection('skills_in_demand')
          .doc(skillId)
          .get();

      if (!skillDoc.exists) return;

      Map<String, dynamic> data = skillDoc.data() as Map<String, dynamic>;
      List<dynamic> requesters = List.from(data['requesters'] ?? []);

      Map<String, dynamic>? userRequest = requesters.firstWhere(
        (r) => r['userId'] == currentUser.uid,
        orElse: () => null,
      );

      if (userRequest != null) {
        await FirebaseFirestore.instance
            .collection('skills_in_demand')
            .doc(skillId)
            .update({
          'requesters': FieldValue.arrayRemove([userRequest]),
          'count': FieldValue.increment(-1),
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        _loadNeededSkills();
        _loadRecentlyAddedSkills();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Your request has been removed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing request: $e')),
      );
    }
  }

  void _removeRecentlyAddedSkill(String skillName) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('recently_added_skills')
          .where('skill', isEqualTo: skillName)
          .where('userId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('recently_added_skills')
            .doc(snapshot.docs.first.id)
            .delete();

        _loadRecentlyAddedSkills();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recent skill entry removed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing recent skill: $e')),
      );
    }
  }

  void _loadUserSkills() async {
    if (FirebaseAuth.instance.currentUser == null) return;

    try {
      QuerySnapshot userSnapshot =
          await FirebaseFirestore.instance.collection("userskillset").get();
      List<String> skills = [];
      for (var doc in userSnapshot.docs) {
        var userData = doc.data() as Map<String, dynamic>;
        if (userData.containsKey("skills")) {
          skills.addAll(List<String>.from(userData["skills"] ?? []));
        }
      }
      setState(() {
        _userSkills = skills.toSet().toList();
      });
    } catch (e) {
      print('Error loading user skills: $e');
    }
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page))
        .then((_) {
      _loadNeededSkills();
      _loadRecentlyAddedSkills();
    });
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inSeconds < 60) return 'just now';
    if (difference.inMinutes < 60)
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    if (difference.inHours < 24)
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Discover Your Skill',
          style: GoogleFonts.robotoMono(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          IconButton(
              icon: Icon(Icons.chat),
              onPressed: () => _navigateTo(context, InboxPage())),
          IconButton(
              icon: Icon(Icons.person),
              onPressed: () => _navigateTo(context, ProfilePage())),
          IconButton(
              icon: Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => LoginPage()));
              }),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedSkill,
                      decoration: InputDecoration(
                        hintText: 'Select a skill you need',
                        hintStyle: GoogleFonts.robotoMono(color: Colors.black),
                        filled: true,
                        fillColor: Colors.black,
                        prefixIcon: Icon(Icons.list, color: Colors.black),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              BorderSide(color: Colors.black, width: 1.5),
                        ),
                      ),
                      items: _skills.map((String skill) {
                        return DropdownMenuItem<String>(
                          value: skill,
                          child: Text(skill),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedSkill = newValue;
                          _needSkillController.clear();
                        });
                      },
                    ),
                    SizedBox(height: 10),
                    Text('OR',
                        style: GoogleFonts.robotoMono(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    TextField(
                      controller: _needSkillController,
                      style: GoogleFonts.robotoMono(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: 'Enter a custom skill need',
                        hintStyle: GoogleFonts.robotoMono(
                            color: Colors.grey, fontSize: 16),
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        prefixIcon:
                            Icon(Icons.help_outline, color: Colors.black),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              BorderSide(color: Colors.black, width: 1.5),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          setState(() {
                            _selectedSkill = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _addNeededSkill,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              'Confirm Need',
                              style: GoogleFonts.robotoMono(
                                  fontSize: 18, color: Colors.white),
                            ),
                    ),
                  ],
                ),
              ).animate().fade(duration: 500.ms).slideY(begin: -0.3, end: 0),
              if (_isLoading && _neededSkills.isEmpty)
                CircularProgressIndicator(),
              if (_neededSkills.isNotEmpty || _userSkills.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Skills in Demand',
                          style: GoogleFonts.robotoMono(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black)),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 10,
                        children: _neededSkills.map((skill) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: skill['userRequested']
                                  ? Colors.blue.shade100
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.black.withOpacity(0.1)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${skill['skill']}',
                                  style: GoogleFonts.robotoMono(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${skill['count']}',
                                    style: GoogleFonts.robotoMono(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (skill['userRequested']) ...[
                                  SizedBox(width: 6),
                                  InkWell(
                                    onTap: () =>
                                        _removeSkillRequest(skill['id']),
                                    child: Icon(Icons.close,
                                        size: 18, color: Colors.black54),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      if (_recentlyAddedSkills.isNotEmpty) ...[
                        SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(15),
                          decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade300)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.add_circle, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text(
                                    'Recently Added Skills',
                                    style: GoogleFonts.robotoMono(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Column(
                                children: _recentlyAddedSkills.map((skill) {
                                  return GestureDetector(
                                    onTap: () => _navigateTo(
                                        context,
                                        SkillRequestersPage(
                                            skill: skill['skill'])),
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 8.0),
                                      child: Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.symmetric(
                                            vertical: 10, horizontal: 15),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.grey.withOpacity(0.2),
                                              spreadRadius: 1,
                                              blurRadius: 3,
                                              offset: Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade600,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                '${skill['count']}',
                                                style: GoogleFonts.robotoMono(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                '"${skill['skill']}"',
                                                style: GoogleFonts.robotoMono(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                Text(
                                                  _getTimeAgo(
                                                      skill['timestamp']),
                                                  style: GoogleFonts.robotoMono(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                if (skill['docs'].any((doc) =>
                                                    doc['userId'] ==
                                                    FirebaseAuth.instance
                                                        .currentUser?.uid))
                                                  InkWell(
                                                    onTap: () =>
                                                        _removeRecentlyAddedSkill(
                                                            skill['skill']),
                                                    child: Icon(
                                                        Icons.delete_outline,
                                                        size: 16,
                                                        color: Colors
                                                            .red.shade300),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              SizedBox(height: 5),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: _loadRecentlyAddedSkills,
                                  icon: Icon(Icons.refresh, size: 16),
                                  label: Text(
                                    'Refresh',
                                    style: GoogleFonts.robotoMono(
                                        color: Colors.grey.shade700),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                            .animate()
                            .fade(duration: 600.ms)
                            .slideY(begin: 0.2, end: 0),
                      ],
                      SizedBox(height: 20),
                      Text('Available Skills',
                          style: GoogleFonts.robotoMono(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black)),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _userSkills
                            .map((skill) => Chip(label: Text(skill)))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Explore Skills',
                        style: GoogleFonts.robotoMono(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
                    SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap:
                          true, // Prevents ListView from taking infinite height
                      physics:
                          NeverScrollableScrollPhysics(), // Disable inner scrolling
                      itemCount: _filteredSkills.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => _navigateTo(context,
                              SkillUsersPage(skill: _filteredSkills[index])),
                          child: Container(
                            margin: EdgeInsets.symmetric(
                                vertical: 10, horizontal: 25),
                            padding: EdgeInsets.symmetric(
                                vertical: 25, horizontal: 30),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: Colors.black, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.grey.shade300,
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                    offset: Offset(0, 6)),
                              ],
                            ),
                            child: Center(
                              child: Text(_filteredSkills[index],
                                  style: GoogleFonts.robotoMono(
                                      color: Colors.black,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                            ),
                          )
                              .animate()
                              .fade(duration: 500.ms)
                              .slideY(begin: 0.2, end: 0),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
