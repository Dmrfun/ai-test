from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.prompt import Prompt, Confirm
from rich.progress import BarColumn, Progress, TextColumn
from rich import box
from backend.goals import GoalTracker, CATEGORIES

console = Console()

PRIORITY_COLORS = {1: "green", 2: "cyan", 3: "yellow", 4: "orange3", 5: "red"}
PRIORITY_LABELS = {1: "Low", 2: "Normal", 3: "Medium", 4: "High", 5: "Critical"}


def show_goals_menu(tracker: GoalTracker):
    while True:
        console.print(Panel(
            "[bold magenta]GoalOS[/bold magenta] — Goals & Aspirations",
            border_style="magenta"
        ))
        console.print(
            "  [bold green]1.[/bold green] View Goals\n"
            "  [bold green]2.[/bold green] Add Goal\n"
            "  [bold green]3.[/bold green] Mark Complete\n"
            "  [bold green]4.[/bold green] Update Progress\n"
            "  [bold green]5.[/bold green] Delete Goal\n"
            "  [bold red]0.[/bold red] Back\n"
        )
        choice = Prompt.ask("[bold yellow]Choose[/bold yellow]", choices=["0","1","2","3","4","5"])

        if choice == "0":
            break
        elif choice == "1":
            _view_goals(tracker)
        elif choice == "2":
            _add_goal(tracker)
        elif choice == "3":
            _complete_goal(tracker)
        elif choice == "4":
            _update_progress(tracker)
        elif choice == "5":
            _delete_goal(tracker)


def _view_goals(tracker: GoalTracker):
    goals = tracker.view_goals()
    if not goals:
        console.print("[yellow]No goals yet. Add one![/yellow]")
        return

    t = Table(box=box.ROUNDED, border_style="magenta", show_lines=True)
    t.add_column("#", style="dim", width=3)
    t.add_column("Title", min_width=20)
    t.add_column("Category")
    t.add_column("Due Date")
    t.add_column("Priority")
    t.add_column("Progress", min_width=20)
    t.add_column("Status")

    for g in goals:
        p_color = PRIORITY_COLORS.get(g['priority'], 'white')
        p_label = PRIORITY_LABELS.get(g['priority'], str(g['priority']))
        progress_bar = _bar(g['progress'])
        if g['status'] == 'Done':
            status = "[green]✓ Done[/green]"
        elif g['status'] == 'Overdue':
            status = "[red]⚠ Overdue[/red]"
        else:
            status = "[yellow]○ Pending[/yellow]"

        t.add_row(
            str(g['index']),
            g['title'],
            g['category'],
            g['due_date'],
            f"[{p_color}]{p_label}[/{p_color}]",
            f"{progress_bar} {g['progress']}%",
            status,
        )
    console.print(t)


def _bar(pct, width=12):
    filled = int(width * pct / 100)
    color = "green" if pct == 100 else ("yellow" if pct >= 50 else "red")
    return f"[{color}]{'█' * filled}{'░' * (width - filled)}[/{color}]"


def _add_goal(tracker: GoalTracker):
    title = Prompt.ask("[magenta]Goal title[/magenta]")
    due = Prompt.ask("[magenta]Due date (YYYY-MM-DD)[/magenta]")
    console.print("Categories: " + ", ".join(f"[{i+1}] {c}" for i, c in enumerate(CATEGORIES)))
    cat_choice = Prompt.ask("[magenta]Category number[/magenta]", default="4")
    try:
        idx = int(cat_choice) - 1
        category = CATEGORIES[idx] if 0 <= idx < len(CATEGORIES) else 'Personal'
    except ValueError:
        category = 'Personal'
    priority = Prompt.ask("[magenta]Priority (1=Low, 5=Critical)[/magenta]", default="3",
                          choices=["1","2","3","4","5"])
    tracker.add_goal(title, due, int(priority), category)
    console.print(f"[green]✓ Goal added: {title}[/green]")


def _complete_goal(tracker: GoalTracker):
    _view_goals(tracker)
    idx_str = Prompt.ask("[magenta]Goal index to mark complete[/magenta]")
    try:
        idx = int(idx_str)
        if tracker.complete_goal(idx):
            console.print(f"[green]✓ Goal #{idx} marked complete![/green]")
        else:
            console.print("[red]Invalid index.[/red]")
    except ValueError:
        console.print("[red]Invalid input.[/red]")


def _update_progress(tracker: GoalTracker):
    _view_goals(tracker)
    idx_str = Prompt.ask("[magenta]Goal index[/magenta]")
    pct_str = Prompt.ask("[magenta]Progress % (0-100)[/magenta]")
    try:
        idx = int(idx_str)
        pct = int(pct_str)
        if tracker.update_progress(idx, pct):
            console.print(f"[green]✓ Progress updated to {pct}%[/green]")
        else:
            console.print("[red]Invalid index.[/red]")
    except ValueError:
        console.print("[red]Invalid input.[/red]")


def _delete_goal(tracker: GoalTracker):
    _view_goals(tracker)
    idx_str = Prompt.ask("[magenta]Goal index to delete[/magenta]")
    try:
        idx = int(idx_str)
        if 0 <= idx < len(tracker.goals):
            name = tracker.goals[idx]['title']
            if Confirm.ask(f"[yellow]Delete goal '{name}'?[/yellow]"):
                tracker.delete_goal(idx)
                console.print(f"[green]✓ Deleted: {name}[/green]")
        else:
            console.print("[red]Invalid index.[/red]")
    except ValueError:
        console.print("[red]Invalid input.[/red]")
