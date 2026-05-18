import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:text_analyzer/src/core/services/api_service.dart';
import 'package:text_analyzer/src/core/services/download_service.dart';
import 'package:text_analyzer/src/core/theme/theme_provider.dart';
import 'package:text_analyzer/src/shared/constants.dart';

class FileScreen extends StatefulWidget {
  const FileScreen({super.key});

  @override
  State<FileScreen> createState() => _FileScreenState();
}

class _FileScreenState extends State<FileScreen> {
  final TextEditingController _controller = TextEditingController();

  String _fileName = '';
  bool _isLoading = false;

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
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'pdf', 'docx'],
      withData: true,
    );

    if (result == null) return;

    final file = result.files.first;

    setState(() {
      _fileName = file.name;
      _isLoading = true;
    });

    try {
      if (file.extension == 'txt') {
        final content = utf8.decode(file.bytes!);

        _controller.text = content;
      } else {
        final result = await ApiService.uploadFile(file);
        _controller.text = result;
      }

      _history.insert(0, {
        "name": _fileName,
        "content": _controller.text,
      });

    } catch (e) {
      _controller.text = 'Помилка читання файлу';
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _processText() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    final endpoint = _actions[_selectedAction]!;

    Map<String, dynamic> body = {
      "text": _controller.text,
    };

    if (endpoint == '/translate') {
      body["target_language"] = _selectedLanguage;
    }

    final result = await ApiService.processText(endpoint, body);

    setState(() {
      _controller.text =
          endpoint == '/check' ? result['style'] ?? '' : result;
      _isLoading = false;
    });
  }


  void _downloadTXT() {
    final bytes = utf8.encode(_controller.text);
    downloadBytes(bytes, 'result.txt');
  }


  Future<void> _downloadPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Text(_controller.text),
      ),
    );

    final bytes = await pdf.save();
    downloadBytes(bytes, 'result.pdf');
  }

  void _showDownloadDialog() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("TXT"),
              onTap: () {
                Navigator.pop(context);
                _downloadTXT();
              },
            ),
            ListTile(
              title: const Text("PDF"),
              onTap: () {
                Navigator.pop(context);
                _downloadPDF();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Файли"),
        actions: [
          Row(
            children: [
              Text(themeProvider.isDark ? "🌙" : "🌞"),
              Switch(
                value: themeProvider.isDark,
                onChanged: (_) => themeProvider.toggleTheme(),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),

      drawer: Drawer(
        child: Column(
          children: [
            const DrawerHeader(child: Text("Меню")),

            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Головна"),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            const Divider(),

            const Padding(
              padding: EdgeInsets.all(8),
              child: Text("Історія файлів"),
            ),

            Expanded(
              child: ListView.builder(
                itemCount: _history.length,
                itemBuilder: (_, i) {
                  final item = _history[i];

                  return ListTile(
                    title: Text(item["name"]!),
                    onTap: () {
                      _controller.text = item["content"]!;
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _pickFile,
              child: const Text("Завантажити файл"),
            ),

            DropdownButton<String>(
              value: _selectedAction,
              isExpanded: true,
              items: _actions.keys
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedAction = val!),
            ),

            if (_selectedAction == 'Переклад')
              DropdownButton<String>(
                value: _selectedLanguage,
                isExpanded: true,
                items: _languages.entries
                    .map((e) => DropdownMenuItem(
                          value: e.value,
                          child: Text(e.key),
                        ))
                    .toList(),
                onChanged: (val) =>
                    setState(() => _selectedLanguage = val!),
              ),

            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: isDark
                      ? null
                      : Border.all(color: Colors.grey.shade300),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : TextField(
                        controller: _controller,
                        maxLines: null,
                        expands: true,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                      ),
              ),
            ),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _processText,
                    child: const Text("Обробити"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _controller.text.isEmpty
                        ? null
                        : _showDownloadDialog,
                    child: const Text("Завантажити"),
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