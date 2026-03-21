import json
import os
from datetime import datetime


DATA_FILE = os.path.join(os.path.dirname(__file__), '..', 'data', 'budget.json')
CATEGORIES = ['Food', 'Entertainment', 'Transport', 'Health', 'Bills', 'General']


class Budget:
    def __init__(self, starting_amount=0.0):
        self.starting_amount = starting_amount
        self.income = []
        self.expenses = []
        self.history = []
        self.load()

    def load(self):
        if os.path.exists(DATA_FILE):
            with open(DATA_FILE, 'r') as f:
                data = json.load(f)
            self.starting_amount = data.get('starting_amount', self.starting_amount)
            self.income = data.get('income', [])
            self.expenses = data.get('expenses', [])
            self.history = data.get('history', [])

    def save(self):
        os.makedirs(os.path.dirname(DATA_FILE), exist_ok=True)
        with open(DATA_FILE, 'w') as f:
            json.dump({
                'starting_amount': self.starting_amount,
                'income': self.income,
                'expenses': self.expenses,
                'history': self.history,
            }, f, indent=2)

    def add_income(self, amount, source):
        entry = {
            'amount': float(amount),
            'source': source,
            'date': datetime.now().isoformat(),
        }
        self.income.append(entry)
        self.history.append({'type': 'income', **entry})
        self.save()

    def add_expense(self, name, amount, category='General'):
        if category not in CATEGORIES:
            category = 'General'
        entry = {
            'name': name,
            'amount': float(amount),
            'category': category,
            'date': datetime.now().isoformat(),
        }
        self.expenses.append(entry)
        self.history.append({'type': 'expense', **entry})
        self.save()

    def update_expense(self, index, new_amount):
        if 0 <= index < len(self.expenses):
            self.expenses[index]['amount'] = float(new_amount)
            self.save()
            return True
        return False

    def delete_expense(self, index):
        if 0 <= index < len(self.expenses):
            removed = self.expenses.pop(index)
            self.history.append({'type': 'deleted_expense', **removed, 'deleted_at': datetime.now().isoformat()})
            self.save()
            return True
        return False

    def total_income(self):
        return self.starting_amount + sum(e['amount'] for e in self.income)

    def total_expenses(self):
        return sum(e['amount'] for e in self.expenses)

    def balance(self):
        return self.total_income() - self.total_expenses()

    def savings(self):
        return self.balance()

    def expenses_by_category(self):
        cats = {c: 0.0 for c in CATEGORIES}
        for e in self.expenses:
            cats[e.get('category', 'General')] += e['amount']
        return cats

    def monthly_summary(self, year=None, month=None):
        now = datetime.now()
        year = year or now.year
        month = month or now.month
        monthly_income = [
            e for e in self.income
            if datetime.fromisoformat(e['date']).year == year
            and datetime.fromisoformat(e['date']).month == month
        ]
        monthly_expenses = [
            e for e in self.expenses
            if datetime.fromisoformat(e['date']).year == year
            and datetime.fromisoformat(e['date']).month == month
        ]
        total_in = sum(e['amount'] for e in monthly_income)
        total_out = sum(e['amount'] for e in monthly_expenses)
        return {
            'year': year,
            'month': month,
            'income': total_in,
            'expenses': total_out,
            'net': total_in - total_out,
            'income_items': monthly_income,
            'expense_items': monthly_expenses,
        }

    def view_budget(self):
        return {
            'starting_amount': self.starting_amount,
            'total_income': self.total_income(),
            'total_expenses': self.total_expenses(),
            'balance': self.balance(),
            'income': self.income,
            'expenses': self.expenses,
            'by_category': self.expenses_by_category(),
        }
