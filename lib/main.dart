import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const KlayinesApp());
}

class KlayinesApp extends StatelessWidget {
  const KlayinesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0D17),
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final serverUrl = 'https://klayines.pythonanywhere.com';
  final targetController = TextEditingController();
  final msgController = TextEditingController();
  List<Map<String, dynamic>> messages = [];
  String myId = '';

  @override
  void initState() {
    super.initState();
    myId = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    _pingServer();
    _startCheckLoop();
  }

  void _pingServer() async {
    try {
      await http.post(
        Uri.parse('$serverUrl/ping'),
        body: jsonEncode({'id': myId}),
      );
    } catch (_) {}
  }

  void _startCheckLoop() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 2));
      await _checkMessages();
      return true;
    });
  }

  Future<void> _checkMessages() async {
    try {
      final resp = await http.post(
        Uri.parse('$serverUrl/check'),
        body: jsonEncode({'id': myId}),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final msgs = data['messages'] as List? ?? [];
        if (msgs.isNotEmpty) {
          setState(() {
            for (var m in msgs) {
              messages.add({
                'from': m['from'] ?? '???',
                'text': m['text'] ?? '',
                'time': m['time'] ?? '',
              });
            }
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final target = targetController.text.trim();
    final text = msgController.text.trim();
    if (target.isEmpty || text.isEmpty) return;

    try {
      await http.post(
        Uri.parse('$serverUrl/send'),
        body: jsonEncode({
          'from': myId,
          'to': target,
          'text': text,
        }),
      );
      setState(() {
        messages.add({
          'from': 'You',
          'text': text,
          'time': TimeOfDay.now().format(context),
        });
      });
      msgController.clear();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.3),
        title: const Text(
          '⚡ KLAYINES',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 20,
            color: Colors.cyanAccent,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.cyan.withOpacity(0.1),
                Colors.purple.withOpacity(0.1),
              ],
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                myId.substring(0, 8),
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Фон
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0B0D17),
                  Color(0xFF1A1F35),
                  Color(0xFF0B0D17),
                ],
              ),
            ),
          ),
          // Стеклянные элементы
          Column(
            children: [
              // Список сообщений
              Expanded(
                child: messages.isEmpty
                    ? const Center(
                        child: Text(
                          'Нет сообщений',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (ctx, i) {
                          final msg = messages[i];
                          final isMe = msg['from'] == 'You';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: isMe
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              children: [
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: isMe
                                            ? [
                                                Colors.cyan.withOpacity(0.2),
                                                Colors.blue.withOpacity(0.1),
                                              ]
                                            : [
                                                Colors.purple.withOpacity(0.2),
                                                Colors.pink.withOpacity(0.1),
                                              ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.1),
                                        width: 0.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (isMe
                                                  ? Colors.cyan
                                                  : Colors.purple)
                                              .withOpacity(0.1),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          msg['from'] ?? '',
                                          style: TextStyle(
                                            color: isMe
                                                ? Colors.cyanAccent
                                                : Colors.purpleAccent,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          msg['text'] ?? '',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              // Поля ввода
              Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyan.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.05),
                            Colors.white.withOpacity(0.02),
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: targetController,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: 'ID получателя',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                              ),
                              border: InputBorder.none,
                              prefixIcon: Icon(
                                Icons.person,
                                color: Colors.cyan.withOpacity(0.5),
                                size: 20,
                              ),
                            ),
                          ),
                          const Divider(
                            color: Colors.white10,
                            height: 1,
                          ),
                          TextField(
                            controller: msgController,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Сообщение...',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                              ),
                              border: InputBorder.none,
                              prefixIcon: Icon(
                                Icons.message,
                                color: Colors.purple.withOpacity(0.5),
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: _sendMessage,
                            child: Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.cyan.withOpacity(0.3),
                                    Colors.blue.withOpacity(0.2),
                                  ],
                                ),
                                border: Border.all(
                                  color: Colors.cyan.withOpacity(0.3),
                                  width: 0.5,
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  'ОТПРАВИТЬ',
                                  style: TextStyle(
                                    color: Colors.cyanAccent,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
