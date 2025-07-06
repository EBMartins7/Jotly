import 'package:flutter/material.dart';
import '../model/note_model.dart';
import '../services/database_helper.dart';
import 'package:hive/hive.dart';
import 'package:lottie/lottie.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _sortOption = 'Newest First';

  // ✅ ADDED: Selection state for multi-select delete
  Set<String> _selectedNoteIds = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _loadSortPreference();
    _searchController.addListener(() {
      _filterNotes(_searchController.text);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.unfocus();
    });
  }

  void _loadSortPreference() async {
    final box = Hive.box('settingsBox');
    final savedSort = box.get('sortOption', defaultValue: 'Newest First');
    setState(() {
      _sortOption = savedSort;
    });
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final notes = await NoteDataSource.getNotes();

    notes.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;

      switch (_sortOption) {
        case 'Oldest First':
          return a.dateTime.compareTo(b.dateTime);
        case 'Title (A-Z)':
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case 'Newest First':
        default:
          return b.dateTime.compareTo(a.dateTime);
      }
    });

    setState(() {
      _notes = notes;
      _filteredNotes = _applySearchFilter(notes, _searchController.text);
    });
  }

  List<Note> _applySearchFilter(List<Note> notes, String query) {
    final searchLower = query.toLowerCase();
    return notes.where((note) {
      final titleLower = note.title.toLowerCase();
      final contentLower = note.content.toLowerCase();
      return titleLower.contains(searchLower) || contentLower.contains(searchLower);
    }).toList();
  }

  void _filterNotes(String query) {
    setState(() {
      _filteredNotes = _applySearchFilter(_notes, query);
    });
  }

  // ✅ ADDED: Selection toggle logic
  void _toggleSelection(String noteId) {
    setState(() {
      if (_selectedNoteIds.contains(noteId)) {
        _selectedNoteIds.remove(noteId);
      } else {
        _selectedNoteIds.add(noteId);
      }
      _isSelectionMode = _selectedNoteIds.isNotEmpty;
    });
  }

  void _cancelSelection() {
    setState(() {
      _selectedNoteIds.clear();
      _isSelectionMode = false;
    });
  }

  // ✅ ADDED: Delete selected notes
  Future<void> _deleteSelectedNotes() async {
    final notesToDelete = _notes.where((note) => _selectedNoteIds.contains(note.id)).toList();
    final backupNotes = [...notesToDelete];

    for (var note in notesToDelete) {
      await NoteDataSource.deleteNoteById(note.id);
    }

    _cancelSelection();
    _loadNotes();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${backupNotes.length} note(s) deleted"),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            for (var note in backupNotes) {
              await NoteDataSource.insertNote(note);
            }
            _loadNotes();
          },
        ),
      ),
    );
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedNoteIds.length == _filteredNotes.length) {
        _selectedNoteIds.clear();
      } else {
        _selectedNoteIds = _filteredNotes.map((note) => note.id).toSet();
      }
      _isSelectionMode = _selectedNoteIds.isNotEmpty;
    });
  }


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // ✅ UPDATED: Show selection count or normal title
        title: _isSelectionMode
            ? Text('${_selectedNoteIds.length} selected', style: TextStyle(color: Colors.white))
            : Text('My Notes', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1C1C1C),
        leading: _isSelectionMode
            ? IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: _cancelSelection,
        )
            : null,
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: Icon(
                _selectedNoteIds.length == _filteredNotes.length
                    ? Icons.select_all
                    : Icons.done_all,
                color: Colors.white,
              ),
              onPressed: _toggleSelectAll,
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.white),
              onPressed: _deleteSelectedNotes,
            ),
          ]
          else
            PopupMenuButton<String>(
              onSelected: (value) async {
                final box = Hive.box('settingsBox');
                await box.put('sortOptions', value);
                setState(() {
                  _sortOption = value;
                });
                _loadNotes();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'Newest First', child: Text('Newest First')),
                const PopupMenuItem(value: 'Oldest First', child: Text('Oldest First')),
                const PopupMenuItem(value: 'Title (A-Z)', child: Text('Title (A-Z)')),
              ],
              icon: const Icon(Icons.sort, color: Colors.white),
            )
        ],
      ),
      body: Container(
        color: const Color(0xFF1C1C1C),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search notes...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white54),
                    onPressed: () {
                      _searchController.clear();
                      _filterNotes('');
                      _searchFocusNode.unfocus();
                    },
                  )
                      : null,
                  filled: true,
                  fillColor: Colors.black45,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _filteredNotes.isEmpty
                  ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Lottie.asset(
                    'assets/animations/empty.json',
                    width: 200,
                    repeat: true,
                  ),
                ),
              )
                  : ListView.builder(
                itemCount: _filteredNotes.length,
                itemBuilder: (context, index) {
                  final note = _filteredNotes[index];
                  final firstLine = note.content.split('\n').first.length > 50
                      ? note.content.split('\n').first.substring(0, 50) + '...'
                      : note.content.split('\n').first;

                  final isSelected = _selectedNoteIds.contains(note.id); // ✅

                  return GestureDetector(
                    onTap: () {
                      if (_isSelectionMode) {
                        _toggleSelection(note.id); // ✅
                      } else {
                        Navigator.pushNamed(
                          context,
                          '/add',
                          arguments: {'note': note},
                        ).then((value) {
                          if (value == true) _loadNotes();
                        });
                      }
                    },
                    onLongPress: () => _toggleSelection(note.id), // ✅
                    child: Container(
                      color: isSelected ? Colors.blueGrey[700] : Colors.transparent,
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            title: Text(
                              note.title,
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              firstLine,
                              style: TextStyle(color: Colors.white70),
                            ),
                            trailing: _isSelectionMode
                                ? Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: Colors.lightBlue,
                            )
                                : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (note.isPinned)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Icon(Icons.push_pin,
                                        color: Colors.lightBlue, size: 20),
                                  ),
                                PopupMenuButton<String>(
                                  icon: Icon(Icons.more_vert, color: Colors.white54),
                                  onSelected: (value) async {
                                    if (value == 'delete') {
                                      final deletedNote = note;
                                      await NoteDataSource.deleteNoteById(note.id);
                                      _loadNotes();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text("Note deleted"),
                                          action: SnackBarAction(
                                            label: "Undo",
                                            onPressed: () async {
                                              await NoteDataSource.insertNote(deletedNote);
                                              _loadNotes();
                                            },
                                          ),
                                        ),
                                      );
                                    } else if (value == 'pin') {
                                      final updatedNote = Note(
                                        title: note.title,
                                        content: note.content,
                                        dateTime: note.dateTime,
                                        id: note.id,
                                        isPinned: !note.isPinned,
                                      );
                                      await NoteDataSource.updateNoteById(
                                          note.id, updatedNote);
                                      _loadNotes();
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'pin',
                                      child: Text(note.isPinned ? 'Unpin' : 'Pin'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete',
                                          style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Divider(
                            color: Colors.white24,
                            thickness: 0.5,
                            indent: 16,
                            endIndent: 16,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: !_isSelectionMode
          ? Transform.translate(
        offset: Offset(0, -20),
        child: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.pushNamed(context, '/add');
            if (result == true) _loadNotes();
          },
          backgroundColor: Colors.lightBlue,
          shape: CircleBorder(),
          child: Icon(Icons.add, color: Colors.black),
        ),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
