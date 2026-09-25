import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Masuk')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              labelText: 'Email',
              controller: _emailController,
            ),
            const SizedBox(height: 16),
            AppTextField(
              labelText: 'Kata Sandi',
              controller: _passwordController,
              obscureText: true,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'Masuk',
              onPressed: () {
                Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.dashboardRoute,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
