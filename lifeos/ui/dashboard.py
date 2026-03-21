from datetime import datetime
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.columns import Columns
from rich.text import Text
from rich import box
from backend.budget import Budget
from backend.goals import GoalTracker
from backend.schedule import Schedule
from backend.health import HealthOS
from backend.notes import NotesOS

console = Console()

BANNER = r"""
  _      _  __       ___  ____
 | |    (_)/ _| ___ / _ \/ ___|
 | |    | | |_ / _ \ | | \___ \
 | |___ | |  _|  __/ |_| |___) |
 |_____|_|_|  \___|\___/|____/
"""


def show_dashboard(budget: Budget, goals: GoalTracker, schedule: Schedule,
                   health: HealthOS, notes: NotesOS):
    console.clear()
    console.print(f"[bold cyan]{BANNER}[/bold cyan]")
    console.print(f"[dim]  Your Personal Command Center  ·  {datetime.now().strftime('%A, %B %d %Y  %H:%M')}[/dim]\n")

    panels = []

    # --- Today's Agenda ---
    today_events = schedule.today_agenda()
    agenda_text = Text()
    if today_events:
        for e in today_events[:5]:
            p = e.get('priority', 2)
            color = {1: "green", 2: "yellow", 3: "red"}.get(p, "white")
            agenda_text.append(f"  {e.get('time','??:??')}  ", style="dim")
            agenda_text.append(f"{e['title']}\n", style=color)
        if len(today_events) > 5:
            agenda_text.append(f"  … +{len(today_events)-5} more\n", style="dim")
    else:
        agenda_text.append("  No events today\n", style="dim")
    panels.append(Panel(agenda_text, title="[blue]📅 Today's Agenda[/blue]", border_style="blue", width=38))

    # --- Goals ---
    pending = goals.pending_count()
    goal_list = goals.view_goals()
    goals_text = Text()
    goals_text.append(f"  {pending} pending goal(s)\n\n", style="yellow")
    urgent = [g for g in goal_list if not g['status'] == 'Done' and g['priority'] >= 4][:3]
    for g in urgent:
        color = "red" if g['status'] == 'Overdue' else "orange3"
        goals_text.append(f"  ★ {g['title'][:28]}\n", style=color)
    if not urgent:
        for g in [x for x in goal_list if x['status'] == 'Pending'][:3]:
            goals_text.append(f"  ○ {g['title'][:28]}\n", style="yellow")
    panels.append(Panel(goals_text, title="[magenta]🎯 Goals[/magenta]", border_style="magenta", width=38))

    # --- Budget ---
    balance = budget.balance()
    bal_color = "green" if balance >= 0 else "red"
    budget_text = Text()
    budget_text.append(f"  Balance: ", style="bold")
    budget_text.append(f"${balance:,.2f}\n", style=bal_color)
    budget_text.append(f"  Income:  ${budget.total_income():,.2f}\n", style="green")
    budget_text.append(f"  Spent:   ${budget.total_expenses():,.2f}\n", style="red")
    top_cats = sorted(budget.expenses_by_category().items(), key=lambda x: -x[1])[:3]
    if top_cats:
        budget_text.append("\n  Top categories:\n", style="dim")
        for cat, amt in top_cats:
            if amt > 0:
                budget_text.append(f"    {cat}: ${amt:,.2f}\n", style="dim")
    panels.append(Panel(budget_text, title="[cyan]💰 Budget[/cyan]", border_style="cyan", width=38))

    # --- Health ---
    habits = health.view_habits()
    health_text = Text()
    if habits:
        for h in habits[:4]:
            icon = "✓" if h['completed_today'] else "✗"
            streak_str = f" 🔥{h['streak']}d" if h['streak'] > 0 else ""
            color = "green" if h['completed_today'] else "red"
            health_text.append(f"  [{icon}] {h['name'][:22]}{streak_str}\n", style=color)
    else:
        health_text.append("  No habits tracked yet\n", style="dim")
    week = health.weekly_summary()
    health_text.append(f"\n  Avg sleep: {week['avg_sleep_hours']}h  |  Exercise: {week['total_exercise_minutes']}min\n", style="dim")
    panels.append(Panel(health_text, title="[green]💪 Health[/green]", border_style="green", width=38))

    console.print(Columns(panels, equal=False, expand=False))

    # --- Latest Journal ---
    latest = notes.latest_journal()
    if latest:
        preview = latest['content'][:120].replace('\n', ' ')
        console.print(Panel(
            f"[dim]{latest['date']}[/dim]\n{preview}{'…' if len(latest['content']) > 120 else ''}",
            title="[yellow]📓 Latest Journal Entry[/yellow]",
            border_style="yellow"
        ))
    console.print()
