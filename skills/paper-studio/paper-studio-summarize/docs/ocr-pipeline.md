# OCR phase — how `ocr/paper.md` is built

Reference for maintainers of `scripts/mineru_ocr.sh` and
`scripts/mineru_to_paper_md.py`. It documents how the paper's text and figures
are produced in Phase 1. The operational contract (what the rest of the skill
relies on) is in `SKILL.md`; this file is the implementation detail behind it.

## Why text-layer-primary

The PDFs this skill targets (CS conference/journal papers, ACM `acmart` /
LinLibertine typeface) are born-digital: they carry a correct embedded text
layer. MinerU's default backend (`hybrid`/VLM) instead image-recognizes every
page, and on this font class that recognition is lossy:

- **descenders dropped** — `making` → `makin`, `by` → `b` (y/g/p glyphs lost)
- **ff/fi ligatures collapsed** — `different` → `diferent`, `effective` → `efective`
- **spurious `<sub>`/`<sup>` tags** — normal kerning tagged as sub/superscript,
  inflating the file (~45% of bytes on one sample) with no added information

`pdftotext` reads the same text layer with none of these defects. So the body
text is taken from the text layer, and MinerU is used only for what the text
layer cannot give: block reading order, figure/table crops, formula LaTeX, and
block classification.

## Method selection (`mineru_ocr.sh`)

```
mineru_ocr.sh <pdf-path> <ocr-dir>
```

1. Probe the text layer: `pdftotext -f 1 -l 5 <pdf>`, count alphanumerics. `>= 200`
   → born-digital → `METHOD=txt`; otherwise → scanned → `METHOD=ocr`.
2. `mineru -p <pdf> -o <tmp> -b pipeline -m <METHOD>`. `-b pipeline` is
   mandatory — the default backend image-recognizes every page and reintroduces
   the defects above.
3. Locate `*_middle.json` under the MinerU output and hand its directory, the
   `<ocr-dir>`, and the PDF path to `mineru_to_paper_md.py`.

Everything is local (MinerU pipeline backend + poppler `pdftotext`); nothing is
uploaded, so under-review manuscripts are safe.

## Inputs (`mineru_to_paper_md.py`)

```
mineru_to_paper_md.py <parse-dir> <ocr-dir> <pdf-path>
```

- **`<parse-dir>/*_middle.json`** — the layout skeleton. Per page: `page_idx`,
  `page_size`, `para_blocks` (each with `type`, `bbox`, `index` = reading order,
  and `lines` → `spans`), and `discarded_blocks` (page furniture, incl.
  footnotes). Spans carry `type` (`text` / `inline_equation` /
  `interline_equation` / `image` / `chart` / `table`), `bbox`, and `content`
  (equation LaTeX, or MinerU's own tagged text). Image/table spans carry
  `image_path` (a crop under `<parse-dir>/images/`) and, for tables, `html`.
- **`pdftotext -bbox <pdf>`** — the authoritative words, each with a bounding
  box. Parsed leniently with a regex (poppler's `-bbox` output is not always
  well-formed XML). `TextLayer.pages[page_idx]` = `(x0, y0, x1, y1, text)` list.

MinerU's `page_size` and poppler's `-bbox` page are the same PDF-point space,
same top-left origin, 1:1 — a word's centre can be tested against a span bbox
directly, no scaling.

## Rebuild

Pages are emitted in order, each prefixed with a `[pNN]` anchor; within a page,
`para_blocks` are emitted in `index` order. `render_block` dispatches on type:

| block type | source of content | output |
| --- | --- | --- |
| `text` / `abstract` / `code` / `ref_text` / `list` / `index` | text layer, per line | prose (see below) |
| `title` | text layer | `#`×`level` heading |
| `interline_equation` | MinerU `content` | `$$…$$` |
| `image` / `chart` | crop `image_path` + caption span | `![caption](figures/fig-NN.ext)` + caption |
| `table` | crop `image_path` **and** `html` | image + `<table>` cell HTML + caption |

**Prose (`block_lines_text` → `render_line`).** For each line: collect its
`inline_equation` spans as `(x0, x1, LaTeX)` regions, then rebuild the line over
its **full bbox** from text-layer words (so a word never slips through a gap
between spans). Words whose centre lies inside an equation region are dropped and
replaced by the LaTeX; all other words are emitted in reading order. A footnote
marker is spliced in as `[^label]` (see below).

**Figures.** Numbered by the reference number parsed from the caption (`Fig. 3`
→ `fig-03`, `Table 1` → `table-01`); a caption MinerU dropped inherits
previous + 1. Crops are copied to `<ocr-dir>/figures/`. `chart` spans are found
under the `chart` span type; a `table`-typed block whose caption starts with
`Fig` is numbered in the figure sequence.

**Tables** keep both the crop **and** the `html` cell text, so numeric results
survive in the text stream rather than living only inside an image.

**Fallbacks (in `block_lines_text`):**
- A text block with **no `lines`** (MinerU failed to segment it, common on
  math-dense text) is refilled over the whole block bbox; inline-equation LaTeX
  is unavailable there, but the text-layer characters are still correct.
- If the text layer yields **nothing** for a block (a scanned PDF with no text
  layer), fall back to MinerU's own recognized text (`mineru_block_text`, with
  `<sub>`/`<sup>` tags stripped).

