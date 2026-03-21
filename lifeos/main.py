#!/usr/bin/env python3
"""
LifeOS — Your Personal Command Center
Run with: python main.py
"""
import sys
import os

# Ensure the lifeos directory is on the path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from rich.console import Console
from rich.panel import Panel
from rich.prompt import Prompt

from backend.budget import Budget
from backend.goals import GoalTracker
from backend.schedule import Schedule
from backend.health import HealthOS
from backend.notes import NotesOS
from ui.dashboard import show_dashboard
from ui.budget_ui import show_budget_menu
from ui.goals_ui import show_goals_menu
from ui.schedule_ui import show_schedule_menu
from ui.health_ui import show_health_menu
from ui.notes_ui import show_notes_menu

console = Console()


def main_menu():
    # Initialise all modules (they auto-load from JSON on construction)
    budget = Budget(starting_amount=1000.0)
    goals = GoalTracker()
    schedule = Schedule()
    health = HealthOS()
    notes = NotesOS()

    while True:
        show_dashboard(budget, goals, schedule, health, notes)
        console.print(Panel(
            "  [bold cyan]0.[/bold cyan]  Refresh Dashboard\n"
            "  [bold cyan]1.[/bold cyan]  💰  BudgetOS  — Finance\n"
            "  [bold magenta]2.[/bold magenta]  🎯  GoalOS   — Goals & Aspirations\n"
            "  [bold blue]3.[/bold blue]  📅  ScheduleOS — Schedules & Routines\n"
            "  [bold green]4.[/bold green]  💪  HealthOS — Health & Wellness\n"
            "  [bold yellow]5.[/bold yellow]  📓  NotesOS  — Notes & Journal\n"
            "  [bold red]q.[/bold red]  Quit",
            title="[bold white]LIFEOS — Main Menu[/bold white]",
            border_style="white",
        ))
        choice = Prompt.ask(
            "[bold white]Navigate to[/bold white]",
            choices=["0", "1", "2", "3", "4", "5", "q"],
        )

        if choice == "q":
            console.print("[dim]Goodbye. Stay focused. 🚀[/dim]")
            break
        elif choice == "0":
            continue  # re-render dashboard
        elif choice == "1":
            show_budget_menu(budget)
        elif choice == "2":
            show_goals_menu(goals)
        elif choice == "3":
            show_schedule_menu(schedule)
        elif choice == "4":
            show_health_menu(health)
        elif choice == "5":
            show_notes_menu(notes)


if __name__ == "__main__":
    main_menu()
