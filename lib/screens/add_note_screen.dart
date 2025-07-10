import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/note_model.dart';
import '../services/database_helper.dart';
import '../theme/theme_notifier.dart';
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
    final isDark = Provider.of<ThemeNotifier>(context).isDarkMode;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    final labelColor = isDark ? Colors.white54 : Colors.black54;

    return Scaffold(
      backgroundColor: backgroundColor,
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
        backgroundColor: backgroundColor,
      ),
      body: Container(
        color: backgroundColor,
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
                  hintStyle: TextStyle(color: labelColor),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: labelColor),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: labelColor.withOpacity(0.6)),
                  ),
                ),
                style: TextStyle(color: textColor),
                maxLines: 1,
              ),
              SizedBox(height: 16),
              TextField(
                controller: _contentController,
                decoration: InputDecoration(
                  hintText: 'Note',
                  hintStyle: TextStyle(color: labelColor),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: labelColor),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: labelColor.withOpacity(0.6)),
                  ),
                ),
                style: TextStyle(color: textColor),
                keyboardType: TextInputType.multiline,
                maxLines: null,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category (optional)',
                  labelStyle: TextStyle(color: labelColor),
                  filled: true,
                  fillColor: isDark ? Colors.black26 : Colors.grey[200],
                  border: OutlineInputBorder(),
                ),
                dropdownColor: isDark ? Colors.grey[900] : Colors.white,
                iconEnabledColor: textColor,
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('None'),
                  ),
                  ..._categoryOptions.map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                style: TextStyle(color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
