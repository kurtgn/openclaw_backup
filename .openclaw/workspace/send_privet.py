#!/usr/bin/env python3
import json
import os
from pathlib import Path

STATE_FILE = Path('privet_state.json')
MAX_RUNS = 5

def load_state():
    if STATE_FILE.exists():
        try:
            data = json.loads(STATE_FILE.read_text())
            return data.get('count', 0)
        except Exception:
            return 0
    return 0

def save_state(count):
    STATE_FILE.write_text(json.dumps({'count': count}))

def main():
    count = load_state()
    if count >= MAX_RUNS:
        print('MAX_REACHED')
        return
    count += 1
    save_state(count)
    print('Понял.')
    if count >= MAX_RUNS:
        print('DELETE_CRON')

if __name__ == '__main__':
    main()
