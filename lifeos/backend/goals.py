import json
import os
from datetime import datetime


DATA_FILE = os.path.join(os.path.dirname(__file__), '..', 'data', 'goals.json')
CATEGORIES = ['Career', 'Health', 'Financial', 'Personal']


class GoalTracker:
    def __init__(self):
        self.goals = []
        self.load()

    def load(self):
        if os.path.exists(DATA_FILE):
            with open(DATA_FILE, 'r') as f:
                self.goals = json.load(f)

    def save(self):
        os.makedirs(os.path.dirname(DATA_FILE), exist_ok=True)
        with open(DATA_FILE, 'w') as f:
            json.dump(self.goals, f, indent=2)

    def add_goal(self, title, due_date, priority=3, category='Personal', progress=0):
        if category not in CATEGORIES:
            category = 'Personal'
        priority = max(1, min(5, int(priority)))
        progress = max(0, min(100, int(progress)))
        goal = {
            'title': title,
            'due_date': due_date,
            'completed': False,
            'priority': priority,
            'category': category,
            'progress': progress,
            'created_at': datetime.now().isoformat(),
            'completed_at': None,
        }
        self.goals.append(goal)
        self.save()

    def complete_goal(self, index):
        if 0 <= index < len(self.goals):
            self.goals[index]['completed'] = True
            self.goals[index]['progress'] = 100
            self.goals[index]['completed_at'] = datetime.now().isoformat()
            self.save()
            return True
        return False

    def update_progress(self, index, progress):
        if 0 <= index < len(self.goals):
            self.goals[index]['progress'] = max(0, min(100, int(progress)))
            if self.goals[index]['progress'] == 100:
                self.goals[index]['completed'] = True
                self.goals[index]['completed_at'] = datetime.now().isoformat()
            self.save()
            return True
        return False

    def delete_goal(self, index):
        if 0 <= index < len(self.goals):
            self.goals.pop(index)
            self.save()
            return True
        return False

    def is_overdue(self, goal):
        if goal['completed']:
            return False
        try:
            due = datetime.strptime(goal['due_date'], '%Y-%m-%d')
            return due.date() < datetime.now().date()
        except ValueError:
            return False

    def view_goals(self):
        result = []
        for i, g in enumerate(self.goals):
            result.append({
                'index': i,
                'title': g['title'],
                'due_date': g['due_date'],
                'status': 'Done' if g['completed'] else ('Overdue' if self.is_overdue(g) else 'Pending'),
                'priority': g['priority'],
                'category': g['category'],
                'progress': g['progress'],
                'completed_at': g.get('completed_at'),
            })
        return result

    def pending_count(self):
        return sum(1 for g in self.goals if not g['completed'])
