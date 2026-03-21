from datetime import datetime, timedelta
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.prompt import Prompt, Confirm
from rich import box
from backend.schedule import Schedule

console = Console()

PRIORITY_COLORS = {1: "green", 2: "yellow", 3: "red"}
PRIORITY_LABELS = {1: "Low", 2: "Medium", 3: "High"}


def show_schedule_menu(schedule: Schedule):
    while True:
        console.print(Panel(
            "[bold blue]ScheduleOS[/bold blue] — Schedules & Routines",
            border_style="blue"
        ))
        console.print(
            "  [bold green]1.[/bold green] Today's Agenda\n"
            "  [bold green]2.[/bold green] View Day\n"
            "  [bold green]3.[/bold green] View Week\n"
            "  [bold green]4.[/bold green] Add Event\n"
            "  [bold green]5.[/bold green] Delete Event\n"
            "  [bold red]0.[/bold red] Back\n"
        )
        choice = Prompt.ask("[bold yellow]Choose[/bold yellow]", choices=["0","1","2","3","4","5"])

        if choice == "0":
            break
        elif choice == "1":
            _today_agenda(schedule)
        elif choice == "2":
            _view_day(schedule)
        elif choice == "3":
            _view_week(schedule)
        elif choice == "4":
            _add_event(schedule)
        elif choice == "5":
            _delete_event(schedule)


def _render_events(events, title="Events"):
    if not events:
        console.print(f"[yellow]No events for {title}.[/yellow]")
        return
    t = Table(title=title, box=box.ROUNDED, border_style="blue")
    t.add_column("#", style="dim", width=3)
    t.add_column("Time")
    t.add_column("Title", min_width=20)
    t.add_column("Date")
    t.add_column("Priority")
    t.add_column("Recurring")
    for i, e in enumerate(events):
        p = e.get('priority', 2)
        color = PRIORITY_COLORS.get(p, 'white')
        label = PRIORITY_LABELS.get(p, str(p))
        recurring = e.get('recurring') or ''
        t.add_row(
            str(i),
            e.get('time', ''),
            e.get('title', ''),
            e.get('date', ''),
            f"[{color}]{label}[/{color}]",
            f"[dim]{recurring}[/dim]",
        )
    console.print(t)


def _today_agenda(schedule: Schedule):
    today = datetime.now().strftime('%Y-%m-%d')
    events = schedule.today_agenda()
    _render_events(events, f"Today's Agenda ({today})")


def _view_day(schedule: Schedule):
    date_str = Prompt.ask("[blue]Date (YYYY-MM-DD)[/blue]", default=datetime.now().strftime('%Y-%m-%d'))
    events = schedule.view_day(date_str)
    _render_events(events, f"Schedule for {date_str}")


def _view_week(schedule: Schedule):
    today = datetime.now()
    monday = today - timedelta(days=today.weekday())
    default_start = monday.strftime('%Y-%m-%d')
    start_str = Prompt.ask("[blue]Week start date (YYYY-MM-DD)[/blue]", default=default_start)
    events = schedule.view_week(start_str)
    _render_events(events, f"Week starting {start_str}")


def _add_event(schedule: Schedule):
    title = Prompt.ask("[blue]Event title[/blue]")
    date_str = Prompt.ask("[blue]Date (YYYY-MM-DD)[/blue]", default=datetime.now().strftime('%Y-%m-%d'))
    time_str = Prompt.ask("[blue]Time (HH:MM)[/blue]", default="09:00")
    priority = Prompt.ask("[blue]Priority (1=Low, 2=Medium, 3=High)[/blue]", default="2",
                          choices=["1","2","3"])
    recurring = Prompt.ask("[blue]Recurring? (none/daily/weekly)[/blue]", default="none",
                           choices=["none","daily","weekly"])
    if recurring == "none":
        recurring = None
    reminder_str = Prompt.ask("[blue]Reminder (minutes before, or 0 for none)[/blue]", default="0")
    reminder = int(reminder_str) if reminder_str.isdigit() and int(reminder_str) > 0 else None
    schedule.add_event(title, date_str, time_str, int(priority), recurring, reminder)
    console.print(f"[green]✓ Event added: {title} on {date_str} at {time_str}[/green]")


def _delete_event(schedule: Schedule):
    date_str = Prompt.ask("[blue]Date (YYYY-MM-DD)[/blue]", default=datetime.now().strftime('%Y-%m-%d'))
    events = schedule.view_day(date_str)
    if not events:
        console.print(f"[yellow]No events on {date_str}.[/yellow]")
        return
    _render_events(events, f"Events on {date_str}")
    idx_str = Prompt.ask("[blue]Event index to delete[/blue]")
    try:
        idx = int(idx_str)
        if 0 <= idx < len(events):
            name = events[idx]['title']
            if Confirm.ask(f"[yellow]Delete event '{name}'?[/yellow]"):
                schedule.delete_event(date_str, idx)
                console.print(f"[green]✓ Deleted: {name}[/green]")
        else:
            console.print("[red]Invalid index.[/red]")
    except ValueError:
        console.print("[red]Invalid input.[/red]")
