#!/usr/bin/env python3
"""Check CI test selections against source and parse shell scripts without running them."""

from pathlib import Path
import re
import subprocess


ROOT = Path(__file__).resolve().parent.parent


def main():
    workflow = (ROOT / ".github/workflows/ci.yml").read_text()
    suites = {}
    for target in ("EasyKeyTests", "EasyKeyUITests"):
        for source in (ROOT / target).glob("*.swift"):
            contents = source.read_text()
            for suite in re.findall(r"\bclass\s+(\w+)\s*:\s*XCTestCase\b", contents):
                suites[f"{target}/{suite}"] = contents

    selections = re.findall(r"-(only|skip)-testing:([\w/]+)", workflow)
    selected_suites = set()
    errors = []
    for mode, selection in selections:
        parts = selection.split("/")
        suite = "/".join(parts[:2])
        if suite not in suites:
            errors.append(f"Unknown CI test suite: {selection}")
            continue
        if len(parts) > 2 and not re.search(r"\bfunc\s+" + re.escape(parts[2]) + r"\s*\(", suites[suite]):
            errors.append(f"Unknown CI test method: {selection}")
        if mode == "only" and len(parts) == 2:
            selected_suites.add(suite)

    for suite in sorted(suites.keys() - selected_suites):
        errors.append(f"Test suite has no complete CI shard assignment: {suite}")

    for script in sorted((ROOT / "Scripts").glob("*.sh")):
        interpreter = "zsh" if "zsh" in script.read_text().splitlines()[0] else "bash"
        result = subprocess.run([interpreter, "-n", str(script)], capture_output=True, text=True)
        if result.returncode:
            errors.append(f"Invalid shell syntax in {script.name}: {result.stderr.strip()}")

    if errors:
        raise SystemExit("\n".join(errors))
    print(f"CI configuration passed: {len(suites)} test suites assigned; shell syntax valid.")


if __name__ == "__main__":
    main()
