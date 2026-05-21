import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final TextEditingController _reportTitleController = TextEditingController();

  String _fileName = '';
  bool _isLoading = false;
  bool _isDownloadingReport = false;

  final List<Map<String, String>> _history = [];

  late Map<String, String> _actions;
  late Map<String, String> _languages;

  late String _selectedAction;
  late String _selectedLanguage;

  int get _charCount => _controller.text.length;
  int get _wordCount {
    final text = _controller.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }

  String _suggestReportTitle([String? text]) {
    final content = (text ?? _controller.text).trim();
    if (content.isEmpty) return 'AI Analysis Report';

    final firstSentence = content.split(RegExp(r'[.!?]\s+')).first;
    final words = firstSentence.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length <= 5) return words.map((w) => _capitalizeWord(w)).join(' ');
    return '${words.take(5).map((w) => _capitalizeWord(w)).join(' ')}...';
  }

  String _capitalizeWord(String word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1);
  }

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

      if (_reportTitleController.text.trim().isEmpty) {
        _reportTitleController.text = _suggestReportTitle();
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

    final currentAutoTitle = _suggestReportTitle();
    final titleWasAuto = _reportTitleController.text.trim().isEmpty ||
        _reportTitleController.text.trim() == currentAutoTitle;

    try {
      final result = await ApiService.processText(endpoint, body);

      if (endpoint == '/check' && result is Map<String, dynamic>) {
        final mistakes = result['mistakes'] as List<dynamic>? ?? [];
        final styleOutput = result['style'] ?? '';
        final correctedText = result['text'] ?? '';
        final originalText = _controller.text;

        setState(() {
          _controller.text = correctedText.isNotEmpty ? correctedText : styleOutput;
          _isLoading = false;
        });

        _showCheckResultDialog(mistakes, originalText, correctedText);
      } else {
        final processedText = result.toString();
        setState(() {
          _controller.text = processedText;
          if (endpoint == '/translate' && titleWasAuto) {
            _reportTitleController.text = _suggestReportTitle(processedText);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Помилка обробки: $e')),
      );
    }
  }

  void _showCheckResultDialog(List<dynamic> mistakes, String originalText, String correctedText) {
    showDialog(
      context: context,
      builder: (_) {
        final changed = correctedText.isNotEmpty && correctedText != originalText;
        final noChanges = mistakes.isNotEmpty && !changed;

        return AlertDialog(
          title: Text(mistakes.isEmpty
              ? 'Перевірка пройшла успішно'
              : 'Знайдено ${mistakes.length} помилок'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (mistakes.isEmpty) ...[
                  const Text('У вашому тексті немає помилок'),
                ] else ...[
                  if (noChanges)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text('Помилки знайдено, але текст не змінився.'),
                    ),
                  const Text('Список помилок:'),
                  const SizedBox(height: 8),
                  ...mistakes.map((mistake) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(_formatMistake(mistake)),
                    );
                  }),
                ],
                const SizedBox(height: 16),
                const Text('Оригінальний текст:'),
                const SizedBox(height: 8),
                Text(originalText),
                if (changed) ...[
                  const SizedBox(height: 16),
                  const Text('Виправлений текст:'),
                  const SizedBox(height: 8),
                  Text(correctedText),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Закрити'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _generateReport(String format) async {
    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Текст для звіту порожній')),
      );
      return;
    }

    setState(() {
      _isDownloadingReport = true;
    });

    final endpoint = format == 'pdf' ? '/report/pdf' : '/report/docx';
    final filename = 'report_${DateTime.now().millisecondsSinceEpoch}.${format == 'pdf' ? 'pdf' : 'docx'}';
    final title = _reportTitleController.text.trim().isEmpty
        ? _suggestReportTitle()
        : _reportTitleController.text.trim();

    final message = await ApiService.downloadReport(
      endpoint,
      {
        'text': _controller.text,
        'title': title,
      },
      filename,
    );

    if (!mounted) return;
    setState(() {
      _isDownloadingReport = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showReportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Завантажити звіт PDF'),
              onTap: () {
                Navigator.pop(context);
                _generateReport('pdf');
              },
            ),
            ListTile(
              leading: const Icon(Icons.article),
              title: const Text('Завантажити звіт DOCX'),
              onTap: () {
                Navigator.pop(context);
                _generateReport('docx');
              },
            ),
          ],
        );
      },
    );
  }

  String _formatMistake(dynamic mistake) {
    if (mistake == null) return '';
    if (mistake is String) return mistake;
    if (mistake is Map) {
      if (mistake.containsKey('message')) {
        return mistake['message'].toString();
      }
      if (mistake.containsKey('error')) {
        return mistake['error'].toString();
      }
      return mistake.entries
          .map((entry) => '${entry.key}: ${entry.value}')
          .join('; ');
    }
    return mistake.toString();
  }


  void _downloadTXT() {
    final bytes = utf8.encode(_controller.text);
    downloadBytes(bytes, 'result.txt');
  }


  String _sanitizeFileName(String name) {
    final sanitized = name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
    return sanitized.isEmpty ? 'document' : sanitized;
  }

  Future<pw.Font> _loadPdfFont() async {
    if (kIsWeb) {
      return pw.Font.helvetica();
    }

    final fontCandidates = <String>[];
    if (Platform.isWindows) {
      fontCandidates.addAll([
        r'C:\Windows\Fonts\arial.ttf',
        r'C:\Windows\Fonts\tahoma.ttf',
        r'C:\Windows\Fonts\calibri.ttf',
      ]);
    } else if (Platform.isLinux) {
      fontCandidates.add('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf');
    } else if (Platform.isMacOS) {
      fontCandidates.addAll([
        '/Library/Fonts/Arial.ttf',
        '/Library/Fonts/Helvetica.ttf',
      ]);
    }

    for (final path in fontCandidates) {
      final file = File(path);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        return pw.Font.ttf(bytes.buffer.asByteData());
      }
    }

    return pw.Font.helvetica();
  }

  Future<void> _downloadPDF() async {
    final title = _reportTitleController.text.trim().isEmpty
        ? _suggestReportTitle()
        : _reportTitleController.text.trim();

    final font = await _loadPdfFont();
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                font: font,
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              _controller.text,
              style: pw.TextStyle(
                font: font,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );

    final bytes = await pdf.save();
    downloadBytes(bytes, '${_sanitizeFileName(title)}.pdf');
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
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_open),
              title: const Text("Файли"),
              selected: true,
              onTap: () => Navigator.pop(context),
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

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: isDark
                    ? null
                    : Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Файл: ${_fileName.isEmpty ? 'Без назви' : _fileName}'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      Text('Символів: $_charCount'),
                      Text('Слів: $_wordCount'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _reportTitleController,
                    decoration: InputDecoration(
                      labelText: 'Заголовок документу',
                      hintText: _suggestReportTitle(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
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
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _controller.text.isEmpty || _isDownloadingReport
                        ? null
                        : _showReportOptions,
                    child: Text(_isDownloadingReport
                        ? 'Генеруємо звіт...'
                        : 'Завантажити звіт'),
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