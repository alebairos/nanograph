#!/usr/bin/env python3
import json
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile
import time

ROOT = pathlib.Path(__file__).resolve().parents[2]


def fail(msg: str) -> None:
    print(f"EVAL-SPRINT FAIL: {msg}", file=sys.stderr)
    sys.exit(1)


def run(cmd: list[str], check: bool = True) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, cwd=ROOT, check=check, text=True, capture_output=True)


def log(path: pathlib.Path, obj: dict) -> None:
    obj.setdefault("ts", time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()))
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a") as f:
        f.write(json.dumps(obj) + "\n")


def main() -> None:
    run(["make", "-C", "tools", "-s", "all"])

    task_log = ROOT / ".harness-data/agent-eval/task-a/run.jsonl"
    elf_log = ROOT / ".harness-data/agent-eval/elf-a/run.jsonl"
    task_log.write_text("")
    elf_log.write_text("")

    work = pathlib.Path(tempfile.mkdtemp())
    try:
        t0 = time.time()
        iter_count = 0
        tool_calls = 0

        def task_step(note: str) -> None:
            nonlocal iter_count, tool_calls
            iter_count += 1
            tool_calls += 1
            log(task_log, {"iter": iter_count, "task": "task-a", "tool_calls": tool_calls, "note": note})

        task_step("nano-probe disassemble fixtures/add_two.ngb")
        dis = run(["tools/bin/nano-probe", "disassemble", "fixtures/add_two.ngb"])
        if "mov eax, 1" not in dis.stdout or "add eax, 1" not in dis.stdout:
            fail("disassemble missing expected mnemonics")

        p1 = work / "p1.ngb"
        task_step("ngb-patch patch1 off=127 pair=01:02")
        run(["tools/bin/ngb-patch", "fixtures/add_two.ngb", str(p1),
             "--off", "127", "--pair", "01:02", "--patch-id", "1", "--timestamp", "1700000000"])
        p1_parse = run(["tools/bin/ngb-parse", "--json", str(p1)])
        if '"ok":true' not in p1_parse.stdout:
            fail(f"p1 parse failed: {p1_parse.stdout}")
        e1 = run(["./scripts/run-linux-elf.sh", str(p1)], check=False)
        if e1.returncode != 3:
            fail(f"p1 exit {e1.returncode} want 3")

        chain = work / "chain.ngb"
        task_step("ngb-patch patch2 off=121 pair=01:02 on p1")
        run(["tools/bin/ngb-patch", str(p1), str(chain),
             "--off", "121", "--pair", "01:02", "--patch-id", "2", "--timestamp", "1700000001"])
        chain_parse = run(["tools/bin/ngb-parse", "--json", str(chain)])
        if '"ok":true' not in chain_parse.stdout:
            fail(f"chain parse failed: {chain_parse.stdout}")
        e2 = run(["./scripts/run-linux-elf.sh", str(chain)], check=False)
        if e2.returncode != 4:
            fail(f"chain exit {e2.returncode} want 4")

        task_step("nano-probe audit-log chain")
        audit = run(["tools/bin/nano-probe", "audit-log", str(chain)])
        patch_lines = [ln for ln in audit.stdout.splitlines() if ln.startswith("patch ")]
        if len(patch_lines) != 2:
            fail(f"patch_count {len(patch_lines)} want 2")

        wall_ms = int((time.time() - t0) * 1000)
        log(task_log, {
            "task": "task-a",
            "success": True,
            "iterations": iter_count,
            "tool_calls": tool_calls,
            "wall_ms": wall_ms,
            "exit_code": 4,
            "patch_count": 2,
            "method": "disassemble+ngb-patch chain",
        })

        elf_t0 = time.time()
        elf_iter = 0
        elf_tools = 0

        def elf_step(note: str) -> None:
            nonlocal elf_iter, elf_tools
            elf_iter += 1
            elf_tools += 1
            log(elf_log, {"iter": elf_iter, "task": "elf-a", "tool_calls": elf_tools, "note": note})

        elf_bin = work / "elf.bin"
        shutil.copy(ROOT / "fixtures/add_two_elf.bin", elf_bin)
        data = bytearray(elf_bin.read_bytes())

        elf_step("scan for b8 01 00 00 00 in ELF")
        pat = bytes([0xB8, 0x01, 0x00, 0x00, 0x00])
        off_mov = data.find(pat)
        if off_mov < 0:
            fail("mov pattern not found")
        off_add = off_mov + 7

        elf_step(f"patch mov imm at {off_mov + 1} and add imm at {off_add}")
        data[off_mov + 1] = 0x02
        data[off_add] = 0x02
        elf_bin.write_bytes(data)

        elf_step("docker run patched ELF")
        with elf_bin.open("rb") as f:
            proc = subprocess.run(
                ["docker", "run", "--rm", "--platform", "linux/amd64", "-i", "ubuntu:24.04",
                 "sh", "-c", "cat > /tmp/e && chmod +x /tmp/e && /tmp/e"],
                stdin=f,
                capture_output=True,
            )
        if proc.returncode != 4:
            fail(f"elf exit {proc.returncode} want 4")

        elf_wall = int((time.time() - elf_t0) * 1000)
        log(elf_log, {
            "task": "elf-a",
            "success": True,
            "iterations": elf_iter,
            "tool_calls": elf_tools,
            "wall_ms": elf_wall,
            "exit_code": 4,
            "patches": [
                {"off": off_mov + 1, "old": "01", "new": "02", "field": "mov eax imm"},
                {"off": off_add, "old": "01", "new": "02", "field": "add eax imm"},
            ],
            "method": "hex scan + byte patch",
        })

        print(f"EVAL-SPRINT OK task-a iter={iter_count} wall_ms={wall_ms} elf-a iter={elf_iter} wall_ms={elf_wall}")
    finally:
        shutil.rmtree(work, ignore_errors=True)


if __name__ == "__main__":
    main()
