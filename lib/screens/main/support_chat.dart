import 'package:flutter/material.dart';

class SupportChat extends StatefulWidget {
  const SupportChat({super.key});

  @override
  State<SupportChat> createState() => _SupportChatState();
}

class _SupportChatState extends State<SupportChat> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF0D9488), Color(0xFF0F172A), Color(0xFF0D9488) ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.only(top: 50, left: 15, right: 15),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
            child: SingleChildScrollView(
              child: Text('Hello world'),
            )
        ),
      ),
    );
  }
}
