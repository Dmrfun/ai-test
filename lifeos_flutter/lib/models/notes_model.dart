import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kNotesKey = 'lifeos_notes';

class Note {
  final String id;
  String title;
  String content;
  List<String> tags;
  final bool isJournal;
  final String date;
  final DateTime createdAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.tags,
    this.isJournal = false,
    required this.date,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'tags': tags,
        'isJournal': isJournal,
        'date': date,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Note.fromJson(Map<String, dynamic> j) => Note(
        id: j['id'] as String,
        title: j['title'] as String,
        content: j['content'] as String,
        tags: List<String>.from(j['tags'] as List? ?? []),
        isJournal: j['isJournal'] as bool? ?? false,
        date: j['date'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}

class NotesModel extends ChangeNotifier {
  List<Note> notes;

  NotesModel({List<Note>? notes}) : notes = notes ?? [];

  List<Note> get allNotes => List.from(notes.reversed);
  List<Note> get journalEntries =>
      notes.where((n) => n.isJournal).toList().reversed.toList();

  Note? get latestJournal {
    final j = notes.where((n) => n.isJournal).toList();
    return j.isEmpty ? null : j.last;
  }

  void addNote(String title, String content, List<String> tags) {
    notes.add(Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      tags: tags,
      date: DateTime.now().toIso8601String().substring(0, 10),
      createdAt: DateTime.now(),
    ));
    _save();
    notifyListeners();
  }

  void addJournalEntry(String content, {String mood = 'neutral'}) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    notes.add(Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Journal — $today',
      content: content,
      tags: ['journal', 'mood:$mood'],
      isJournal: true,
      date: today,
      createdAt: DateTime.now(),
    ));
    _save();
    notifyListeners();
  }

  void deleteNote(String id) {
    notes.removeWhere((n) => n.id == id);
    _save();
    notifyListeners();
  }

  List<Note> search(String keyword) {
    final kw = keyword.toLowerCase();
    return notes.where((n) =>
        n.title.toLowerCase().contains(kw) ||
        n.content.toLowerCase().contains(kw) ||
        n.tags.any((t) => t.toLowerCase().contains(kw))).toList();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_kNotesKey, jsonEncode(notes.map((n) => n.toJson()).toList()));
  }

  static Future<NotesModel> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kNotesKey);
    if (raw == null) return NotesModel();
    final list = jsonDecode(raw) as List;
    return NotesModel(
        notes: list.map((e) => Note.fromJson(e as Map<String, dynamic>)).toList());
  }
}
