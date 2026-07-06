#!/usr/bin/env python3
"""Convert MinerU parse output into the paper-studio OCR contract.

Usage: mineru_to_paper_md.py <parse-dir> <ocr-dir>

<parse-dir> is the MinerU output directory containing *_content_list.json
and images/ (e.g. <out>/<pdf-stem>/auto/). Writes:

    <ocr-dir>/paper.md               one [pNN] anchor line per PDF page
    <ocr-dir>/figures/fig-NN.ext     figures, named by their paper number
    <ocr-dir>/figures/table-NN.ext   tables, named by their paper number
    <ocr-dir>/figures.md             metadata index: label, file, page, caption

Figures/tables are named by their reference number in the paper (Fig. 3
-> fig-03.jpg, Table 1 -> table-01.jpg), NOT by page — the page is
recovered from figures.md instead. The number is parsed from the block's
caption ("Fig. N" / "Table N"); a figure whose caption MinerU dropped
(some raster `image` blocks) inherits the previous figure number + 1,
which reconstructs it correctly because the captioned figures pin the
sequence. figures.md lists every extracted image with its label, page
anchor, and caption so downstream steps can map a file back to its page.

A figure/table block MinerU located but could not recognize (no cropped
image AND no HTML body — its recognizer failed) is not silently dropped:
it is recorded in a "⚠ Not extracted" section of figures.md (with its
reserved filename, page, kind, and approximate bbox) for the skill's
Finalize step to recover by rendering the page and cropping. Its number is
still reserved so later figures/tables keep their correct numbers.

Block schema handled (MinerU 2.x content_list): each block has a `type`
(text / image / chart / table / equation), a 0-based `page_idx`, and
type-specific fields (`text`, `text_level`, `img_path`, `img_caption`,
`img_footnote`, `chart_caption`, `chart_footnote`, `content`,
`table_caption`, `table_footnote`, `table_body`). `chart` is a raster
figure MinerU recognized as a plot — extracted like `image` but with
`chart_*` caption fields. `table` is imported as its cropped image
(preserving the original visual form), falling back to the HTML
`table_body` only when no image crop exists. A `table`-typed block whose
caption starts with "Fig" is really a figure (MinerU misclassifies
matrix-shaped figures) and is numbered in the figure sequence. Unknown
block types degrade to their `text` field. If MinerU changes this schema,
adjust here — the raw JSON in <parse-dir> is the source of truth.

Stdlib only; no third-party imports. Compatible with Python 3.8+ (macOS
system python3 is often 3.9 — do not use runtime-evaluated new-style
annotations here).
"""

from __future__ import annotations

import json
import re
import shutil
import sys
from pathlib import Path


NUM_RE = re.compile(r"(?i)\b(?:fig(?:ure)?|table)\.?\s*(\d+)")


def page_anchor(page_idx: int) -> str:
    return f"[p{page_idx + 1:02d}]"


def joined(value) -> str:
    """MinerU caption/footnote fields are lists of strings (or absent)."""
    if isinstance(value, list):
        return " ".join(s.strip() for s in value if s and s.strip())
    return (value or "").strip() if isinstance(value, str) else ""


def caption_number(caption: str):
    """Parse the leading 'Fig. N' / 'Table N' number, or None."""
    m = NUM_RE.match(caption.lstrip())
    return int(m.group(1)) if m else None


def figure_kind(btype: str, caption: str) -> str:
    """'figure' or 'table' — caption prefix wins (MinerU misclassifies some
    matrix-shaped figures as tables), else fall back to the block type."""
    c = caption.lstrip()
    if re.match(r"(?i)table\b", c):
        return "table"
    if re.match(r"(?i)fig", c):
        return "figure"
    return "table" if btype == "table" else "figure"


