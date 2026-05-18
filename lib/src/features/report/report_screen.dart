import 'package:flutter/material.dart';

class ReportScreen extends StatefulWidget {
  final List<Map<String, String>> history;

  const ReportScreen({super.key, required this.history});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String _report = '';

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

  void _downloadReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Завантаження (імітація)")),
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
              onPressed: _report.isEmpty ? null : _downloadReport,
              icon: const Icon(Icons.download),
              label: const Text("Завантажити"),
            ),
          ],
        ),
      ),
    );
  }
}