## Footnotes

Restoring the body↔footnote link that a plain text-layer word ("just a digit")
would lose. MinerU tags footnote markers as `<sup>…</sup>`; that signal — not raw
geometry — is used, so math subscripts (lowered, and in equation spans anyway)
are never mistaken for footnotes.

- **What counts as a marker** (`sup_marker_tokens`): a digit run, or a footnote
  symbol from `*∗⁎†‡§¶‖#` (incl. the Unicode operator `∗` U+2217, which papers
  use in place of ASCII `*`), or a symbol trailing on text — MinerU sometimes
  tags an author name and its mark together (`<sup>LIM∗</sup>`), so the trailing
  `∗` is recovered. Non-digit **letters** are excluded: those are the ligature /
  ascender noise (`fi`, `ff`, `h`, `d`, …), never real footnotes.
- **Labels** (`fn_label`): digits pass through unchanged (`[^7]`) — numeric
  footnotes are unique across a paper. Symbols map to an ASCII name and are
  **page-scoped** (`∗` → `[^star-p01]`) because symbols are reused from page to
  page (equal-contribution on p1, a table note on p14); a global `[^star]` would
  collapse unrelated footnotes onto one id.
- **References** are marked where the small superscript sits: inside a
  well-segmented line via that line's `<sup>` tags; inside a no-line block via
  the page's marker set (`footnote_markers_by_page`, reference-position markers
  only).
- **Definitions** come from `page_footnote` blocks in `discarded_blocks`
  (`render_footnote_def`). One such block may concatenate several definitions
  (`∗These authors… †Corresponding author…`); it is split at every marker into
  one `[^label]: …` per footnote.

## Outputs

Written to `<ocr-dir>/`:

- **`paper.md`** — one `[pNN]` anchor per PDF page (`pNN` = PDF page number, not
  the printed page number), headings, prose, `$…$` / `$$…$$` math, figures as
  relative `![](figures/…)` refs, tables as image + `<table>` HTML, footnotes as
  GFM `[^label]` / `[^label]: …`.
- **`figures/fig-NN.ext` / `table-NN.ext`** — crops named by paper reference
  number.
- **`figures.md`** — a metadata table (Label / File / Page / Caption) mapping
  each crop to its page, plus a `⚠ Not extracted` section listing regions MinerU
  located but could not crop, for the skill's Finalize step to recover.

## Fidelity & known limitations

- **Body-vocab fidelity** vs the text layer is ~92–98% on the sample corpus.
  The gap is **not** lost prose: it is table cell text (present in the `<table>`
  HTML but not counted as body vocabulary) and page furniture MinerU files under
  `discarded_blocks` (ACM copyright/license, running headers) that is
  intentionally not emitted. No descender loss, no ligature collapse, and no
  `<sub>`/`<sup>` tags remain.
- **Footnote definition ordering** — a `page_footnote` block refilled from the
  text layer can occasionally pull in an adjacent word (e.g. a nearby table
  label) at the start of a definition. The content is preserved; the ordering is
  not always exact.
- **Symbol footnote reuse within one page** — page-scoping prevents cross-page
  collisions, but two different footnotes using the same symbol on the *same*
  page are not disambiguated (rare).
- **Scanned PDFs** — no text layer, so the body falls back to MinerU's OCR text,
  which is subject to MinerU's recognition quality (the defects this pipeline
  avoids for born-digital PDFs can reappear).
