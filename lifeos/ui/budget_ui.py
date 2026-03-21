from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.prompt import Prompt, Confirm
from rich import box
from backend.budget import Budget, CATEGORIES

console = Console()


def show_budget_menu(budget: Budget):
    while True:
        console.print(Panel(
            "[bold cyan]BudgetOS[/bold cyan] — Finance Manager",
            border_style="cyan"
        ))
        console.print(
            "  [bold green]1.[/bold green] View Budget\n"
            "  [bold green]2.[/bold green] Add Income\n"
            "  [bold green]3.[/bold green] Add Expense\n"
            "  [bold green]4.[/bold green] Update Expense\n"
            "  [bold green]5.[/bold green] Delete Expense\n"
            "  [bold green]6.[/bold green] Monthly Summary\n"
            "  [bold green]7.[/bold green] Expense History\n"
            "  [bold red]0.[/bold red] Back to Main Menu\n"
        )
        choice = Prompt.ask("[bold yellow]Choose[/bold yellow]", choices=["0","1","2","3","4","5","6","7"])

        if choice == "0":
            break
        elif choice == "1":
            _view_budget(budget)
        elif choice == "2":
            _add_income(budget)
        elif choice == "3":
            _add_expense(budget)
        elif choice == "4":
            _update_expense(budget)
        elif choice == "5":
            _delete_expense(budget)
        elif choice == "6":
            _monthly_summary(budget)
        elif choice == "7":
            _expense_history(budget)


def _view_budget(budget: Budget):
    data = budget.view_budget()

    summary = Table(box=box.ROUNDED, border_style="cyan")
    summary.add_column("", style="bold")
    summary.add_column("Amount", justify="right", style="green")
    summary.add_row("Starting Amount", f"${data['starting_amount']:,.2f}")
    summary.add_row("Total Income", f"${data['total_income']:,.2f}")
    summary.add_row("Total Expenses", f"[red]${data['total_expenses']:,.2f}[/red]")
    balance_color = "green" if data['balance'] >= 0 else "red"
    summary.add_row("Balance", f"[{balance_color}]${data['balance']:,.2f}[/{balance_color}]")
    console.print(Panel(summary, title="[cyan]Budget Summary[/cyan]", border_style="cyan"))

    cat_table = Table(title="Expenses by Category", box=box.SIMPLE, border_style="dim")
    cat_table.add_column("Category", style="bold")
    cat_table.add_column("Amount", justify="right")
    for cat, amt in data['by_category'].items():
        if amt > 0:
            cat_table.add_row(cat, f"[red]${amt:,.2f}[/red]")
    console.print(cat_table)

    if data['expenses']:
        exp_table = Table(title="All Expenses", box=box.SIMPLE, border_style="dim")
        exp_table.add_column("#", style="dim")
        exp_table.add_column("Name")
        exp_table.add_column("Category")
        exp_table.add_column("Amount", justify="right")
        exp_table.add_column("Date")
        for i, e in enumerate(data['expenses']):
            exp_table.add_row(
                str(i), e['name'], e['category'],
                f"[red]${e['amount']:,.2f}[/red]",
                e['date'][:10]
            )
        console.print(exp_table)


def _add_income(budget: Budget):
    source = Prompt.ask("[cyan]Income source[/cyan]")
    amount_str = Prompt.ask("[cyan]Amount[/cyan]")
    try:
        amount = float(amount_str)
        budget.add_income(amount, source)
        console.print(f"[green]✓ Added income: ${amount:,.2f} from {source}[/green]")
    except ValueError:
        console.print("[red]Invalid amount.[/red]")


