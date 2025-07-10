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

  String? _selectedCategory;

  final List<String> _categoryOptions = ['Work', 'Personal', 'Ideas', 'Other'];

  Future<void> _saveNote() async {
    if (_titleController.text.isNotEmpty && _contentController.text.isNotEmpty) {
      final updatedNote = Note(
        title: _titleController.text,
        content: _contentController.text,
        category: _selectedCategory,
        dateTime: DateTime.now().toString(),
        id: widget.note?.id ?? uuid.v4(),
        isPinned: widget.note?.isPinned ?? false,
      );

      try {
        if (widget.note != null) {
          await NoteDataSource.updateNoteById(widget.note!.id, updatedNote);
        } else {
          await NoteDataSource.insertNote(updatedNote);
        }

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
      _selectedCategory = widget.note!.category;
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
      backgroundColor: const Color(0xFF1C1C1C),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.lightBlue),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: Colors.lightBlue),
            onPressed: _saveNote,
          ),
        ],
        backgroundColor: const Color(0xFF1C1C1C),
      ),
      body: Container(
        color: const Color(0xFF1C1C1C),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category (optional)',
                  labelStyle: TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(),
                ),
                dropdownColor: Colors.grey[900],
                iconEnabledColor: Colors.white,
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('None', style: TextStyle(color: Colors.white)),
                  ),
                  ..._categoryOptions.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category, style: TextStyle(color: Colors.white)),
                  );
                }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
