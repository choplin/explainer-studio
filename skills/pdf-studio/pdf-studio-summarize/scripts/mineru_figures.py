#!/usr/bin/env python3
"""Harvest figure/chart crops from a MinerU parse into the pdf-studio figure
contract. Unlike paper-studio's converter, this does NOT rebuild the body text
(pdf-studio's visual workers do that) and does NOT crop tables/console output
(those stay as text): it only pulls the genuine figures — diagrams, plots,
photos — that visual reading cannot capture, and indexes them by absolute PDF
page.

Usage: mineru_figures.py <parse-dir> <ocr-dir> <body-start-page>

  <parse-dir>        MinerU output dir holding *_middle.json and images/
  <ocr-dir>          where to write figures/ and figures.md
  <body-start-page>  1-based PDF page number that MinerU page_idx 0 maps to
                     (i.e. the `-s` start page passed to MinerU, +1 because
                     `-s` is 0-based; use 1 when MinerU ran over the whole PDF)

Design choices that differ from paper-studio (books, not papers):
  - Only `image`/`chart` blocks are cropped. `table` blocks (which in technical
    books are overwhelmingly code/console output, and whose cell layout the
    visual workers already transcribe as text) are left to the text stream.
  - Files are named by ABSOLUTE PDF page (`fig-p031-1.jpg`), not by a paper
    reference number. Page-based names are unique across chunks, need no global
    counter, and self-document their location — so this can run once over the
    whole PDF or per range without collisions.
  - Captions are taken from MinerU's own recognized caption text (no text-layer
    machinery); when a block carries several captions, the one that looks like a
    real "Figure X.Y"/"Table X.Y" caption is preferred over an in-figure label.

Stdlib only. Python 3.8+.
"""

from __future__ import annotations

import json
import re
import shutil
import sys
from pathlib import Path


# A book figure/table caption: "Figure 1.4", "Fig. 3", "Table 2.1" — the number
# may be chapter-scoped (1.4) or flat (3). Used both to pick the real caption
# among several and to derive a label.
CAP_RE = re.compile(r"(?i)\b(fig(?:ure)?|table)\.?\s*(\d+(?:\.\d+)*)")


def page_anchor(page: int) -> str:
    return f"[p{page:02d}]"


def caption_of(block: dict) -> str:
    """MinerU's recognized caption for an image/chart block. A block may carry
    several *_caption sub-blocks (an in-figure label plus the real caption); pick
    the one that reads as a figure/table caption, else the longest."""
    caps = []
    for sub in block.get("blocks", []):
        if str(sub.get("type", "")).endswith("_caption"):
            txt = "".join(
                sp.get("content", "")
                for ln in sub.get("lines", [])
                for sp in ln.get("spans", [])
            )
            txt = re.sub(r"</?su[bp]>", "", txt).strip()
            if txt:
                caps.append(txt)
    if not caps:
        return ""
    for c in caps:
        if CAP_RE.match(c.lstrip()):
            return c
    return max(caps, key=len)


def label_of(caption: str, page: int) -> str:
    """A short label for the figure. Prefer the caption's own "Figure X.Y"; fall
    back to the page it sits on when the caption has no reference number."""
    m = CAP_RE.match(caption.lstrip())
    if m:
        kind = "Figure" if m.group(1).lower().startswith("fig") else "Table"
        return f"{kind} {m.group(2)}"
    return f"Figure p{page:02d}"


def find_image_path(block: dict) -> str:
    """The crop path for an image/chart block (depth-first over its subtree)."""
    def walk(b):
        for ln in b.get("lines", []):
            for sp in ln.get("spans", []):
                if sp.get("type") in ("image", "chart") and sp.get("image_path"):
                    return sp["image_path"]
        for sub in b.get("blocks", []):
            hit = walk(sub)
            if hit:
                return hit
        return None

    return walk(block) or ""


def main() -> int:
    if len(sys.argv) != 4:
        print(f"usage: {sys.argv[0]} <parse-dir> <ocr-dir> <body-start-page>",
              file=sys.stderr)
        return 2
    parse_dir, out_dir = Path(sys.argv[1]), Path(sys.argv[2])
    try:
        start = int(sys.argv[3])
    except ValueError:
        print(f"error: body-start-page must be an integer, got {sys.argv[3]!r}",
              file=sys.stderr)
        return 2

    mids = sorted(parse_dir.glob("*_middle.json"))
    if not mids:
        print(f"error: no *_middle.json in {parse_dir}", file=sys.stderr)
        return 1
    m = json.loads(mids[0].read_text(encoding="utf-8"))

    figures_dir = out_dir / "figures"
    records, missing = [], []
    per_page = {}   # absolute page -> running index, for unique page-scoped names

    for pinfo in m["pdf_info"]:
        page = start + pinfo["page_idx"]
        for block in sorted(pinfo.get("para_blocks", []),
                            key=lambda b: b.get("index", 0)):
            if block.get("type") not in ("image", "chart"):
                continue          # tables / console output stay as text
            caption = caption_of(block)
            label = label_of(caption, page)
            per_page[page] = per_page.get(page, 0) + 1
            stem = f"fig-p{page:03d}-{per_page[page]}"
            image_path = find_image_path(block)
            src = (parse_dir / "images" / Path(image_path).name) if image_path else None
            if src and src.is_file():
                ext = src.suffix.lstrip(".") or "jpg"
                name = f"{stem}.{ext}"
                figures_dir.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(src, figures_dir / name)
                records.append({"label": label, "file": f"figures/{name}",
                                "page": page_anchor(page), "caption": caption})
            else:
                missing.append({"label": label, "file": f"figures/{stem}.jpg",
                                "page": page_anchor(page),
                                "bbox": block.get("bbox"), "caption": caption})

    write_metadata(out_dir, records, missing)
    print(f"figure harvest: {len(records)} figure(s) -> {figures_dir}/, "
          f"metadata -> {out_dir/'figures.md'}"
          + (f"; ⚠ {len(missing)} located but not cropped" if missing else ""))
    return 0


def write_metadata(out_dir: Path, records: list, missing: list) -> None:
    lines = [
        "# Figure metadata", "",
        "Each harvested figure in `figures/`, its label, the PDF page it came "
        "from, and MinerU's caption text. Filenames encode the PDF page "
        "(`fig-p031-1.jpg` = first figure on page 31). Tables and console "
        "output are intentionally NOT harvested as images — they live in the "
        "text extraction.", "",
        "| Label | File | Page | Caption |", "| --- | --- | --- | --- |",
    ]
    for r in records:
        cap = (r["caption"] or "(caption未抽出)").replace("|", "\\|").replace("\n", " ")
        lines.append(f"| {r['label']} | {r['file']} | {r['page']} | {cap} |")
    if missing:
        lines += ["", "## ⚠ Not extracted — recover at Finalize", "",
                  "MinerU located these figure regions but produced no crop. "
                  "Render the page with `pdftoppm` and crop the region, then "
                  "move its row up into the table above (or drop it if it is a "
                  "phantom).", "",
                  "| Intended file | Page | bbox (approx) | Caption |",
                  "| --- | --- | --- | --- |"]
        for m in missing:
            cap = (m["caption"] or "(caption未抽出)").replace("|", "\\|").replace("\n", " ")
            bbox = ",".join(str(x) for x in m["bbox"]) if m.get("bbox") else "unknown"
            lines.append(f"| {m['file']} | {m['page']} | [{bbox}] | {cap} |")
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "figures.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    sys.exit(main())
