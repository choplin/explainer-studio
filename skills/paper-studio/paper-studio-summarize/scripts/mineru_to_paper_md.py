#!/usr/bin/env python3
"""Convert MinerU parse output into the paper-studio OCR contract, sourcing body
text from the PDF's own text layer (maximal fidelity) instead of MinerU's OCR.

Usage: mineru_to_paper_md.py <parse-dir> <ocr-dir> <pdf-path>

MinerU (run as `-b pipeline -m txt`) contributes only the *layout skeleton* —
block reading order, per-block/-span bounding boxes, block types, figure/table
crops, and formula LaTeX — via <parse-dir>/*_middle.json. The prose itself is
re-extracted from the PDF text layer (`pdftotext -bbox`) by matching each text
span's bbox to the text-layer words inside it. This avoids MinerU's OCR text
defects on this font class (ACM acmart / LinLibertine): dropped descenders,
collapsed ff/fi ligatures, and spurious <sub>/<sup> tagging. Inline-equation
spans keep MinerU's LaTeX; genuine subscripts therefore survive as `$..._{}$`.

Writes the same contract as the OCR-based converter:
    <ocr-dir>/paper.md               one [pNN] anchor line per PDF page
    <ocr-dir>/figures/fig-NN.ext     figures, named by paper reference number
    <ocr-dir>/figures/table-NN.ext   tables, named by paper reference number
    <ocr-dir>/figures.md             metadata index: label, file, page, caption

Stdlib only. Python 3.8+ (no runtime-evaluated new-style annotations).
"""

from __future__ import annotations

import html
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path


NUM_RE = re.compile(r"(?i)\b(?:fig(?:ure)?|table)\.?\s*(\d+)")
WORD_RE = re.compile(r'<word xMin="([\d.]+)" yMin="([\d.]+)" '
                     r'xMax="([\d.]+)" yMax="([\d.]+)">(.*?)</word>', re.S)
PAGE_RE = re.compile(r'<page width="([\d.]+)" height="([\d.]+)"')

# Footnote markers: a run of digits, or one of the classic footnote symbols
# (including their Unicode variants — papers commonly use U+2217 ∗ and U+204E ⁎
# rather than an ASCII `*`). Symbols are safe to accept alongside digits because
# MinerU's spurious `<sup>` tags on this font class are ligature/ascender
# *letters* (fi, ff, h, d, …), never these symbols. Non-digit *letters* stay
# excluded (indistinguishable from that ligature noise). Symbols are mapped to
# ASCII labels so the GFM footnote id is well-formed (`[^*]` is not reliably a
# valid label; `[^star]` is).
FN_SYMBOLS = "*∗⁎†‡§¶‖#"       # ASCII/operator asterisks, dagger, etc.
_SYMCLASS = "[" + re.escape(FN_SYMBOLS) + "]"
FN_MARKER_RE = re.compile(r"<sup>(\d+|" + _SYMCLASS + r"+)</sup>")
_SYM_LABEL = {"*": "star", "∗": "star", "⁎": "star", "†": "dagger",
              "‡": "ddagger", "§": "sect", "¶": "para", "‖": "dbar", "#": "hash"}


def fn_label(marker, page_idx=None):
    """GFM-safe footnote label for a raw marker. Digit footnotes are unique across
    a paper, so they pass through as-is. Symbol footnotes (`∗`, `†`, …) are reused
    from page to page (equal-contribution on p1, a table note on p14), so they are
    scoped by page to keep unrelated footnotes from collapsing onto one id; the
    symbol maps char-by-char to ASCII names (`∗`->`star`, `††`->`daggerdagger`)."""
    if marker.isdigit():
        return marker
    base = "".join(_SYM_LABEL.get(c, "") for c in marker) or "fn"
    return f"{base}-p{page_idx + 1:02d}" if page_idx is not None else base


def sup_marker_tokens(content):
    """The footnote marker token(s) inside a `<sup>…</sup>` content: a pure digit
    run, a pure symbol run, or a symbol run trailing on text — MinerU sometimes
    tags an author name and its affiliation mark together as one superscript
    (`<sup>LIM∗</sup>`), so recover the trailing `∗` as the marker."""
    if re.fullmatch(r"\d+", content):
        return [content]
    if re.fullmatch(_SYMCLASS + r"+", content):
        return [content]
    m = re.search(_SYMCLASS + r"+$", content)
    return [m.group(0)] if m else []


