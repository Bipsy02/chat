
import 'dart:convert';

import 'package:chat/utils/encryption.dart';
import 'package:chat/pages/chatPage.dart';
import 'package:chat/pages/searchPage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _decryptLastMessage(String otherUserId, String encryptedMessage) {
    try {
      if (encryptedMessage.isEmpty) {
        return '';
      }

      final currentUserId = _auth.currentUser!.uid;
      final key = Encryption.generateKeyFromUserIds(currentUserId, otherUserId);

      final decryptedMessage = Encryption.decryptData(encryptedMessage, key);

      return decryptedMessage;
    } catch (e) {
      print('Decryption error: $e');
      return 'Unable to decrypt message';
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
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(width: 20),
                      Text(
                        'Inbox',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SearchPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 1),
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('chats')
                      .where('participants', arrayContains: _auth.currentUser!.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final conversations = snapshot.data!.docs;

                    return ListView.separated(
                      separatorBuilder: (context, index) => const Divider(
                        height: 1,
                        color: Colors.grey,
                      ),
                      itemCount: conversations.length,
                      itemBuilder: (context, index) {
                        final conversationData = conversations[index].data() as Map<String, dynamic>;
                        final chatDocId = conversations[index].id;
                        final otherUserId = (conversationData['participants'] as List).firstWhere((id) => id != _auth.currentUser!.uid);
                        return StreamBuilder<QuerySnapshot>(
                          stream: _firestore
                              .collection('chats')
                              .doc(chatDocId)
                              .collection('messages')
                              .orderBy('timestamp', descending: true)
                              .limit(1)
                              .snapshots(),
                          builder: (context, messageSnapshot) {
                            if (!messageSnapshot.hasData) {
                              return const SizedBox.shrink();
                            }

                            final messageData = messageSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                            final imageUrl = messageData['imageUrl'];

                            return FutureBuilder<DocumentSnapshot>(
                              future: _firestore.collection('users').doc(otherUserId).get(),
                              builder: (context, userSnapshot) {
                                if (!userSnapshot.hasData) {
                                  return const SizedBox.shrink();
                                }

                                final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                                final lastMessage = conversationData['lastMessage'] ?? '';
                                final decryptedLastMessage = lastMessage.isNotEmpty
                                    ? _decryptLastMessage(otherUserId, lastMessage)
                                    : 'No messages yet';

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: CircleAvatar(
                                    radius: 24,
                                    backgroundImage: userData['profilePicture'] != null
                                        ? MemoryImage(base64Decode(userData['profilePicture']))
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
                                    imageUrl != null && imageUrl.isNotEmpty
                                        ? 'Sent an image'
                                        : decryptedLastMessage,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  trailing: Text(
                                    conversationData['lastMessageTime'] != null
                                        ? _formatTimestamp(conversationData['lastMessageTime'])
                                        : '',
                                    style: GoogleFonts.outfit(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatPage(
                                          chatId: conversations[index].id,
                                          otherUserId: otherUserId,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
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

  String _formatTimestamp(Timestamp timestamp) {
    final datetime = timestamp.toDate();
    final now = DateTime.now();

    if (datetime.year == now.year &&
        datetime.month == now.month &&
        datetime.day == now.day) {
      return '${datetime.hour.toString().padLeft(2, '0')}:${datetime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${datetime.day}/${datetime.month}/${datetime.year}';
    }
  }
}