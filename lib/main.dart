import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:text_analyzer/src/app.dart';
import 'package:text_analyzer/src/core/theme/theme_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}
