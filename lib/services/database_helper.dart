import 'package:hive_flutter/hive_flutter.dart';
import '../model/note_model.dart';

class NoteDataSource {
  static const _boxName = 'notesBox';

  // Open or return the existing Hive box
  static Future<Box<Note>> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox<Note>(_boxName);
    }
    return Hive.box<Note>(_boxName);
  }

  // Insert a new note into the box
  static Future<void> insertNote(Note note) async {
    final box = await _getBox();
    await box.add(note);
  }

  // Get all notes as a list
  static Future<List<Note>> getNotes() async {
    final box = await _getBox();
    return box.values.toList();
  }

  // Update a note by matching its ID
  static Future<void> updateNoteById(String id, Note updatedNote) async {
    final box = await _getBox();

    final keyToUpdate = box.keys.firstWhere(
          (key) => box.get(key)?.id == id,
      orElse: () => null,
    );

    if (keyToUpdate != null) {
      await box.put(keyToUpdate, updatedNote);
    }
  }

  static Future<void> togglePinStatus(String id, bool newStatus) async {
    final box = await _getBox();

    final key = box.keys.firstWhere(
          (key) => box.get(key)?.id == id,
      orElse: () => null,
    );

    if (key != null) {
      final note = box.get(key);
      if (note != null) {
        final updatedNote = Note(
          title: note.title,
          content: note.content,
          dateTime: note.dateTime,
          id: note.id,
          isPinned: newStatus, // Update only pin status
        );
        await box.put(key, updatedNote);
      }
    }
  }

  // Delete a note by matching its ID
  static Future<void> deleteNoteById(String id) async {
    final box = await _getBox();

    final keyToDelete = box.keys.firstWhere(
          (key) => box.get(key)?.id == id,
      orElse: () => null,
    );

    if (keyToDelete != null) {
      await box.delete(keyToDelete);
    }
  }

  // Optional: Clear all notes in the box
  static Future<void> clearAllNotes() async {
    final box = await _getBox();
    await box.clear();
  }
}
