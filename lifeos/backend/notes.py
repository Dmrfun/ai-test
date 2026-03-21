import json
import os
from datetime import datetime


DATA_FILE = os.path.join(os.path.dirname(__file__), '..', 'data', 'notes.json')


class NotesOS:
    def __init__(self):
        self.notes = []
        self.load()

    def load(self):
        if os.path.exists(DATA_FILE):
            with open(DATA_FILE, 'r') as f:
                self.notes = json.load(f)

    def save(self):
        os.makedirs(os.path.dirname(DATA_FILE), exist_ok=True)
        with open(DATA_FILE, 'w') as f:
            json.dump(self.notes, f, indent=2)

    def add_note(self, title, content, tags=None, is_journal=False):
        if tags is None:
            tags = []
        if isinstance(tags, str):
            tags = [t.strip() for t in tags.split(',') if t.strip()]
        note = {
            'title': title,
            'content': content,
            'tags': tags,
            'is_journal': is_journal,
            'date': datetime.now().strftime('%Y-%m-%d'),
            'created_at': datetime.now().isoformat(),
        }
        self.notes.append(note)
        self.save()

    def add_journal_entry(self, content, mood=None):
        today = datetime.now().strftime('%Y-%m-%d')
        title = f"Journal — {today}"
        tags = ['journal']
        if mood:
            tags.append(f'mood:{mood}')
        self.add_note(title, content, tags=tags, is_journal=True)

    def view_notes(self, journals_only=False):
        notes = self.notes if not journals_only else [n for n in self.notes if n.get('is_journal')]
        return list(reversed(notes))

    def search_notes(self, keyword):
        kw = keyword.lower()
        return [
            n for n in self.notes
            if kw in n['title'].lower()
            or kw in n['content'].lower()
            or any(kw in t.lower() for t in n.get('tags', []))
        ]

    def delete_note(self, index):
        if 0 <= index < len(self.notes):
            self.notes.pop(index)
            self.save()
            return True
        return False

    def latest_journal(self):
        journals = [n for n in self.notes if n.get('is_journal')]
        return journals[-1] if journals else None
