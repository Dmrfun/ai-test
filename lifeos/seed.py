#!/usr/bin/env python3
"""
Seed script — populates LifeOS with demo data.
Run with: python seed.py
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import json
import shutil
from datetime import datetime, timedelta

DATA_DIR = os.path.join(os.path.dirname(__file__), 'data')

def reset():
    if os.path.exists(DATA_DIR):
        shutil.rmtree(DATA_DIR)
    os.makedirs(DATA_DIR, exist_ok=True)
    print("Data directory reset.")

def seed_budget():
    from backend.budget import Budget
    b = Budget(starting_amount=3500.0)
    b.add_income(2500.0, "Monthly Salary")
    b.add_income(400.0, "Freelance Project")
    b.add_expense("Groceries", 180.0, "Food")
    b.add_expense("Netflix", 15.0, "Entertainment")
    b.add_expense("Bus Pass", 60.0, "Transport")
    b.add_expense("Gym Membership", 45.0, "Health")
    b.add_expense("Electricity Bill", 90.0, "Bills")
    b.add_expense("Dinner Out", 55.0, "Food")
    b.add_expense("Books", 35.0, "Entertainment")
    b.add_expense("Phone Bill", 40.0, "Bills")
    print("✓ Budget seeded")

def seed_goals():
    from backend.goals import GoalTracker
    g = GoalTracker()
    today = datetime.now().date()
    g.add_goal("Complete Python certification", str(today + timedelta(days=60)), priority=4, category="Career", progress=35)
    g.add_goal("Run a 5K race", str(today + timedelta(days=45)), priority=3, category="Health", progress=20)
    g.add_goal("Save $5,000 emergency fund", str(today + timedelta(days=180)), priority=5, category="Financial", progress=50)
    g.add_goal("Read 12 books this year", str(today + timedelta(days=270)), priority=2, category="Personal", progress=25)
    g.add_goal("Learn Spanish basics", str(today + timedelta(days=90)), priority=3, category="Personal", progress=10)
    g.add_goal("Get promoted to Senior Dev", str(today + timedelta(days=365)), priority=5, category="Career", progress=15)
    # Mark one as complete
    g.complete_goal(5)  # mark last as done for demo
    print("✓ Goals seeded")

def seed_schedule():
    from backend.schedule import Schedule
    s = Schedule()
    today = datetime.now().date()

    s.add_event("Morning Run", str(today), "07:00", priority=2, recurring="daily")
    s.add_event("Team Standup", str(today), "09:30", priority=3)
    s.add_event("Lunch Break", str(today), "12:30", priority=1)
    s.add_event("Code Review Session", str(today), "14:00", priority=3, reminder_minutes=15)
    s.add_event("Gym Session", str(today), "18:00", priority=2)

    tomorrow = today + timedelta(days=1)
    s.add_event("Doctor Appointment", str(tomorrow), "10:00", priority=3, reminder_minutes=60)
    s.add_event("Coffee with Mentor", str(tomorrow), "15:00", priority=2)

    next_week = today + timedelta(days=7)
    s.add_event("Monthly Review", str(next_week), "11:00", priority=3)
    s.add_event("Weekly Planning", str(today), "08:00", priority=2, recurring="weekly")
    print("✓ Schedule seeded")

def seed_health():
    from backend.health import HealthOS
    h = HealthOS()
    today = datetime.now().date()

    for i in range(7):
        d = str(today - timedelta(days=i))
        h.log_habit("Morning Run", i < 5, d)
        h.log_habit("Meditation", i < 6, d)
        h.log_habit("Read 30 min", i % 2 == 0, d)
        h.log_sleep(7.0 + (i % 2) * 0.5, 4 if i % 3 else 3, d)
        if i % 2 == 0:
            h.log_exercise("Running", 30, d)
        if i == 1:
            h.log_exercise("Yoga", 45, d)
        if i == 3:
            h.log_exercise("Cycling", 60, d)
    print("✓ Health seeded")

def seed_notes():
    from backend.notes import NotesOS
    n = NotesOS()

    n.add_note(
        "Python Tips",
        "1. Use list comprehensions for clean code.\n2. f-strings are faster than .format().\n3. dataclasses reduce boilerplate.",
        tags=["python", "programming", "tips"]
    )
    n.add_note(
        "Book Recommendations",
        "- Atomic Habits by James Clear\n- Deep Work by Cal Newport\n- The Pragmatic Programmer",
        tags=["books", "reading"]
    )
    n.add_note(
        "Project Ideas",
        "1. CLI task manager with sync\n2. Personal finance dashboard\n3. Habit tracker with streaks\n4. Recipe manager app",
        tags=["ideas", "projects"]
    )
    n.add_journal_entry(
        "Had a productive day. Finished the backend module for LifeOS and started the UI. "
        "Feeling good about progress. Need to remember to take breaks more often.",
        mood="happy"
    )
    n.add_journal_entry(
        "Struggled a bit with motivation today. Did manage to log my habits and get a workout in. "
        "Small wins count. Tomorrow I'll tackle the schedule module.",
        mood="neutral"
    )
    print("✓ Notes seeded")


if __name__ == "__main__":
    print("Seeding LifeOS with demo data...\n")
    reset()
    seed_budget()
    seed_goals()
    seed_schedule()
    seed_health()
    seed_notes()
    print("\n✅ All demo data loaded. Run 'python main.py' to start LifeOS!")