class FigureStore:
    def __init__(self, parse_dir: Path, figures_dir: Path):
        self.parse_dir = parse_dir
        self.figures_dir = figures_dir
        self.fig_n = 0
        self.table_n = 0
        self.copied = 0
        # metadata rows: {"label", "file", "page", "caption"}
        self.records: list[dict] = []
        # blocks MinerU detected but could not extract (no image + no body);
        # surfaced for Finalize to recover: {"label","file","page","kind","bbox","caption"}
        self.missing: list[dict] = []

    def next_label(self, kind: str, caption: str):
        """Return (label, stem) for the next figure/table, numbering by the
        caption's own number when present, else previous + 1. Called once per
        image/chart/table block so numbers stay stable whether or not the
        block's image could be extracted."""
        num = caption_number(caption)
        if kind == "table":
            num = num if num is not None else self.table_n + 1
            self.table_n = max(self.table_n, num)
            return f"Table {num}", f"table-{num:02d}"
        num = num if num is not None else self.fig_n + 1
        self.fig_n = max(self.fig_n, num)
        return f"Fig. {num}", f"fig-{num:02d}"

    def copy_image(self, stem: str, label: str, page_idx: int,
                   img_path: str, caption: str):
        """Copy the cropped image into figures/ as <stem>.<ext>; record its
        metadata. Return the paper.md-relative ref, or None if no crop exists."""
        src = self.parse_dir / img_path
        if not img_path or not src.is_file():
            return None
        ext = src.suffix.lstrip(".") or "png"
        name = f"{stem}.{ext}"
        dst = self.figures_dir / name
        # Guard against a number reused by two blocks (rare): suffix -b, -c...
        suffix = ord("b")
        while dst.exists():
            name = f"{stem}-{chr(suffix)}.{ext}"
            dst = self.figures_dir / name
            suffix += 1
        self.figures_dir.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(src, dst)
        self.copied += 1
        self.records.append({
            "label": label,
            "file": f"figures/{name}",
            "page": page_anchor(page_idx),
            "caption": caption,
        })
        return f"figures/{name}"

    def record_missing(self, stem: str, label: str, kind: str,
                       page_idx: int, bbox, caption: str) -> None:
        """A figure/table MinerU located (it has a block) but failed to
        recognize — no cropped image and no HTML body. Record it so Finalize
        can recover it by rendering the page and cropping by bbox."""
        self.missing.append({
            "label": label,
            "file": f"figures/{stem}.jpg",
            "page": page_anchor(page_idx),
            "kind": kind,
            "bbox": bbox,
            "caption": caption,
        })


def render_block(block: dict, figures: FigureStore) -> str:
    btype = block.get("type")
    page_idx = block.get("page_idx", 0)
    text = (block.get("text") or "").strip()

    if btype == "text":
        level = block.get("text_level")
        if level and text:
            return "#" * min(int(level), 6) + " " + text
        return text

    if btype == "equation":
        if text and not text.startswith("$$"):
            return f"$$\n{text}\n$$"
        return text

    if btype in ("image", "chart", "table"):
        # image  -> raster figure; chart -> a plot MinerU recognized;
        # table  -> imported as its cropped image (HTML body only as a
        #           fallback when no crop exists). All are numbered by their
        #           paper reference number and indexed in figures.md.
        if btype == "image":
            caption = joined(block.get("img_caption"))
            foot = joined(block.get("img_footnote"))
        elif btype == "chart":
            caption = joined(block.get("chart_caption"))
            foot = joined(block.get("chart_footnote"))
        else:
            caption = joined(block.get("table_caption"))
            foot = joined(block.get("table_footnote"))

        kind = figure_kind(btype, caption)
        label, stem = figures.next_label(kind, caption)
        body = (block.get("table_body") or "").strip() if btype == "table" else ""
        parts = []
        ref = figures.copy_image(stem, label, page_idx,
                                 block.get("img_path") or "", caption)
        if ref:
            parts.append(f"![{caption or label}]({ref})")
            # Keep the label visible in the text even when MinerU dropped the
            # descriptive caption, so the figure number survives in paper.md.
            parts.append(caption if caption else label)
        elif body:
            # Table with no crop — fall back to the structured HTML so it is
            # never lost.
            if caption:
                parts.append(caption)
            parts.append(body)
        else:
            # MinerU located a figure/table region but produced neither a crop
            # nor a body (recognition failed). Surface it for Finalize recovery
            # instead of dropping it silently.
            figures.record_missing(stem, label, kind, page_idx,
                                   block.get("bbox"), caption)
            parts.append(
                f"> ⚠ {label}: MinerU could not extract this {kind}. "
                f"Recover at Finalize — see `ocr/figures.md`."
            )
            if caption:
                parts.append(caption)

        content = (block.get("content") or "").strip()
        if content:
            parts.append(content)
        if foot:
            parts.append(foot)
        return "\n\n".join(p for p in parts if p)

    return text  # unknown block type: keep whatever text it carries


