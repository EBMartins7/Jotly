import 'package:flutter/material.dart';
import '../model/note_model.dart';
import '../services/database_helper.dart';
import 'package:uuid/uuid.dart';

class AddNoteScreen extends StatefulWidget {
  final Note? note;
  const AddNoteScreen({super.key, this.note});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final uuid = Uuid();

  Future<void> _saveNote() async {
    print("📝 Save note triggered");

    if (_titleController.text.isNotEmpty && _contentController.text.isNotEmpty) {
      final updatedNote = Note(
        title: _titleController.text,
        content: _contentController.text,
        dateTime: DateTime.now().toString(),
        id: widget.note?.id ?? uuid.v4(),
        isPinned: widget.note?.isPinned ?? false,
      );

      try {
        if (widget.note != null) {
          print("🔁 Updating existing note...");
          await NoteDataSource.updateNoteById(widget.note!.id, updatedNote);
        } else {
          print("➕ Inserting new note...");
          await NoteDataSource.insertNote(updatedNote);
        }

        print("✅ Note saved, popping...");
        Navigator.pop(context, true);
      } catch (e) {
        print("❌ Error saving note: $e");
      }
    } else {
      print("⚠️ Title or content is empty");
    }
  }



  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.lightBlue),
          onPressed: () {
            Navigator.pop(context); // Go back to HomeScreen
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: Colors.lightBlue),
            onPressed: _saveNote, // Save the note
          ),
        ],
        backgroundColor: const Color(0xFF1C1C1C),
      ),
      body: Container(
        color: const Color(0xFF1C1C1C),
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                  hintText: 'Title',
                  hintStyle: TextStyle(color: Colors.white38),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white38),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
              ),
              style: TextStyle(color: Colors.white),
              maxLines: 1,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                  hintText: 'Note',
                  hintStyle: TextStyle(color: Colors.white38),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white38),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
              ),
              style: TextStyle(color: Colors.white),
              keyboardType: TextInputType.multiline,
              maxLines: null,
            ),
          ],
        ),
      ),
    );
  }
}
