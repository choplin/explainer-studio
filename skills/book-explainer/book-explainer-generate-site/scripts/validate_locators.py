#!/usr/bin/env python3
"""Validate EPUB source-locator spans before reading-site generation."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

SPAN_RE = re.compile(r"\]\{(?P<attrs>[^{}]*\.source-locator[^{}]*)\}")
LOCATOR_RE = re.compile(r'\bdata-locator="(?P<locator>[^"]+)"')
INLINE_CODE_RE = re.compile(r"`[^`]*`")


def prose_without_code(source: str) -> str:
    """Remove fenced and inline code while retaining approximate line positions."""
    lines: list[str] = []
    fenced = False
    fence_marker = ""
    for line in source.splitlines():
        stripped = line.lstrip()
        if not fenced and stripped.startswith(("```", "~~~")):
            fenced = True
            fence_marker = stripped[:3]
            lines.append("")
            continue
        if fenced:
            if stripped.startswith(fence_marker):
                fenced = False
            lines.append("")
            continue
        lines.append(INLINE_CODE_RE.sub("", line))
    return "\n".join(lines)


def validate_source(path: Path, valid_locators: set[str]) -> list[str]:
    """Return source-locator contract violations for one Markdown file."""
    prose = prose_without_code(path.read_text(encoding="utf-8"))
    errors: list[str] = []
    for match in SPAN_RE.finditer(prose):
        locator_match = LOCATOR_RE.search(match.group("attrs"))
        line = prose.count("\n", 0, match.start()) + 1
        if locator_match is None:
            errors.append(f"{path}:{line}: source-locator has no data-locator")
            continue
        locator = locator_match.group("locator")
        if locator not in valid_locators:
            errors.append(f"{path}:{line}: unknown EPUB locator: {locator}")
    for match in re.finditer(r"\{\.p\}", prose):
        line = prose.count("\n", 0, match.start()) + 1
        errors.append(f"{path}:{line}: EPUB source contains a PDF .p locator")
    return errors


def parser() -> argparse.ArgumentParser:
    """Build the CLI parser."""
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument("locator_map", type=Path)
    result.add_argument("sources", nargs="+", type=Path)
    return result


def main() -> int:
    """CLI entry point."""
    args = parser().parse_args()
    try:
        locator_map = json.loads(args.locator_map.read_text(encoding="utf-8"))
        valid_locators = set(locator_map["valid_locators"])
    except (OSError, json.JSONDecodeError, KeyError, TypeError) as error:
        print(f"error: invalid EPUB locator map: {error}", file=sys.stderr)
        return 1

    errors: list[str] = []
    for source in args.sources:
        try:
            errors.extend(validate_source(source, valid_locators))
        except OSError as error:
            errors.append(f"{source}: cannot read source: {error}")
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print(f"EPUB locator validation passed for {len(args.sources)} source(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
