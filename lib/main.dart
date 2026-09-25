import 'package:flutter/material.dart';
import 'core/constants/app_colors.dart';
import 'features/auth/presentation/screens/auth_screen.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SimpanNota',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryNavy),
      ),
      home: const AuthScreen(),
    );
  }
}
