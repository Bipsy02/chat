
import 'dart:convert';
import 'dart:io';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/imageHandler.dart';

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
  String? _otherUserName;

  @override
  void initState() {
    super.initState();
    _fetchOtherUserName();
  }

  Future<void> _fetchOtherUserName() async {
    try {
      final userDoc = await _firestore.collection('users').doc(widget.otherUserId).get();
      setState(() {
        _otherUserName = userDoc.data()?['name'] ?? 'Unknown User';
      });
    } catch (e) {
      print('Error fetching user name: $e');
    }
  }

  Future<void> _sendMessage({String? textMessage, String? imageUrl}) async {
    if ((textMessage == null || textMessage.isEmpty) && imageUrl == null) return;

    final currentUser = _auth.currentUser!;

    final messageData = {
      'senderId': currentUser.uid,
      'text': textMessage,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      // Send message to Firestore
      await _firestore
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add(messageData);

      // Update the last message in the chat
      await _firestore.collection('chats').doc(widget.chatId).update({
        'lastMessage': imageUrl ?? textMessage ?? 'No message',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      // Send local notification
      _sendLocalNotification(textMessage, imageUrl);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    }
  }

  void _sendLocalNotification(String? textMessage, String? imageUrl) {
    // Check if the current user is not the sender before sending the notification
    if (_auth.currentUser!.uid == widget.otherUserId) {
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: 'basic_channel',
          title: _otherUserName ?? 'New Message',
          body: textMessage ?? (imageUrl != null ? 'Sent an image' : 'New message'),
          payload: {
            'chatId': widget.chatId,
            'otherUserId': widget.otherUserId,
          },
          notificationLayout: NotificationLayout.Default,
        ),
      );
    }
  }

  Future<void> _pickAndUploadImage() async {
    File? pickedImage = await _imageHandler.pickImage();
    if (pickedImage != null) {
      // Encode image to Base64
      String? base64Image = await _imageHandler.encodeImageToBase64(pickedImage);
      if (base64Image != null) {
        // Send the base64-encoded image
        _sendMessage(imageUrl: base64Image);  // Send only the image data
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

                      // Get the imageUrl (Base64 encoded string) from Firestore
                      final imageUrl = messageData['imageUrl'];

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
                              // Display the decoded image only if it exists for this message
                              if (imageUrl != null)
                                Image.memory(
                                  base64Decode(imageUrl),
                                  height: 200, // Optional: set height of the image
                                  width: 200,  // Optional: set width of the image
                                ),
                              if (messageData['text'] != null)
                                Text(
                                  messageData['text'],
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