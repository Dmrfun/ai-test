# LifeOS — Your Personal Command Center

A comprehensive personal life management CLI application built with Python and Rich. Manage your finances, goals, schedule, health, and journal from one sleek terminal interface.

## Features

| Module | Description |
|--------|-------------|
| 💰 **BudgetOS** | Track income, expenses by category, monthly summaries, savings |
| 🎯 **GoalOS** | Goals with priority levels, progress bars, overdue detection |
| 📅 **ScheduleOS** | Events, recurring schedules, reminders, weekly view |
| 💪 **HealthOS** | Habit streaks, sleep logs, exercise tracker, weekly summary |
| 📓 **NotesOS** | Notes with tags, daily journal with mood tracking, search |

## Setup

### Requirements
- Python 3.8+
- pip

### Install & Run

```bash
# Clone or download the repo, then:
pip install -r requirements.txt

# Option 1: Quick start with demo data
bash run.sh

# Option 2: Manual start
python lifeos/seed.py   # load demo data (optional)
python lifeos/main.py   # start the app
```

## Usage

The app launches with a **Dashboard** showing today's agenda, pending goals, budget balance, habit streaks, and your latest journal entry.

Navigate using numbered options in each menu. Press `0` to go back, `q` to quit.

### BudgetOS
- Set a starting balance
- Log income from any source
- Track expenses in 6 categories: Food, Entertainment, Transport, Health, Bills, General
- View monthly summaries and full transaction history

### GoalOS
- Add goals with due dates, priority (1–5), and category
- Track progress (0–100%) with visual progress bars
- Overdue goals are highlighted in red

### ScheduleOS
- Add one-time or recurring (daily/weekly) events
- Set optional reminder windows
- View today's agenda, a specific day, or full week

### HealthOS
- Log daily habits and see streak counts
- Record sleep hours and quality (1–5)
- Track exercise sessions by type and duration
- Weekly summary with averages

### NotesOS
- Create notes with titles, content, and comma-separated tags
- Write daily journal entries with mood tracking
- Full-text search across notes and tags
- View journal history separately

## File Structure

```
.
├── lifeos/
│   ├── main.py          # Entry point
│   ├── seed.py          # Demo data loader
│   ├── backend/
│   │   ├── budget.py
│   │   ├── goals.py
│   │   ├── schedule.py
│   │   ├── health.py
│   │   └── notes.py
│   ├── ui/
│   │   ├── dashboard.py
│   │   ├── budget_ui.py
│   │   ├── goals_ui.py
│   │   ├── schedule_ui.py
│   │   ├── health_ui.py
│   │   └── notes_ui.py
│   └── data/            # Auto-created JSON files
│       ├── budget.json
│       ├── goals.json
│       ├── schedule.json
│       ├── health.json
│       └── notes.json
├── requirements.txt
├── run.sh
└── README.md
```

## Data Persistence

All data is stored as JSON files in `lifeos/data/`. The app auto-loads on startup and auto-saves after every change. No external database required.
