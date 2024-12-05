import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

import '../utils/imageHandler.dart';
import '../utils/encryption.dart'; 

class ChatPage extends StatefulWidget {
  final String chatId;
  final String otherUserId;

  const ChatPage({
    Key? key,
    required this.chatId,
    required this.otherUserId,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ImageHandler _imageHandler = ImageHandler();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();

  late encrypt.Key _encryptionKey;

  @override
  void initState() {
    super.initState();
    final currentUserId = _auth.currentUser!.uid;
    _encryptionKey = Encryption.generateKeyFromUserIds(
        currentUserId,
        widget.otherUserId
    );
  }

  Future<void> _sendMessage({String? textMessage, String? imageUrl}) async {
    if ((textMessage == null || textMessage.isEmpty) && imageUrl == null) return;

    final currentUser = _auth.currentUser!;

    final encryptedText = textMessage != null
        ? Encryption.encryptData(textMessage, _encryptionKey)
        : null;
    final encryptedImage = imageUrl != null
        ? Encryption.encryptData(imageUrl, _encryptionKey)
        : null;

    final messageData = {
      'senderId': currentUser.uid,
      'text': encryptedText,
      'imageUrl': encryptedImage,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      await _firestore
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add(messageData);

      await _firestore.collection('chats').doc(widget.chatId).update({
        'lastMessage': encryptedText ?? encryptedImage ?? 'No message',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    }
  }

  Future<void> _pickAndUploadImage() async {
    File? pickedImage = await _imageHandler.pickImage();
    if (pickedImage != null) {
      String? base64Image = await _imageHandler.encodeImageToBase64(pickedImage);
      if (base64Image != null) {
        _sendMessage(imageUrl: base64Image);
      } else {
        print("Failed to encode image.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<DocumentSnapshot>(
          future: _firestore.collection('users').doc(widget.otherUserId).get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Text('Loading...');
            }
            final userData = snapshot.data!.data() as Map<String, dynamic>;
            return Text(userData['name']);
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('chats')
                    .doc(widget.chatId)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data!.docs;

                  return ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final messageData = messages[index].data() as Map<String, dynamic>;
                      final bool isMe = messageData['senderId'] == _auth.currentUser!.uid;

                      final encryptedImageUrl = messageData['imageUrl'];
                      final encryptedText = messageData['text'];

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blue[100] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (encryptedImageUrl != null)
                                Image.memory(
                                  base64Decode(
                                      Encryption.decryptData(
                                          encryptedImageUrl,
                                          _encryptionKey
                                      )
                                  ),
                                  height: 200,
                                  width: 200,
                                ),

                              if (encryptedText != null)
                                Text(
                                  Encryption.decryptData(
                                      encryptedText,
                                      _encryptionKey
                                  ),
                                  style: const TextStyle(fontSize: 16),
                                ),

                              const SizedBox(height: 5),
                              Text(
                                _formatTimestamp(messageData['timestamp']),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              )
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attachment_outlined),
                  onPressed: _pickAndUploadImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    _sendMessage(textMessage: _messageController.text);
                    _messageController.clear();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final datetime = timestamp.toDate();
    return '${datetime.hour}:${datetime.minute}';
  }
}