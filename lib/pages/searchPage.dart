
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chatPage.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchUserPageState();
}

class _SearchUserPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<DocumentSnapshot> _searchResults = [];
  bool _isSearching = false;

  Future<void> _startChat(String otherUserId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User is not authenticated')),
      );
      return;
    }

    try {
      final existingChatQuery = await _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .get();

      String? chatId;
      for (var doc in existingChatQuery.docs) {
        final participants = doc['participants'] as List<dynamic>;
        if (participants.contains(otherUserId) && participants.length == 2) {
          chatId = doc.id;
          break;
        }
      }

      if (chatId == null) {
        final chatRef = await _firestore.collection('chats').add({
          'participants': [currentUserId, otherUserId],
          'createdAt': FieldValue.serverTimestamp(),
        });
        chatId = chatRef.id;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            chatId: chatId!,
            otherUserId: otherUserId,
          ),
        ),
      );
    } catch (e) {
      print('Error starting chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting chat: $e')),
      );
    }
  }


  void _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      final lowercaseQuery = query.toLowerCase();

      final querySnapshot = await _firestore
          .collection('users')
          .where('searchIndex', arrayContains: lowercaseQuery)
          .limit(10)
          .get();

      setState(() {
        _searchResults = querySnapshot.docs.where((doc) {
          final userData = doc.data();
          return userData['email'] != _auth.currentUser!.email;
        }).toList();
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching users: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(15),
                  bottomRight: Radius.circular(15),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by name or email',
                        hintStyle: GoogleFonts.outfit(color: Colors.grey),
                        border: InputBorder.none,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search, color: Colors.grey),
                          onPressed: () => _searchUsers(_searchController.text.trim()),
                        ),
                      ),
                      onSubmitted: _searchUsers,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 1),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
                child: _isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : _searchResults.isEmpty && _searchController.text.isNotEmpty
                    ? Center(
                      child: Text(
                        'No users found',
                        style: GoogleFonts.outfit(),
                      ),
                    )
                    : _searchResults.isEmpty
                    ? Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                    ),
                    width: double.infinity,
                    height: double.infinity,
                  )
                    : ListView.separated(
                      separatorBuilder: (context, index) => const Divider(
                        height: 1,
                        color: Colors.grey,
                      ),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final userData = _searchResults[index].data()
                        as Map<String, dynamic>;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundImage:
                            userData['profilePicUrl'] != null
                                ? NetworkImage(userData['profilePicUrl'])
                                : null,
                            child: userData['profilePicUrl'] == null
                                ? Text(
                              userData['name'][0].toUpperCase(),
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            )
                                : null,
                          ),
                          title: Text(
                            userData['name'],
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            userData['email'],
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          onTap: () => _startChat(_searchResults[index].id),
                        );
                      },
                    ),
              ),
            )
          ],
        ),
      ),
    );
  }
}