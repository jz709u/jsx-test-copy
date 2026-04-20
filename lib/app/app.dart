import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'shell/main_shell.dart';

class JsxApp extends StatelessWidget {
  const JsxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JSX: How I Fly',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: const MainShell(),
    );
  }
}
