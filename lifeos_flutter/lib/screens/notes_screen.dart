import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notes_model.dart';
import '../theme/app_theme.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(children: [
          Icon(Icons.book_outlined,
              color: AppColors.notesColor, size: 20),
          const SizedBox(width: 8),
          const Text('NotesOS'),
        ]),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.notesColor,
          labelColor: AppColors.notesColor,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [Tab(text: 'Notes'), Tab(text: 'Journal')],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.accent),
            onPressed: () => _showAddDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search notes…',
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.textMuted, size: 18),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: AppColors.textMuted, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                        })
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _NotesTab(search: _search),
                _JournalTab(search: _search),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _AddNoteDialog(isJournal: _tabs.index == 1),
    );
  }
}

class _NotesTab extends StatelessWidget {
  final String search;

  const _NotesTab({required this.search});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<NotesModel>();
    final notes = search.isEmpty
        ? model.allNotes.where((n) => !n.isJournal).toList()
        : model.search(search).where((n) => !n.isJournal).toList();

    if (notes.isEmpty) {
      return Center(
          child: Text(
              search.isEmpty ? 'No notes yet' : 'No results for "$search"',
              style: const TextStyle(color: AppColors.textMuted)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: notes.length,
      itemBuilder: (_, i) => _NoteCard(note: notes[i]),
    );
  }
}

class _JournalTab extends StatelessWidget {
  final String search;

  const _JournalTab({required this.search});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<NotesModel>();
    final entries = search.isEmpty
        ? model.journalEntries
        : model.search(search).where((n) => n.isJournal).toList();

    if (entries.isEmpty) {
      return const Center(
          child: Text('No journal entries yet',
              style: TextStyle(color: AppColors.textMuted)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: entries.length,
      itemBuilder: (_, i) => _NoteCard(note: entries[i], isJournal: true),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;
  final bool isJournal;

  const _NoteCard({required this.note, this.isJournal = false});

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isJournal ? AppColors.notesColor.withOpacity(0.3) : AppColors.border;

    return GestureDetector(
      onTap: () => _openNote(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(isJournal ? '📔' : '📝',
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(note.title,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ),
                Text(note.date,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              note.content.length > 100
                  ? '${note.content.substring(0, 100)}…'
                  : note.content,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
            if (note.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: note.tags
                    .map((t) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                AppColors.notesColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(t,
                              style: const TextStyle(
                                  color: AppColors.notesColor,
                                  fontSize: 10)),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => _confirmDelete(context),
                  child: const Icon(Icons.delete_outline,
                      size: 16, color: AppColors.danger),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openNote(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Text(note.isJournal ? '📔' : '📝',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(note.title,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 16)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(note.date,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(height: 12),
              Text(note.content,
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.6)),
              if (note.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  children: note.tags
                      .map((t) => Chip(
                            label: Text(t),
                            backgroundColor:
                                AppColors.notesColor.withOpacity(0.12),
                            labelStyle: const TextStyle(
                                color: AppColors.notesColor, fontSize: 11),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close',
                  style: TextStyle(color: AppColors.accent))),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Note',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text('Delete "${note.title}"?',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              context.read<NotesModel>().deleteNote(note.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _AddNoteDialog extends StatefulWidget {
  final bool isJournal;
  const _AddNoteDialog({required this.isJournal});

  @override
  State<_AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<_AddNoteDialog> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  String _mood = 'neutral';
  late bool _isJournal;

  @override
  void initState() {
    super.initState();
    _isJournal = widget.isJournal;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Row(
        children: [
          Text(_isJournal ? '📔 Journal Entry' : '📝 New Note',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16)),
          const Spacer(),
          TextButton(
            onPressed: () => setState(() => _isJournal = !_isJournal),
            child: Text(_isJournal ? 'Switch to Note' : 'Switch to Journal',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isJournal) ...[
                TextField(
                  controller: _titleCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 10),
              ],
              TextField(
                controller: _contentCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                maxLines: 6,
                decoration: InputDecoration(
                    labelText: _isJournal ? 'Journal Entry' : 'Content'),
              ),
              const SizedBox(height: 10),
              if (_isJournal) ...[
                DropdownButtonFormField<String>(
                  value: _mood,
                  dropdownColor: AppColors.surfaceElevated,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Mood'),
                  items: const [
                    DropdownMenuItem(value: 'happy', child: Text('😊 Happy')),
                    DropdownMenuItem(
                        value: 'neutral', child: Text('😐 Neutral')),
                    DropdownMenuItem(value: 'sad', child: Text('😔 Sad')),
                    DropdownMenuItem(
                        value: 'stressed', child: Text('😤 Stressed')),
                    DropdownMenuItem(
                        value: 'grateful', child: Text('🙏 Grateful')),
                  ],
                  onChanged: (v) => setState(() => _mood = v!),
                ),
              ] else ...[
                TextField(
                  controller: _tagsCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                      labelText: 'Tags',
                      hintText: 'tag1, tag2, tag3'),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary))),
        ElevatedButton(
          onPressed: () {
            if (_contentCtrl.text.isEmpty) return;
            final model = context.read<NotesModel>();
            if (_isJournal) {
              model.addJournalEntry(_contentCtrl.text, mood: _mood);
            } else {
              final tags = _tagsCtrl.text
                  .split(',')
                  .map((t) => t.trim())
                  .where((t) => t.isNotEmpty)
                  .toList();
              model.addNote(
                  _titleCtrl.text.isEmpty ? 'Untitled' : _titleCtrl.text,
                  _contentCtrl.text,
                  tags);
            }
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
