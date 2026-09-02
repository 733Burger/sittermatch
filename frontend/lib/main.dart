import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('SitterMatch Test')),
        body: const Center(child: BackendTest()),
      ),
    );
  }
}

class BackendTest extends StatefulWidget {
  const BackendTest({super.key});

  @override
  State<BackendTest> createState() => _BackendTestState();
}

class _BackendTestState extends State<BackendTest> {
  String message = 'Loading...';

  @override
  void initState() {
    super.initState();
    fetchMessage();
  }

  Future<void> fetchMessage() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/api/hello'),
      );
      setState(() {
        message = response.body;
      });
    } catch (e) {
      setState(() {
        message = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(message, style: const TextStyle(fontSize: 18));
  }
}
