import 'package:flutter/material.dart';
import '../model/note_model.dart';
import 'package:intl/intl.dart';

class NotePreviewScreen extends StatelessWidget {
  final Note note;

  const NotePreviewScreen({super.key, required this.note});

  // ✅ Format the note's date to something human-readable
  String _formatDate(String rawDate) {
    try {
      final date = DateTime.parse(rawDate);
      return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return rawDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1C),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.lightBlue),
            onPressed: () {
              // ✅ Navigate to AddNoteScreen in edit mode with note passed as argument
              Navigator.pushNamed(
                context,
                '/add',
                arguments: {'note': note},
              ).then((result) {
                if (result == true) Navigator.pop(context, true); // refresh if edited
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
              // ✅ Note Title
              Text(
                note.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),

              // ✅ Date/Time Display
              Text(
                DateFormat('MMM d, yyyy • h:mm a').format(DateTime.parse(note.dateTime)),
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 16),

              // ✅ Category label if exists
              if (note.category != null && note.category!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(note.category!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    note.category!,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),

              if (note.category != null && note.category!.isNotEmpty)
                const SizedBox(height: 16),

              // ✅ Pinned Icon
              if (note.isPinned)
                Row(
                  children: const [
                    Icon(Icons.push_pin, size: 20, color: Colors.lightBlue),
                    SizedBox(width: 6),
                    Text("Pinned", style: TextStyle(color: Colors.lightBlue))
                  ],
                ),
              if (note.isPinned) const SizedBox(height: 16),

              // ✅ Note Content
              Text(
                note.content,
                style: const TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
              )
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Assign a background color to each category
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Work':
        return Colors.orange;
      case 'Personal':
        return Colors.green;
      case 'Ideas':
        return Colors.purple;
      case 'Other':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }
}
