from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.prompt import Prompt, Confirm
from rich.markdown import Markdown
from rich import box
from backend.notes import NotesOS

console = Console()


def show_notes_menu(notes: NotesOS):
    while True:
        console.print(Panel(
            "[bold yellow]NotesOS[/bold yellow] — Notes & Journal",
            border_style="yellow"
        ))
        console.print(
            "  [bold green]1.[/bold green] View Notes\n"
            "  [bold green]2.[/bold green] Add Note\n"
            "  [bold green]3.[/bold green] Add Journal Entry\n"
            "  [bold green]4.[/bold green] Search Notes\n"
            "  [bold green]5.[/bold green] View Journal\n"
            "  [bold green]6.[/bold green] Delete Note\n"
            "  [bold red]0.[/bold red] Back\n"
        )
        choice = Prompt.ask("[bold yellow]Choose[/bold yellow]", choices=["0","1","2","3","4","5","6"])

        if choice == "0":
            break
        elif choice == "1":
            _view_notes(notes)
        elif choice == "2":
            _add_note(notes)
        elif choice == "3":
            _add_journal(notes)
        elif choice == "4":
            _search_notes(notes)
        elif choice == "5":
            _view_journal(notes)
        elif choice == "6":
            _delete_note(notes)


def _render_notes_table(note_list, title="Notes"):
    if not note_list:
        console.print(f"[yellow]No {title.lower()} found.[/yellow]")
        return
    t = Table(title=title, box=box.ROUNDED, border_style="yellow", show_lines=True)
    t.add_column("#", style="dim", width=3)
    t.add_column("Title", min_width=20)
    t.add_column("Date")
    t.add_column("Tags")
    t.add_column("Preview", min_width=30)
    for i, n in enumerate(note_list):
        tags_str = ", ".join(n.get('tags', []))
        preview = n['content'][:60].replace('\n', ' ') + ('…' if len(n['content']) > 60 else '')
        icon = "📔" if n.get('is_journal') else "📝"
        t.add_row(str(i), f"{icon} {n['title']}", n.get('date', ''), f"[dim]{tags_str}[/dim]", preview)
    console.print(t)


def _view_notes(notes: NotesOS):
    all_notes = notes.view_notes()
    _render_notes_table(all_notes, "All Notes")
    if all_notes:
        idx_str = Prompt.ask("[yellow]Enter index to read (or Enter to skip)[/yellow]", default="")
        if idx_str.strip().isdigit():
            idx = int(idx_str)
            if 0 <= idx < len(all_notes):
                n = all_notes[idx]
                console.print(Panel(
                    f"[bold]{n['title']}[/bold]\n[dim]{n['date']}  |  tags: {', '.join(n.get('tags', []))}[/dim]\n\n{n['content']}",
                    border_style="yellow"
                ))


def _add_note(notes: NotesOS):
    title = Prompt.ask("[yellow]Note title[/yellow]")
    console.print("[dim]Enter content (type '.' on a new line to finish):[/dim]")
    lines = []
    while True:
        line = input()
        if line == '.':
            break
        lines.append(line)
    content = '\n'.join(lines)
    tags_str = Prompt.ask("[yellow]Tags (comma-separated, optional)[/yellow]", default="")
    notes.add_note(title, content, tags_str)
    console.print(f"[green]✓ Note added: {title}[/green]")


def _add_journal(notes: NotesOS):
    from datetime import datetime
    console.print(f"[yellow]Daily Journal Entry — {datetime.now().strftime('%Y-%m-%d')}[/yellow]")
    mood = Prompt.ask("[yellow]Mood (happy/neutral/sad/stressed/grateful/other)[/yellow]", default="neutral")
    console.print("[dim]Write your journal entry (type '.' on a new line to finish):[/dim]")
    lines = []
    while True:
        line = input()
        if line == '.':
            break
        lines.append(line)
    content = '\n'.join(lines)
    notes.add_journal_entry(content, mood)
    console.print("[green]✓ Journal entry saved.[/green]")


def _search_notes(notes: NotesOS):
    keyword = Prompt.ask("[yellow]Search keyword[/yellow]")
    results = notes.search_notes(keyword)
    _render_notes_table(results, f"Search Results for '{keyword}'")


def _view_journal(notes: NotesOS):
    journals = notes.view_notes(journals_only=True)
    _render_notes_table(journals, "Journal Entries")
    if journals:
        idx_str = Prompt.ask("[yellow]Enter index to read (or Enter to skip)[/yellow]", default="")
        if idx_str.strip().isdigit():
            idx = int(idx_str)
            if 0 <= idx < len(journals):
                n = journals[idx]
                console.print(Panel(
                    f"[bold]{n['title']}[/bold]\n[dim]{n['date']}  |  {', '.join(n.get('tags', []))}[/dim]\n\n{n['content']}",
                    border_style="yellow"
                ))


def _delete_note(notes: NotesOS):
    all_notes = notes.view_notes()
    _render_notes_table(all_notes, "All Notes")
    if not all_notes:
        return
    idx_str = Prompt.ask("[yellow]Note index to delete (actual list index)[/yellow]")
    try:
        display_idx = int(idx_str)
        if 0 <= display_idx < len(all_notes):
            n = all_notes[display_idx]
            actual_idx = notes.notes.index(n)
            if Confirm.ask(f"[red]Delete note '{n['title']}'?[/red]"):
                notes.delete_note(actual_idx)
                console.print(f"[green]✓ Deleted: {n['title']}[/green]")
        else:
            console.print("[red]Invalid index.[/red]")
    except (ValueError, ValueError):
        console.print("[red]Invalid input.[/red]")
