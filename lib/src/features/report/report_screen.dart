import 'package:flutter/material.dart';
import 'package:text_analyzer/src/core/services/api_service.dart';

class ReportScreen extends StatefulWidget {
  final List<Map<String, String>> history;

  const ReportScreen({super.key, required this.history});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String _report = '';
  bool _isDownloading = false;

  void _generateReport(String type) {
    if (type == 'Короткий') {
      _report = "Кількість запитів: ${widget.history.length}";
    } else if (type == 'Детальний') {
      _report = widget.history
          .map((e) => "${e['action']} → ${e['text']}")
          .join("\n\n");
    }
    setState(() {});
  }

  Future<void> _downloadReport(String format) async {
    if (_report.isEmpty) return;

    setState(() {
      _isDownloading = true;
    });

    final endpoint = format == 'pdf' ? '/report/pdf' : '/report/docx';
    final filename = 'report_${DateTime.now().millisecondsSinceEpoch}.${format == 'pdf' ? 'pdf' : 'docx'}';

    final message = await ApiService.downloadReport(
      endpoint,
      {
        'text': _report,
        'title': 'AI Analysis Report',
      },
      filename,
    );

    if (!mounted) return;

    setState(() {
      _isDownloading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showDownloadOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Завантажити PDF'),
              onTap: () {
                Navigator.pop(context);
                _downloadReport('pdf');
              },
            ),
            ListTile(
              leading: const Icon(Icons.article),
              title: const Text('Завантажити DOCX'),
              onTap: () {
                Navigator.pop(context);
                _downloadReport('docx');
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Звіти")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => _generateReport('Короткий'),
                  child: const Text("Короткий"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _generateReport('Детальний'),
                  child: const Text("Детальний"),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Colors.grey[200],
                child: SingleChildScrollView(
                  child: Text(_report.isEmpty
                      ? "Оберіть тип звіту"
                      : _report),
                ),
              ),
            ),

            ElevatedButton.icon(
              onPressed: _report.isEmpty || _isDownloading ? null : _showDownloadOptions,
              icon: const Icon(Icons.download),
              label: Text(
                _isDownloading ? 'Завантаження...' : 'Завантажити',
              ),
            ),
          ],
        ),
      ),
    );
  }
}