def _add_expense(budget: Budget):
    name = Prompt.ask("[cyan]Expense name[/cyan]")
    amount_str = Prompt.ask("[cyan]Amount[/cyan]")
    console.print("Categories: " + ", ".join(f"[{i+1}] {c}" for i, c in enumerate(CATEGORIES)))
    cat_choice = Prompt.ask("[cyan]Category number (or name)[/cyan]", default="6")
    try:
        idx = int(cat_choice) - 1
        category = CATEGORIES[idx] if 0 <= idx < len(CATEGORIES) else 'General'
    except ValueError:
        category = cat_choice if cat_choice in CATEGORIES else 'General'
    try:
        amount = float(amount_str)
        budget.add_expense(name, amount, category)
        console.print(f"[green]✓ Added expense: {name} ${amount:,.2f} ({category})[/green]")
    except ValueError:
        console.print("[red]Invalid amount.[/red]")


def _update_expense(budget: Budget):
    if not budget.expenses:
        console.print("[yellow]No expenses to update.[/yellow]")
        return
    _view_budget(budget)
    idx_str = Prompt.ask("[cyan]Expense index to update[/cyan]")
    new_amt_str = Prompt.ask("[cyan]New amount[/cyan]")
    try:
        idx = int(idx_str)
        new_amt = float(new_amt_str)
        if budget.update_expense(idx, new_amt):
            console.print(f"[green]✓ Updated expense #{idx} to ${new_amt:,.2f}[/green]")
        else:
            console.print("[red]Invalid index.[/red]")
    except ValueError:
        console.print("[red]Invalid input.[/red]")


def _delete_expense(budget: Budget):
    if not budget.expenses:
        console.print("[yellow]No expenses to delete.[/yellow]")
        return
    _view_budget(budget)
    idx_str = Prompt.ask("[cyan]Expense index to delete[/cyan]")
    try:
        idx = int(idx_str)
        if 0 <= idx < len(budget.expenses):
            name = budget.expenses[idx]['name']
            if Confirm.ask(f"[yellow]Delete expense '{name}'?[/yellow]"):
                budget.delete_expense(idx)
                console.print(f"[green]✓ Deleted expense: {name}[/green]")
        else:
            console.print("[red]Invalid index.[/red]")
    except ValueError:
        console.print("[red]Invalid input.[/red]")


def _monthly_summary(budget: Budget):
    from datetime import datetime
    now = datetime.now()
    year_str = Prompt.ask("[cyan]Year[/cyan]", default=str(now.year))
    month_str = Prompt.ask("[cyan]Month (1-12)[/cyan]", default=str(now.month))
    try:
        summary = budget.monthly_summary(int(year_str), int(month_str))
        t = Table(box=box.ROUNDED, border_style="cyan")
        t.add_column("", style="bold")
        t.add_column("Amount", justify="right")
        t.add_row("Income", f"[green]${summary['income']:,.2f}[/green]")
        t.add_row("Expenses", f"[red]${summary['expenses']:,.2f}[/red]")
        net_color = "green" if summary['net'] >= 0 else "red"
        t.add_row("Net", f"[{net_color}]${summary['net']:,.2f}[/{net_color}]")
        console.print(Panel(t, title=f"[cyan]{year_str}-{month_str:>02} Summary[/cyan]", border_style="cyan"))
    except ValueError:
        console.print("[red]Invalid date.[/red]")


def _expense_history(budget: Budget):
    if not budget.history:
        console.print("[yellow]No history yet.[/yellow]")
        return
    t = Table(title="Transaction History", box=box.SIMPLE, border_style="dim")
    t.add_column("Type")
    t.add_column("Description")
    t.add_column("Amount", justify="right")
    t.add_column("Date")
    for h in budget.history[-20:]:
        t_type = h.get('type', '')
        if t_type == 'income':
            t.add_row("[green]Income[/green]", h.get('source', ''), f"[green]+${h['amount']:,.2f}[/green]", h.get('date', '')[:10])
        elif t_type == 'expense':
            t.add_row("[red]Expense[/red]", h.get('name', ''), f"[red]-${h['amount']:,.2f}[/red]", h.get('date', '')[:10])
        elif t_type == 'deleted_expense':
            t.add_row("[dim]Deleted[/dim]", h.get('name', ''), f"[dim]${h['amount']:,.2f}[/dim]", h.get('deleted_at', '')[:10])
    console.print(t)
