import json
import os
from datetime import datetime, timedelta


DATA_FILE = os.path.join(os.path.dirname(__file__), '..', 'data', 'schedule.json')


class Schedule:
    def __init__(self):
        self.events = []
        self.load()

    def load(self):
        if os.path.exists(DATA_FILE):
            with open(DATA_FILE, 'r') as f:
                self.events = json.load(f)

    def save(self):
        os.makedirs(os.path.dirname(DATA_FILE), exist_ok=True)
        with open(DATA_FILE, 'w') as f:
            json.dump(self.events, f, indent=2)

    def add_event(self, title, date_str, time_str, priority=2, recurring=None, reminder_minutes=None):
        """
        priority: 1=low, 2=medium, 3=high
        recurring: None, 'daily', or 'weekly'
        """
        priority = max(1, min(3, int(priority)))
        event = {
            'title': title,
            'date': date_str,
            'time': time_str,
            'priority': priority,
            'recurring': recurring,
            'reminder_minutes': reminder_minutes,
            'created_at': datetime.now().isoformat(),
        }
        self.events.append(event)
        self._expand_recurring(event)
        self.save()

    def _expand_recurring(self, event):
        if not event.get('recurring'):
            return
        try:
            base_date = datetime.strptime(event['date'], '%Y-%m-%d')
        except ValueError:
            return
        end_date = datetime.now() + timedelta(days=30)
        delta = timedelta(days=1) if event['recurring'] == 'daily' else timedelta(weeks=1)
        current = base_date + delta
        while current <= end_date:
            date_str = current.strftime('%Y-%m-%d')
            duplicate = any(
                e['title'] == event['title'] and e['date'] == date_str and e['time'] == event['time']
                for e in self.events
            )
            if not duplicate:
                self.events.append({
                    'title': event['title'],
                    'date': date_str,
                    'time': event['time'],
                    'priority': event['priority'],
                    'recurring': event['recurring'],
                    'reminder_minutes': event.get('reminder_minutes'),
                    'created_at': datetime.now().isoformat(),
                    'is_recurring_instance': True,
                })
            current += delta

    def view_day(self, date_str):
        day_events = [e for e in self.events if e['date'] == date_str]
        return sorted(day_events, key=lambda e: e.get('time', ''))

    def view_week(self, start_date_str):
        try:
            start = datetime.strptime(start_date_str, '%Y-%m-%d')
        except ValueError:
            return []
        end = start + timedelta(days=6)
        week_events = [
            e for e in self.events
            if start <= datetime.strptime(e['date'], '%Y-%m-%d') <= end
        ]
        return sorted(week_events, key=lambda e: (e['date'], e.get('time', '')))

    def delete_event(self, date_str, index):
        day_events = [e for e in self.events if e['date'] == date_str]
        if 0 <= index < len(day_events):
            self.events.remove(day_events[index])
            self.save()
            return True
        return False

    def today_agenda(self):
        today = datetime.now().strftime('%Y-%m-%d')
        return self.view_day(today)

    def get_reminders(self):
        """Return events with reminders due in the next hour."""
        now = datetime.now()
        due = []
        for e in self.events:
            if e.get('reminder_minutes') is None:
                continue
            try:
                event_dt = datetime.strptime(f"{e['date']} {e['time']}", '%Y-%m-%d %H:%M')
                remind_at = event_dt - timedelta(minutes=e['reminder_minutes'])
                if now <= remind_at <= now + timedelta(hours=1):
                    due.append(e)
            except ValueError:
                pass
        return due
