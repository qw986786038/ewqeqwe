import 'package:flutter/material.dart';
import 'package:lemon_net/lemon_net.dart';

void main() {
  LemonNet.init('https://httpbin.org');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('lemon_net example')),
        body: Center(
          child: FilledButton(
            onPressed: () async {
              final response = await LemonNet.instance.get('/get');
              debugPrint('HTTP ${response.statusCode}: ${response.data}');
            },
            child: const Text('Send request'),
          ),
        ),
      ),
    );
  }
}
