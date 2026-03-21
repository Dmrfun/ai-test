from datetime import datetime
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.prompt import Prompt
from rich import box
from backend.health import HealthOS

console = Console()


def show_health_menu(health: HealthOS):
    while True:
        console.print(Panel(
            "[bold green]HealthOS[/bold green] — Health & Wellness",
            border_style="green"
        ))
        console.print(
            "  [bold green]1.[/bold green] Log Habit\n"
            "  [bold green]2.[/bold green] Log Sleep\n"
            "  [bold green]3.[/bold green] Log Exercise\n"
            "  [bold green]4.[/bold green] View Habits & Streaks\n"
            "  [bold green]5.[/bold green] Weekly Summary\n"
            "  [bold red]0.[/bold red] Back\n"
        )
        choice = Prompt.ask("[bold yellow]Choose[/bold yellow]", choices=["0","1","2","3","4","5"])

        if choice == "0":
            break
        elif choice == "1":
            _log_habit(health)
        elif choice == "2":
            _log_sleep(health)
        elif choice == "3":
            _log_exercise(health)
        elif choice == "4":
            _view_habits(health)
        elif choice == "5":
            _weekly_summary(health)


def _log_habit(health: HealthOS):
    name = Prompt.ask("[green]Habit name[/green]")
    done = Prompt.ask("[green]Completed? (y/n)[/green]", choices=["y","n","Y","N"])
    date = Prompt.ask("[green]Date (YYYY-MM-DD or enter for today)[/green]",
                      default=datetime.now().strftime('%Y-%m-%d'))
    health.log_habit(name, done.lower() == 'y', date)
    status = "[green]✓ completed[/green]" if done.lower() == 'y' else "[red]✗ missed[/red]"
    console.print(f"[green]Logged habit '{name}':[/green] {status}")


def _log_sleep(health: HealthOS):
    hours_str = Prompt.ask("[green]Hours of sleep[/green]")
    quality_str = Prompt.ask("[green]Quality (1-5)[/green]", choices=["1","2","3","4","5"])
    date = Prompt.ask("[green]Date (YYYY-MM-DD or enter for today)[/green]",
                      default=datetime.now().strftime('%Y-%m-%d'))
    try:
        health.log_sleep(float(hours_str), int(quality_str), date)
        console.print(f"[green]✓ Sleep logged: {hours_str}h, quality {quality_str}/5[/green]")
    except ValueError:
        console.print("[red]Invalid input.[/red]")


def _log_exercise(health: HealthOS):
    ex_type = Prompt.ask("[green]Exercise type[/green]")
    duration_str = Prompt.ask("[green]Duration (minutes)[/green]")
    date = Prompt.ask("[green]Date (YYYY-MM-DD or enter for today)[/green]",
                      default=datetime.now().strftime('%Y-%m-%d'))
    try:
        health.log_exercise(ex_type, int(duration_str), date)
        console.print(f"[green]✓ Exercise logged: {ex_type} for {duration_str} min[/green]")
    except ValueError:
        console.print("[red]Invalid input.[/red]")


def _view_habits(health: HealthOS):
    habits = health.view_habits()
    if not habits:
        console.print("[yellow]No habits tracked yet.[/yellow]")
        return
    t = Table(title="Habit Tracker", box=box.ROUNDED, border_style="green")
    t.add_column("Habit", min_width=20)
    t.add_column("Today", justify="center")
    t.add_column("Streak", justify="right")
    t.add_column("Completion Rate", justify="right")
    for h in habits:
        today_icon = "[green]✓[/green]" if h['completed_today'] else "[red]✗[/red]"
        streak_str = f"[yellow]🔥 {h['streak']}d[/yellow]" if h['streak'] > 0 else "0d"
        rate = h['completion_rate']
        rate_color = "green" if rate >= 80 else ("yellow" if rate >= 50 else "red")
        t.add_row(h['name'], today_icon, streak_str, f"[{rate_color}]{rate}%[/{rate_color}]")
    console.print(t)


def _weekly_summary(health: HealthOS):
    summary = health.weekly_summary()
    s = Table(box=box.ROUNDED, border_style="green")
    s.add_column("Metric", style="bold")
    s.add_column("Value", justify="right")
    s.add_row("Period", summary['period'])
    s.add_row("Avg Sleep", f"{summary['avg_sleep_hours']}h")
    s.add_row("Sleep Quality", f"{summary['avg_sleep_quality']}/5")
    s.add_row("Exercise Sessions", str(summary['exercise_sessions']))
    s.add_row("Total Exercise", f"{summary['total_exercise_minutes']} min")
    console.print(Panel(s, title="[green]Weekly Health Summary[/green]", border_style="green"))

    if summary['habit_completions']:
        ht = Table(title="Habit Completions This Week", box=box.SIMPLE)
        ht.add_column("Habit")
        ht.add_column("Days Completed", justify="right")
        for habit, count in summary['habit_completions'].items():
            ht.add_row(habit, str(count))
        console.print(ht)

    if summary['exercise_logs']:
        et = Table(title="Exercise Log", box=box.SIMPLE)
        et.add_column("Date")
        et.add_column("Type")
        et.add_column("Duration", justify="right")
        for e in summary['exercise_logs']:
            et.add_row(e['date'], e['type'], f"{e['duration_minutes']} min")
        console.print(et)
