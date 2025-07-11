import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/note_model.dart';
import '../services/database_helper.dart';
import 'package:hive/hive.dart';
import 'package:lottie/lottie.dart';
import '../theme/theme_notifier.dart';
import 'note_preview_screen.dart';

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

  Set<String> _selectedNoteIds = {};
  bool _isSelectionMode = false;
  String? _selectedCategory;

  final Map<String, Color> categoryColors = {
    'Work': Colors.deepOrangeAccent,
    'Personal': Colors.tealAccent,
    'Ideas': Colors.amberAccent,
    'Other': Colors.purpleAccent,
  };

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
      final matchesQuery =
          titleLower.contains(searchLower) || contentLower.contains(searchLower);
      final matchesCategory =
          _selectedCategory == null || note.category == _selectedCategory;
      return matchesQuery && matchesCategory;
    }).toList();
  }

  void _filterNotes(String query) {
    setState(() {
      _filteredNotes = _applySearchFilter(_notes, query);
    });
  }

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

  Future<void> _deleteSelectedNotes() async {
    final notesToDelete =
    _notes.where((note) => _selectedNoteIds.contains(note.id)).toList();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final hintColor = isDark ? Colors.white54 : Colors.black54;
    final iconColor = Theme.of(context).iconTheme.color;
    final tileColor = isDark ? Colors.black45 : Colors.grey.shade200;

    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('${_selectedNoteIds.length} selected')
            : const Text('Jotly'),
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6, color: iconColor),
            onPressed: () {
              Provider.of<ThemeNotifier>(context, listen: false).toggleTheme();
            },
          ),
          if (_isSelectionMode) ...[
            IconButton(
              icon: Icon(
                _selectedNoteIds.length == _filteredNotes.length
                    ? Icons.select_all
                    : Icons.done_all,
              ),
              onPressed: _toggleSelectAll,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelectedNotes,
            ),
          ] else ...[
            IconButton(
              icon: Icon(Icons.category, color: iconColor),
              onPressed: () async {
                final selected = await showMenu<String?>(
                  context: context,
                  position: const RelativeRect.fromLTRB(1000, 80, 10, 0),
                  items: [
                    const PopupMenuItem(value: null, child: Text('All')),
                    ...['Work', 'Personal', 'Ideas', 'Other'].map(
                          (category) => PopupMenuItem(
                        value: category,
                        child: Text(category),
                      ),
                    ),
                  ],
                );
                if (selected != null || _selectedCategory != null) {
                  setState(() {
                    _selectedCategory = selected;
                    _filteredNotes = _applySearchFilter(_notes, _searchController.text);
                  });
                }
              },
            ),
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
              icon: Icon(Icons.sort, color: iconColor),
            )
          ]
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Search notes...',
                hintStyle: TextStyle(color: hintColor),
                prefixIcon: Icon(Icons.search, color: hintColor),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: hintColor),
                  onPressed: () {
                    _searchController.clear();
                    _filterNotes('');
                    _searchFocusNode.unfocus();
                  },
                )
                    : null,
                filled: true,
                fillColor: tileColor,
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
                final isSelected = _selectedNoteIds.contains(note.id);
                final firstLine = note.content.split('\n').first.length > 50
                    ? note.content.split('\n').first.substring(0, 50) + '...'
                    : note.content.split('\n').first;

                return GestureDetector(
                  onTap: () {
                    if (_isSelectionMode) {
                      _toggleSelection(note.id);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NotePreviewScreen(note: note),
                        ),
                      ).then((value) {
                        if (value == true) _loadNotes();
                      });
                    }
                  },
                  onLongPress: () => _toggleSelection(note.id),
                  child: Container(
                    color: isSelected ? Colors.blueGrey[200] : Colors.transparent,
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          title: Text(
                            note.title,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                firstLine,
                                style: TextStyle(color: hintColor),
                              ),
                              if (note.category != null && note.category!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: categoryColors[note.category] ?? Colors.grey,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      note.category!,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
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
                                  padding:
                                  const EdgeInsets.only(right: 8.0),
                                  child: Icon(Icons.push_pin,
                                      color: Colors.lightBlue, size: 20),
                                ),
                              PopupMenuButton<String>(
                                icon: Icon(Icons.more_vert,
                                    color: hintColor),
                                onSelected: (value) async {
                                  if (value == 'delete') {
                                    final deletedNote = note;
                                    await NoteDataSource
                                        .deleteNoteById(note.id);
                                    _loadNotes();
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content:
                                        const Text("Note deleted"),
                                        action: SnackBarAction(
                                          label: "Undo",
                                          onPressed: () async {
                                            await NoteDataSource
                                                .insertNote(
                                                deletedNote);
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
                                      category: note.category,
                                    );
                                    await NoteDataSource.updateNoteById(
                                        note.id, updatedNote);
                                    _loadNotes();
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'pin',
                                    child: Text(note.isPinned
                                        ? 'Unpin'
                                        : 'Pin'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete',
                                        style: TextStyle(
                                            color: Colors.red)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Divider(thickness: 0.5),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: !_isSelectionMode
          ? FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/add');
          if (result == true) _loadNotes();
        },
        backgroundColor: Colors.lightBlue,
        child: const Icon(Icons.add, color: Colors.black),
      )
          : null,
    );
  }
}
