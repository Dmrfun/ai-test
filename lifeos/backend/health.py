import json
import os
from datetime import datetime, timedelta
from collections import defaultdict


DATA_FILE = os.path.join(os.path.dirname(__file__), '..', 'data', 'health.json')


class HealthOS:
    def __init__(self):
        self.habits = []
        self.sleep_logs = []
        self.exercise_logs = []
        self.load()

    def load(self):
        if os.path.exists(DATA_FILE):
            with open(DATA_FILE, 'r') as f:
                data = json.load(f)
            self.habits = data.get('habits', [])
            self.sleep_logs = data.get('sleep_logs', [])
            self.exercise_logs = data.get('exercise_logs', [])

    def save(self):
        os.makedirs(os.path.dirname(DATA_FILE), exist_ok=True)
        with open(DATA_FILE, 'w') as f:
            json.dump({
                'habits': self.habits,
                'sleep_logs': self.sleep_logs,
                'exercise_logs': self.exercise_logs,
            }, f, indent=2)

    def log_habit(self, name, completed, date=None):
        date = date or datetime.now().strftime('%Y-%m-%d')
        self.habits.append({
            'name': name,
            'completed': bool(completed),
            'date': date,
            'logged_at': datetime.now().isoformat(),
        })
        self.save()

    def log_sleep(self, hours, quality, date=None):
        quality = max(1, min(5, int(quality)))
        date = date or datetime.now().strftime('%Y-%m-%d')
        self.sleep_logs.append({
            'hours': float(hours),
            'quality': quality,
            'date': date,
            'logged_at': datetime.now().isoformat(),
        })
        self.save()

    def log_exercise(self, exercise_type, duration_minutes, date=None):
        date = date or datetime.now().strftime('%Y-%m-%d')
        self.exercise_logs.append({
            'type': exercise_type,
            'duration_minutes': int(duration_minutes),
            'date': date,
            'logged_at': datetime.now().isoformat(),
        })
        self.save()

    def _habit_streak(self, name):
        completed_dates = sorted(
            {h['date'] for h in self.habits if h['name'] == name and h['completed']},
            reverse=True
        )
        if not completed_dates:
            return 0
        streak = 0
        check_date = datetime.now().date()
        for date_str in completed_dates:
            d = datetime.strptime(date_str, '%Y-%m-%d').date()
            if d == check_date or d == check_date - timedelta(days=streak):
                streak += 1
                check_date = d - timedelta(days=1) if streak > 1 else check_date
            else:
                break
        # Proper streak calculation
        streak = 0
        check = datetime.now().date()
        date_set = {datetime.strptime(d, '%Y-%m-%d').date() for d in completed_dates}
        while check in date_set:
            streak += 1
            check -= timedelta(days=1)
        return streak

    def view_habits(self):
        habit_names = list({h['name'] for h in self.habits})
        result = []
        for name in habit_names:
            logs = [h for h in self.habits if h['name'] == name]
            completed_today = any(
                h['date'] == datetime.now().strftime('%Y-%m-%d') and h['completed']
                for h in logs
            )
            streak = self._habit_streak(name)
            total = len(logs)
            done = sum(1 for h in logs if h['completed'])
            result.append({
                'name': name,
                'streak': streak,
                'completed_today': completed_today,
                'total_logs': total,
                'completion_rate': round(done / total * 100) if total else 0,
            })
        return result

    def weekly_summary(self, start_date=None):
        if start_date is None:
            today = datetime.now().date()
            start_date = today - timedelta(days=6)
        else:
            start_date = datetime.strptime(start_date, '%Y-%m-%d').date()
        end_date = start_date + timedelta(days=6)

        def in_range(date_str):
            d = datetime.strptime(date_str, '%Y-%m-%d').date()
            return start_date <= d <= end_date

        week_habits = [h for h in self.habits if in_range(h['date'])]
        week_sleep = [s for s in self.sleep_logs if in_range(s['date'])]
        week_exercise = [e for e in self.exercise_logs if in_range(e['date'])]

        avg_sleep = sum(s['hours'] for s in week_sleep) / len(week_sleep) if week_sleep else 0
        avg_quality = sum(s['quality'] for s in week_sleep) / len(week_sleep) if week_sleep else 0
        total_exercise_min = sum(e['duration_minutes'] for e in week_exercise)

        habit_completions = defaultdict(int)
        for h in week_habits:
            if h['completed']:
                habit_completions[h['name']] += 1

        return {
            'period': f"{start_date} to {end_date}",
            'avg_sleep_hours': round(avg_sleep, 1),
            'avg_sleep_quality': round(avg_quality, 1),
            'total_exercise_minutes': total_exercise_min,
            'exercise_sessions': len(week_exercise),
            'habit_completions': dict(habit_completions),
            'sleep_logs': week_sleep,
            'exercise_logs': week_exercise,
        }
