import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  final List<Map<String, String>> history;
  final VoidCallback onFileOpen;
  final Function(String) onSelectHistory;

  const AppDrawer({
    super.key,
    required this.history,
    required this.onFileOpen,
    required this.onSelectHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            child: Text(
              'Меню',
              style: TextStyle(fontSize: 20),
            ),
          ),

          // 🔹 HOME
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Головна'),
            onTap: () => Navigator.pop(context),
          ),

          // 🔹 FILE
          ListTile(
            leading: const Icon(Icons.file_open),
            title: const Text('Файли'),
            onTap: () {
              Navigator.pop(context);
              onFileOpen();
            },
          ),

          const Divider(),

          const Padding(
            padding: EdgeInsets.all(8),
            child: Text("Історія"),
          ),

          Expanded(
            child: history.isEmpty
                ? const Center(child: Text("Пусто"))
                : ListView.builder(
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final item = history[index];

                      return ListTile(
                        title: Text(item['action'] ?? ''),
                        subtitle: Text(
                          item['text'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          onSelectHistory(item['text'] ?? '');
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}