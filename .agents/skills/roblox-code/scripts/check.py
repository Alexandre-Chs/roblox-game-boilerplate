#!/usr/bin/env python3
"""Run the house checks from the repository root."""
from pathlib import Path
import subprocess
raise SystemExit(subprocess.call(["node", "scripts/project.mjs", "check"], cwd=Path(__file__).resolve().parents[4]))
