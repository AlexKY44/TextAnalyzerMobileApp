import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) {
      return 'Введіть ім’я';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Введіть email';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+').hasMatch(email)) {
      return 'Невірний формат email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Введіть пароль';
    }
    if (password.length < 6) {
      return 'Пароль має містити мінімум 6 символів';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final confirm = value ?? '';
    if (confirm.isEmpty) {
      return 'Підтвердіть пароль';
    }
    if (confirm != _password.text) {
      return 'Паролі не співпадають';
    }
    return null;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    setState(() => _isLoading = false);
    Navigator.pop(context, {
      'registered': true,
      'name': _name.text.trim(),
      'email': _email.text.trim(),
    });
  }

  void _skip() {
    Navigator.pop(context, {
      'registered': false,
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Реєстрація')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Створіть обліковий запис, щоб отримати більше можливостей.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Ім’я',
                  hintText: 'Ваше ім’я',
                ),
                validator: _validateName,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'example@mail.com',
                ),
                validator: _validateEmail,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _password,
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  labelText: 'Пароль',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _showPassword = !_showPassword);
                    },
                  ),
                ),
                validator: _validatePassword,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirmPassword,
                obscureText: !_showPassword,
                decoration: const InputDecoration(
                  labelText: 'Підтвердження пароля',
                ),
                validator: _validateConfirmPassword,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Зареєструватись'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _isLoading ? null : _skip,
                child: const Text('Пропустити'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
