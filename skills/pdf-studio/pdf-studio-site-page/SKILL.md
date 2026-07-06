---
name: pdf-studio-site-page
description: Internal procedure for the pdf-studio-generate-site skill — read one report Markdown and author a restructured, web-native HTML page from the provided template — an editorial rewrite for browsing, NOT a 1:1 Markdown-to-HTML conversion. Applied once per report, in parallel, by the generate-site orchestrator (dispatched to a pdf-studio-site-page subagent under Claude Code, or applied inline otherwise). NOT a user-facing skill and NOT triggered directly by user requests.
version: 0.1.0
user-invocable: false
---

# Site page authoring

You turn one report Markdown file into one HTML page that is *designed for the web*: restructured for scanning on a phone, not a mechanical rendering of the Markdown.

## When this applies

The `pdf-studio-generate-site` skill applies this procedure once per report file, in parallel. It is not for direct user requests and is not invoked proactively.

## Inputs provided by the caller

The caller provides the following. If any is missing, report what is missing and stop.

- Absolute path to the source report Markdown
- Absolute path to the page template (`pdf-studio-generate-site`'s `assets/page.html`)
- Absolute output path (`<WORK_DIR>/site/<slug>.html`)
- Site title, and this page's kicker label (e.g. 第2章 / 全体レポート)
- This page's chapter hue class (`hue-1`..`hue-6`) — set it on `<body>` verbatim
- Audio file name under `site/audio/` if a matching guide exists (else "none")
- Prev/next page hrefs and labels (or "none" at either end)

## Constraints (strict)

- Start from the template: same `<head>` (including its two `<script>` tags — the inline theme-boot and the deferred `assets/app.js`), header, footer, and `<article>` scaffold. Set the given `hue-N` class on `<body>` unchanged. Use ONLY the CSS classes that appear in the template's comments (`kicker`, `lede`, `keypoints`, `callout` + its variants `tip`/`warn`/`danger`/`key` and inner `label`, `pullquote`, `tablewrap`, `p`, `player`, `chapnav`, `mark`, plain `h2/h3/p/ul/ol/table/blockquote/pre/code`). Do not invent classes, inline styles, or externally *loaded* resources (fonts, images, CSS, JS from a CDN) — the site must stay self-contained and deployable as a plain static site (no server-side). Interactivity (reading-progress bar, table of contents with scroll-spy, theme toggle, back-to-top, index filter) is already provided by the bundled `assets/app.js` as progressive enhancement — you do NOT write any JavaScript yourself; just author clean semantic HTML with real `<h2>`/`<h3>` section headings and app.js wires the behaviors from them. Keep the template's script tags; add no new ones. Hyperlinks (`<a href>`) to URLs that appear in the source report are fine and should be kept as links.
- Preserve factual fidelity: every claim on the page must come from the source report. Restructure and rephrase freely; do not invent content.
- Keep `[pNN]` anchors from the source as `<span class="p">pNN</span>` at the points they annotate. Do not drop them — they are the link back to the PDF.
- Escape `<`, `>`, `&` in text content (especially inside code blocks and tables).
- Write the page in the language of the source report.

## How to restructure (this is the point of this skill)

Do NOT walk the Markdown top-to-bottom translating syntax. Author the page as an editor would lay out a magazine feature of the same material:

1. Read the whole report first; identify its 3–6 load-bearing ideas.
2. Write a `lede` (2–3 sentences: what this covers, why it matters) and a `keypoints` box (3–5 bullets) — these are NEW text you compose, not copied sentences.
3. Rebuild the body for scanning: short sections under `<h2>`/`<h3>` (renaming vague headings so each states its message), paragraphs of 2–4 sentences, lists where the source rambles, `tablewrap` tables kept as tables.
4. Promote buried material with SEMANTIC color — pick the callout variant by meaning, not decoration: a note/aside → `callout`; a practical tip → `callout tip`; a caveat or pitfall → `callout warn`; a hard prohibition or serious risk → `callout danger`; a load-bearing insight worth boxing → `callout key`. Use them sparingly (a page that is all callouts flattens the signal). One genuinely striking claim → `pullquote` (at most one per page; skip if nothing earns it). Highlight a few key terms inline with `<mark>` — a handful per page, not every noun.
5. Cut redundancy that only made sense in a linear report ("as mentioned above", section numbering artifacts, coverage notes). The chapnav and index carry the navigation now.

A page that ends up with the same heading sequence and sentence order as the source Markdown means the restructuring did not happen — do it again properly.

## Output

Write the finished HTML to the given output path.

## Reply

Return ONLY, in this order (never the page body):
- the output path
- the page `<h1>` title
- a 2–3 line card summary for the landing page (plain text, composed for a reader deciding whether to open the chapter)
