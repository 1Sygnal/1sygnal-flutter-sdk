import 'package:flutter/material.dart';
import 'screens/example_screen.dart';

class OneSygnalExampleApp extends StatelessWidget {
  const OneSygnalExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OneSygnal Flutter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const ExampleScreen(),
    );
  }
}
