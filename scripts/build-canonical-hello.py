#!/usr/bin/env python3
"""Deprecated: use scripts/build-canonical-hello.sh (C hello-fixture)."""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sh = ROOT / "scripts" / "build-canonical-hello.sh"
sys.exit(subprocess.call([str(sh), *sys.argv[1:]]))
