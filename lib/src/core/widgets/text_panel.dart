import 'package:flutter/material.dart';

class TextPanel extends StatelessWidget {
  final TextEditingController? controller;
  final String text;
  final String hint;
  final bool isDark;
  final bool isLoading;
  final bool isInput;
  final VoidCallback? onVoiceTap;
  final VoidCallback onCopy;

  const TextPanel({
    super.key,
    this.controller,
    this.text = '',
    this.hint = '',
    required this.isDark,
    this.isLoading = false,
    this.isInput = false,
    this.onVoiceTap,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: isDark
            ? null
            : Border.all(color: Colors.grey.shade300, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isInput && onVoiceTap != null)
                IconButton(
                  icon: const Icon(Icons.mic),
                  onPressed: onVoiceTap,
                ),
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: onCopy,
              ),
            ],
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : controller != null
                    ? TextField(
                        controller: controller,
                        maxLines: null,
                        expands: true,
                        decoration: InputDecoration(
                          hintText: hint,
                          border: InputBorder.none,
                        ),
                      )
                    : SingleChildScrollView(
                        child: Text(
                          text.isEmpty ? 'Тут буде результат...' : text,
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
