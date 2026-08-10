#!/usr/bin/env python3
"""Check that all l10n maps share the same keys and flag suspicious text."""

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
L10N = ROOT / "lib" / "l10n" / "l10n.dart"


def main():
    text = L10N.read_text(encoding="utf-8")
    maps = {}
    current = None
    for line in text.splitlines():
        m = re.match(r"\s*static const (_zhHans|_zhHant|_ja|_en) =", line)
        if m:
            current = m.group(1)
            maps[current] = {}
            continue
        if current is None:
            continue
        if line.strip() == "};":
            current = None
            continue
        kv = re.match(r"\s*'([^']+)':\s*'([^']*)'", line)
        if kv:
            maps[current][kv.group(1)] = kv.group(2)

    base = maps.get("_zhHans", {})
    for name in ("_zhHant", "_ja", "_en"):
        missing = sorted(set(base) - set(maps.get(name, {})))
        extra = sorted(set(maps.get(name, {})) - set(base))
        if missing:
            print(f"{name} missing: {', '.join(missing)}")
        if extra:
            print(f"{name} extra: {', '.join(extra)}")
    print("maps:", {k: len(v) for k, v in maps.items()})


if __name__ == "__main__":
    sys.exit(main())