def write_metadata(out_dir: Path, records: list, missing: list) -> None:
    lines = [
        "# Figure & table metadata",
        "",
        "Each extracted image in `figures/`, its paper reference number, the "
        "PDF page it came from, and its caption. Filenames encode the "
        "reference number (`fig-03.jpg` = Fig. 3); this table recovers the "
        "page a filename no longer carries.",
        "",
        "| Label | File | Page | Caption |",
        "| --- | --- | --- | --- |",
    ]
    for r in records:
        cap = (r["caption"] or "(caption未抽出)").replace("|", "\\|").replace("\n", " ")
        lines.append(f"| {r['label']} | {r['file']} | {r['page']} | {cap} |")

    if missing:
        lines += [
            "",
            "## ⚠ Not extracted — recover at Finalize",
            "",
            "MinerU located these figure/table regions but its recognizer "
            "produced no image and no HTML, so nothing could be written. "
            "Per the skill's Finalize step, render each page with `pdftoppm` "
            "and crop the region (the `bbox` is a hint in MinerU's own "
            "coordinate space — render the whole page and crop by eye if it "
            "doesn't line up), verify it visually, save it to the intended "
            "file, then move its row up into the table above. Drop the row "
            "instead if the region is a phantom (no real figure/table there).",
            "",
            "| Intended file | Page | Kind | bbox (approx) | Caption |",
            "| --- | --- | --- | --- | --- |",
        ]
        for m in missing:
            cap = (m["caption"] or "(caption未抽出)").replace("|", "\\|").replace("\n", " ")
            bbox = ",".join(str(x) for x in m["bbox"]) if m.get("bbox") else "unknown"
            lines.append(
                f"| {m['file']} | {m['page']} | {m['kind']} | [{bbox}] | {cap} |"
            )
    (out_dir / "figures.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    if len(sys.argv) != 3:
        print(f"usage: {sys.argv[0]} <parse-dir> <ocr-dir>", file=sys.stderr)
        return 2

    parse_dir = Path(sys.argv[1])
    out_dir = Path(sys.argv[2])

    candidates = sorted(parse_dir.glob("*_content_list.json"))
    if not candidates:
        print(f"error: no *_content_list.json in {parse_dir}", file=sys.stderr)
        return 1
    blocks = json.loads(candidates[0].read_text(encoding="utf-8"))
    if not isinstance(blocks, list):
        print(f"error: {candidates[0]} is not a JSON array", file=sys.stderr)
        return 1

    figures = FigureStore(parse_dir, out_dir / "figures")
    chunks: list[str] = []
    current_page = None
    for block in blocks:
        page_idx = block.get("page_idx", 0)
        if page_idx != current_page:
            current_page = page_idx
            chunks.append(page_anchor(page_idx))
        rendered = render_block(block, figures)
        if rendered:
            chunks.append(rendered)

    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "paper.md").write_text(
        "\n\n".join(chunks) + "\n", encoding="utf-8"
    )
    write_metadata(out_dir, figures.records, figures.missing)

    pages = (current_page + 1) if current_page is not None else 0
    miss = len(figures.missing)
    print(
        f"OCR complete: {pages} page(s) -> {out_dir / 'paper.md'}, "
        f"{figures.copied} figure(s) -> {out_dir / 'figures'}/, "
        f"metadata -> {out_dir / 'figures.md'}"
        + (f"; ⚠ {miss} figure/table(s) MinerU could not extract — "
           f"listed in figures.md for Finalize recovery" if miss else "")
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
