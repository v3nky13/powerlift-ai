import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ChatScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> _messages = []; // Store chat messages

  @override
  void initState() {
    super.initState();
    _addIntroMessage();
  }

  void _addIntroMessage() {
    setState(() {
      _messages.add({
        "sender": "bot",
        "text": "Hello! I'm Rosh - AI Coach for Powerlifting. 💪You can ask me any questions related to powerlifting!"
      });
    });
  }

  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty) return;

    // Add user message to chat
    setState(() {
      _messages.add({"sender": "user", "text": _controller.text});
    });

    final response = await http.post(
      Uri.parse("http://10.0.2.2:5001/chat"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"question": _controller.text}),
    );

    if (response.statusCode == 200) {
      final botResponse = jsonDecode(response.body)["response"];

      // Add bot response to chat
      setState(() {
        _messages.add({"sender": "bot", "text": botResponse});
      });
    } else {
      setState(() {
        _messages.add({"sender": "bot", "text": "Error: ${response.body}"});
      });
    }

    _controller.clear(); // Clear input field
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(10),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message["sender"] == "user";

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blueAccent : Colors.grey[300],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      message["text"]!,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Divider(height: 1),
          Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: Colors.black,
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}