def page_anchor(page_idx):
    return f"[p{page_idx + 1:02d}]"


# --------------------------------------------------------------------------- #
# Text layer: words with bounding boxes, parsed leniently (poppler's -bbox XML
# is not always well-formed — regex tolerates the stray tokens ElementTree trips
# on).                                                                          #
# --------------------------------------------------------------------------- #
class TextLayer:
    def __init__(self, pdf):
        out = subprocess.run(["pdftotext", "-bbox", str(pdf), "-"],
                             capture_output=True, text=True).stdout
        self.pages = []  # page_idx -> list of (x0,y0,x1,y1, text)
        for pg in re.split(r"<page ", out)[1:]:
            words = []
            for x0, y0, x1, y1, t in WORD_RE.findall("<page " + pg):
                t = html.unescape(t).strip()
                if t:
                    words.append((float(x0), float(y0), float(x1), float(y1), t))
            self.pages.append(words)

    def words_in(self, page_idx, bbox, pad=1.0):
        """Text-layer words whose center falls in bbox, in reading order.
        Returns (text, cx, height) tuples sorted top-to-bottom, left-to-right."""
        if page_idx >= len(self.pages):
            return []
        x0, y0, x1, y1 = bbox
        hits = []
        for wx0, wy0, wx1, wy1, t in self.pages[page_idx]:
            cx, cy = (wx0 + wx1) / 2, (wy0 + wy1) / 2
            if x0 - pad <= cx <= x1 + pad and y0 - pad <= cy <= y1 + pad:
                hits.append((round(wy0), wx0, cx, wy1 - wy0, t))
        hits.sort(key=lambda h: (h[0], h[1]))
        return [(t, cx, h) for _, _, cx, h, t in hits]

    def render_line(self, page_idx, line_bbox, eqs, sup_markers=frozenset()):
        """Rebuild one line from the text layer over the FULL line bbox (so no
        word slips through a gap between spans), substituting each inline-
        equation region (given as (x0, x1, latex)) with MinerU's LaTeX. A word
        that MinerU tagged as a superscript on this line (its value is in
        `sup_markers` — a digit run or a footnote symbol) and is smaller than the
        surrounding text is a footnote reference marker -> `[^label]` (attached to
        the preceding word). Using MinerU's own `<sup>` signal — not raw geometry
        — keeps math subscripts (which are lowered, and live in equation spans
        anyway) from being mistaken for footnotes, and places the marker exactly
        where it belongs."""
        words = self.words_in(page_idx, line_bbox)
        if not words and not eqs:
            return ""
        heights = [h for _, _, h in words] or [1.0]
        med_h = sorted(heights)[len(heights) // 2]
        eqs = sorted(eqs)
        out, ei = [], 0
        for t, cx, h in words:
            while ei < len(eqs) and cx > eqs[ei][1]:       # passed an equation
                out.append(" " + eqs[ei][2]); ei += 1
            if ei < len(eqs) and eqs[ei][0] <= cx <= eqs[ei][1]:
                continue                                    # word inside equation region
            if t in sup_markers and h < 0.85 * med_h:       # footnote reference marker
                out.append(f"[^{fn_label(t, page_idx)}]")
            else:
                out.append(" " + t)
        for j in range(ei, len(eqs)):                       # trailing equations
            out.append(" " + eqs[j][2])
        return "".join(out).strip()


# --------------------------------------------------------------------------- #
# Figure/table store — numbering + crops + figures.md (ported from the OCR      #
# converter; image paths are bare sha filenames under <parse-dir>/images/).     #
# --------------------------------------------------------------------------- #
class FigureStore:
    def __init__(self, parse_dir, figures_dir):
        self.parse_dir = parse_dir
        self.figures_dir = figures_dir
        self.fig_n = 0
        self.table_n = 0
        self.copied = 0
        self.records = []   # {"label","file","page","caption"}
        self.missing = []   # {"label","file","page","kind","bbox","caption"}

    def next_label(self, kind, caption):
        m = NUM_RE.match(caption.lstrip())
        num = int(m.group(1)) if m else None
        if kind == "table":
            num = num if num is not None else self.table_n + 1
            self.table_n = max(self.table_n, num)
            return f"Table {num}", f"table-{num:02d}"
        num = num if num is not None else self.fig_n + 1
        self.fig_n = max(self.fig_n, num)
        return f"Fig. {num}", f"fig-{num:02d}"

    def copy_image(self, stem, label, page_idx, image_path, caption):
        if not image_path:
            return None
        src = self.parse_dir / "images" / Path(image_path).name
        if not src.is_file():
            return None
        ext = src.suffix.lstrip(".") or "png"
        name = f"{stem}.{ext}"
        dst = self.figures_dir / name
        suffix = ord("b")
        while dst.exists():
            name = f"{stem}-{chr(suffix)}.{ext}"
            dst = self.figures_dir / name
            suffix += 1
        self.figures_dir.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(src, dst)
        self.copied += 1
        self.records.append({"label": label, "file": f"figures/{name}",
                             "page": page_anchor(page_idx), "caption": caption})
        return f"figures/{name}"

    def record_missing(self, stem, label, kind, page_idx, bbox, caption):
        self.missing.append({"label": label, "file": f"figures/{stem}.jpg",
                            "page": page_anchor(page_idx), "kind": kind,
                            "bbox": bbox, "caption": caption})


def figure_kind(btype, caption):
    c = caption.lstrip()
    if re.match(r"(?i)table\b", c):
        return "table"
    if re.match(r"(?i)fig", c):
        return "figure"
    return "table" if btype == "table" else "figure"


# --------------------------------------------------------------------------- #
# Block rendering                                                              #
# --------------------------------------------------------------------------- #
def mineru_block_text(block):
    """MinerU's own text for a block (spans joined), used only as a fallback when
    the PDF has no usable text layer for this region (scanned pages). Strips the
    spurious <sub>/<sup> tags MinerU emits on some fonts; keeps equation LaTeX."""
    parts = []

    def walk(b):
        for ln in b.get("lines", []):
            for sp in ln.get("spans", []):
                st = sp.get("type")
                c = (sp.get("content") or "")
                if st == "inline_equation":
                    parts.append(f"${c}$" if c else "")
                elif st in ("interline_equation", "displayed_equation"):
                    parts.append(f"$${c}$$" if c else "")
                elif st in (None, "text"):
                    parts.append(c)
        for sub in b.get("blocks", []):
            walk(sub)

    walk(block)
    s = " ".join(p for p in parts if p)
    return re.sub(r"</?su[bp]>", "", s).strip()


def block_lines_text(block, page_idx, layer, page_sups=frozenset()):
    """Join a text-bearing block's lines into text-layer-refilled markdown,
    each line rebuilt over its full bbox with inline-equation LaTeX spliced in.
    Some MinerU text blocks carry no `lines` (line segmentation failed, often on
    math-dense text) — fall back to refilling the whole block bbox so the prose
    is not lost (inline-equation LaTeX is unavailable there, but the text layer
    still yields correct characters); `page_sups` (the page's footnote numbers)
    lets footnote references inside such a block still be marked. If the text
    layer yields nothing at all for the block (a scanned PDF with no text layer),
    fall back to MinerU's own OCR text so the block is not dropped."""
    if not block.get("lines"):
        return layer.render_line(page_idx, block["bbox"], [], page_sups) \
            or mineru_block_text(block)
    lines = []
    for ln in block.get("lines", []):
        eqs = []
        for sp in ln.get("spans", []):
            if sp.get("type") == "inline_equation":
                c = (sp.get("content") or "").strip()
                if c:
                    b = sp["bbox"]
                    eqs.append((b[0], b[2], f"${c}$"))
            elif sp.get("type") in ("interline_equation", "displayed_equation"):
                c = (sp.get("content") or "").strip()
                if c:
                    b = sp["bbox"]
                    eqs.append((b[0], b[2], f"$${c}$$"))
        # footnote markers MinerU tagged as superscripts on this line
        content = "".join(sp.get("content") or "" for sp in ln.get("spans", []))
        sup_markers = frozenset(
            tok for c in re.findall(r"<sup>([^<]*)</sup>", content)
            for tok in sup_marker_tokens(c))
        line = layer.render_line(page_idx, ln["bbox"], eqs, sup_markers)
        if line:
            lines.append(line)
    return " ".join(lines).strip() or mineru_block_text(block)


def caption_text(block, page_idx, layer, keys):
    for sub in block.get("blocks", []):
        if sub.get("type") in keys:
            txt = block_lines_text(sub, page_idx, layer)
            if txt:
                return txt
    return ""


def find_span(block, want):
    """Depth-first find the first span of a given type in a block subtree."""
    for sub in block.get("blocks", []):
        for ln in sub.get("lines", []):
            for sp in ln.get("spans", []):
                if sp.get("type") == want:
                    return sp
    for ln in block.get("lines", []):
        for sp in ln.get("spans", []):
            if sp.get("type") == want:
                return sp
    return None


def render_block(block, page_idx, layer, figures, page_sups=frozenset()):
    t = block.get("type")

    if t in ("text", "abstract", "code", "ref_text", "list", "index"):
        return block_lines_text(block, page_idx, layer, page_sups)

    if t == "title":
        txt = block_lines_text(block, page_idx, layer)
        lvl = block.get("level") or 1
        return ("#" * min(int(lvl), 6) + " " + txt) if txt else ""

    if t == "interline_equation":
        sp = find_span(block, "interline_equation") or find_span(block, "displayed_equation")
        c = (sp.get("content") or "").strip() if sp else ""
        return f"$$\n{c}\n$$" if c else ""

    if t in ("image", "chart", "table"):
        cap = caption_text(block, page_idx, layer,
                           ("image_caption", "chart_caption", "table_caption"))
        foot = caption_text(block, page_idx, layer,
                            ("image_footnote", "chart_footnote", "table_footnote"))
        kind = figure_kind(t, cap)
        label, stem = figures.next_label(kind, cap)
        img_sp = (find_span(block, "image") or find_span(block, "chart")
                  or find_span(block, "table"))
        image_path = img_sp.get("image_path") if img_sp else None
        table_html = (img_sp.get("html") or "").strip() if (img_sp and t == "table") else ""
        parts = []
        ref = figures.copy_image(stem, label, page_idx, image_path, cap)
        if ref:
            parts.append(f"![{cap or label}]({ref})")
            parts.append(cap if cap else label)
            if table_html:                       # table: keep BOTH crop and cells
                parts.append(table_html)
        elif table_html:
            if cap:
                parts.append(cap)
            parts.append(table_html)
        else:
            figures.record_missing(stem, label, kind, page_idx,
                                   block.get("bbox"), cap)
            parts.append(f"> ⚠ {label}: MinerU could not extract this {kind}. "
                        f"Recover at Finalize — see `ocr/figures.md`.")
            if cap:
                parts.append(cap)
        if foot:
            parts.append(foot)
        return "\n\n".join(p for p in parts if p)

    return ""


def write_metadata(out_dir, records, missing):
    lines = [
        "# Figure & table metadata", "",
        "Each extracted image in `figures/`, its paper reference number, the "
        "PDF page it came from, and its caption. Filenames encode the "
        "reference number (`fig-03.jpg` = Fig. 3); this table recovers the "
        "page a filename no longer carries.", "",
        "| Label | File | Page | Caption |", "| --- | --- | --- | --- |",
    ]
    for r in records:
        cap = (r["caption"] or "(caption未抽出)").replace("|", "\\|").replace("\n", " ")
        lines.append(f"| {r['label']} | {r['file']} | {r['page']} | {cap} |")
    if missing:
        lines += ["", "## ⚠ Not extracted — recover at Finalize", "",
                  "MinerU located these figure/table regions but its recognizer "
                  "produced no image and no HTML. Render each page with `pdftoppm` "
                  "and crop the region, then move its row up into the table above. "
                  "Drop the row instead if the region is a phantom.", "",
                  "| Intended file | Page | Kind | bbox (approx) | Caption |",
                  "| --- | --- | --- | --- | --- |"]
        for m in missing:
            cap = (m["caption"] or "(caption未抽出)").replace("|", "\\|").replace("\n", " ")
            bbox = ",".join(str(x) for x in m["bbox"]) if m.get("bbox") else "unknown"
            lines.append(f"| {m['file']} | {m['page']} | {m['kind']} | [{bbox}] | {cap} |")
    (out_dir / "figures.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def footnote_markers_by_page(parse_dir):
    """The set of footnote markers (digit runs or symbols) referenced on each
    page, from MinerU's content list (`<sup>…</sup>` markers that are not at a
    block's start, i.e. references, keyed by the block's page). Used to mark
    footnote references inside math-dense blocks that MinerU left without line
    segmentation, where the per-line `<sup>` signal is unavailable."""
    cls = sorted(parse_dir.glob("*_content_list.json"))
    if not cls:
        return {}
    try:
        blocks = json.loads(cls[0].read_text(encoding="utf-8"))
    except (ValueError, OSError):
        return {}
    by_page = {}
    for b in blocks:
        t = b.get("text") or ""
        pg = b.get("page_idx", 0)
        for mm in re.finditer(r"<sup>([^<]*)</sup>", t):
            if re.sub(r"<[^>]+>", "", t[:mm.start()]).strip():   # a reference, not a def
                for tok in sup_marker_tokens(mm.group(1)):
                    by_page.setdefault(pg, set()).add(tok)
    return by_page


def render_footnote_def(block, page_idx, layer):
    """A footnote definition — MinerU files these as `page_footnote` blocks in a
    page's discarded_blocks (page furniture), so they are rendered here rather
    than in the main block loop. block_lines_text has already turned each leading
    footnote marker into a `[^label]`; a single block may concatenate several
    definitions (e.g. `∗These authors… †Corresponding author…`), so split at every
    marker and emit one GFM definition `[^label]: …` per footnote."""
    txt = block_lines_text(block, page_idx, layer)
    if not txt:
        return ""
    # normalise a bare leading marker (symbol/digit not caught by sup detection)
    txt = re.sub(r"^(\d{1,3}|" + _SYMCLASS + r"+)\s+",
                 lambda mm: f"[^{fn_label(mm.group(1), page_idx)}] ", txt)
    tokens = re.split(r"(\[\^[^\]\s]+\])", txt)          # [pre, marker, body, marker, body, …]
    defs = []
    i = 1
    while i < len(tokens):
        label = tokens[i]
        body = tokens[i + 1].strip() if i + 1 < len(tokens) else ""
        defs.append(f"{label}: {body}")
        i += 2
    return "\n\n".join(defs) if defs else txt


def main():
    if len(sys.argv) != 4:
        print(f"usage: {sys.argv[0]} <parse-dir> <ocr-dir> <pdf-path>", file=sys.stderr)
        return 2
    parse_dir, out_dir, pdf = Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3])

    mids = sorted(parse_dir.glob("*_middle.json"))
    if not mids:
        print(f"error: no *_middle.json in {parse_dir}", file=sys.stderr)
        return 1
    m = json.loads(mids[0].read_text(encoding="utf-8"))
    layer = TextLayer(pdf)
    figures = FigureStore(parse_dir, out_dir / "figures")

    fn_by_page = footnote_markers_by_page(parse_dir)
    chunks = []
    for pinfo in m["pdf_info"]:
        pidx = pinfo["page_idx"]
        page_sups = frozenset(fn_by_page.get(pidx, ()))
        chunks.append(page_anchor(pidx))
        for block in sorted(pinfo.get("para_blocks", []), key=lambda b: b.get("index", 0)):
            rendered = render_block(block, pidx, layer, figures, page_sups)
            if rendered:
                chunks.append(rendered)
        # footnote definitions live in discarded_blocks (MinerU treats them as
        # page furniture); emit each page's after its body so `[^N]:` resolves.
        for fb in pinfo.get("discarded_blocks", []):
            if fb.get("type") == "page_footnote":
                d = render_footnote_def(fb, pidx, layer)
                if d:
                    chunks.append(d)

    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "paper.md").write_text("\n\n".join(chunks) + "\n", encoding="utf-8")
    write_metadata(out_dir, figures.records, figures.missing)

    pages = len(m["pdf_info"])
    miss = len(figures.missing)
    print(f"text-layer rebuild: {pages} page(s) -> {out_dir/'paper.md'}, "
          f"{figures.copied} figure(s) -> {out_dir/'figures'}/, "
          f"metadata -> {out_dir/'figures.md'}"
          + (f"; ⚠ {miss} figure/table(s) MinerU could not extract" if miss else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main())
