#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Install dependencies if needed
pip install -q -r requirements.txt

# Seed demo data if data directory is empty
if [ ! -d "lifeos/data" ] || [ -z "$(ls -A lifeos/data 2>/dev/null)" ]; then
    echo "First run detected — loading demo data..."
    python lifeos/seed.py
fi

python lifeos/main.py
