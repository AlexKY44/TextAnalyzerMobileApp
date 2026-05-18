import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:text_analyzer/src/core/services/api_service.dart';
import 'package:text_analyzer/src/core/widgets/app_drawer.dart';
import 'package:text_analyzer/src/core/widgets/text_panel.dart';
import 'package:text_analyzer/src/features/file/file_screen.dart';
import 'package:text_analyzer/src/features/register/register_screen.dart';
import 'package:text_analyzer/src/shared/constants.dart';
import 'package:text_analyzer/src/core/theme/theme_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _inputController = TextEditingController();

  String _outputText = '';
  bool _isLoading = false;

  bool _isRegistered = false; // 🔥 користувач
  String _userName = '';

  final List<Map<String, String>> _history = [];

  late Map<String, String> _actions;
  late Map<String, String> _languages;

  late String _selectedAction;
  late String _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _actions = actionsMap;
    _languages = languageMap;
    _selectedAction = _actions.keys.first;
    _selectedLanguage = _languages.values.first;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showRegisterScreen();
    });
  }

  Future<void> _showRegisterScreen() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );

    setState(() {
      _isRegistered = result != null && result['registered'] == true;
      _userName = _isRegistered ? (result?['name'] as String? ?? '') : '';
    });
  }

  // 🔥 ЛІМІТ
  bool _checkLimit() {
    int limit = _isRegistered ? 1000 : 300;

    if (_inputController.text.length > limit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ліміт: $limit символів")),
      );
      return false;
    }
    return true;
  }

  Future<void> _handleProcess() async {
    if (_inputController.text.trim().isEmpty || _isLoading) return;
    if (!_checkLimit()) return;

    setState(() {
      _isLoading = true;
      _outputText = '';
    });

    final endpoint = _actions[_selectedAction]!;

    Map<String, dynamic> body = {
      "text": _inputController.text,
    };

    if (endpoint == '/translate') {
      body["target_language"] = _selectedLanguage;
    }

    final result = await ApiService.processText(endpoint, body);

    _history.insert(0, {
      "action": _selectedAction,
      "text": _inputController.text,
    });

    setState(() {
      _outputText =
          endpoint == '/check' ? result['style'] ?? '' : result;
      _isLoading = false;
    });
  }

  void _reuseText() {
    if (_outputText.isEmpty) return;

    setState(() {
      _inputController.text = _outputText;
      _outputText = '';
    });
  }

  Future<void> _openFileScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FileScreen()),
    );

    if (result != null) {
      setState(() {
        _inputController.text = result;
      });
    }
  }

  // 🔥 КОПІЮВАННЯ
  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Скопійовано")),
    );
  }

  // 🔥 МІКРОФОН (заглушка)
  void _voiceInput() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Тут буде голосовий ввід 🎤")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: AppDrawer(
        history: _history,
        onFileOpen: _openFileScreen,
        onSelectHistory: (text) {
          _inputController.text = text;
        },
      ),

      appBar: AppBar(
        title: const Text("AI Text Analyzer"),
        actions: [
          if (_isRegistered)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(
                  'Привіт, $_userName',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _showRegisterScreen,
              child: const Text(
                'Реєстрація',
                style: TextStyle(color: Colors.white),
              ),
            ),
          IconButton(
            icon: Icon(themeProvider.isDark ? Icons.nights_stay : Icons.wb_sunny),
            onPressed: () => themeProvider.toggleTheme(),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            DropdownButton<String>(
              value: _selectedAction,
              isExpanded: true,
              items: _actions.keys.map((e) {
                return DropdownMenuItem(value: e, child: Text(e));
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedAction = val!;
                });
              },
            ),

            if (_selectedAction == 'Переклад')
              DropdownButton<String>(
                value: _selectedLanguage,
                isExpanded: true,
                items: _languages.entries.map((e) {
                  return DropdownMenuItem(
                    value: e.value,
                    child: Text(e.key),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedLanguage = val!;
                  });
                },
              ),

            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: isDark
                    ? null
                    : Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                _isRegistered
                    ? 'Ліміт: 1000 символів'
                    : 'Ви не зареєстровані. Ліміт: 300 символів',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 🔥 INPUT
            Expanded(
              child: TextPanel(
                controller: _inputController,
                hint: 'Введіть текст...',
                isDark: isDark,
                isInput: true,
                onVoiceTap: _voiceInput,
                onCopy: () => _copy(_inputController.text),
              ),
            ),

            const SizedBox(height: 10),

            // 🔥 OUTPUT
            Expanded(
              child: TextPanel(
                text: _outputText,
                isDark: isDark,
                isLoading: _isLoading,
                onCopy: () => _copy(_outputText),
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleProcess,
                    child: const Text("Обробити"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _reuseText,
                    child: const Text("Використати"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}