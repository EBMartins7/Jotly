import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/note_model.dart';
import 'package:intl/intl.dart';
import '../theme/theme_notifier.dart';

class NotePreviewScreen extends StatelessWidget {
  final Note note;

  const NotePreviewScreen({super.key, required this.note});

  String _formatDate(String rawDate) {
    try {
      final date = DateTime.parse(rawDate);
      return DateFormat('MMM d, yyyy • h:mm a').format(date);
    } catch (_) {
      return rawDate;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Work':
        return Colors.deepOrangeAccent;
      case 'Personal':
        return Colors.tealAccent;
      case 'Ideas':
        return Colors.amberAccent;
      case 'Other':
        return Colors.purpleAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeNotifier>(context).isDarkMode;
    final theme = Theme.of(context);
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.white60 : Colors.black54;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        iconTheme: IconThemeData(color: theme.appBarTheme.foregroundColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.lightBlue),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/add',
                arguments: {'note': note},
              ).then((result) {
                if (result == true) Navigator.pop(context, true);
              });
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatDate(note.dateTime),
                style: TextStyle(color: subTextColor, fontSize: 13),
              ),
              const SizedBox(height: 16),
              if (note.category != null && note.category!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(note.category!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    note.category!,
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
              if (note.category != null && note.category!.isNotEmpty)
                const SizedBox(height: 16),
              if (note.isPinned)
                Row(
                  children: const [
                    Icon(Icons.push_pin, size: 20, color: Colors.lightBlue),
                    SizedBox(width: 6),
                    Text("Pinned", style: TextStyle(color: Colors.lightBlue))
                  ],
                ),
              if (note.isPinned) const SizedBox(height: 16),
              Text(
                note.content,
                style: TextStyle(fontSize: 16, color: subTextColor, height: 1.5),
              )
            ],
          ),
        ),
      ),
    );
  }
}
