---
name: pdf-studio-site-page
description: Internal procedure for the pdf-studio-generate-site skill — read one report Markdown and author a restructured, web-native HTML page from the provided template — an editorial rewrite for browsing, NOT a 1:1 Markdown-to-HTML conversion. Applied once per report, in parallel, by the generate-site orchestrator (dispatched to a pdf-studio-site-page subagent under Claude Code, or applied inline otherwise). NOT a user-facing skill and NOT triggered directly by user requests.
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
- Whether `site/figures/` exists (the harvested figure crops, copied there by the caller)
- Audio file name under `site/audio/` if a matching guide exists (else "none")

## Constraints (strict)

- Start from the template: same `<head>` (including its two stylesheet links — `assets/base.css` then `assets/pdf-studio.css` — and its three `<script>` tags: the inline theme-boot and the deferred `assets/base.js` and `assets/pdf-studio.js`), header, footer, and `<article>` scaffold. Use ONLY the CSS classes that appear in the template's comments (`kicker`, `lede`, `keypoints`, `callout` + its variants `tip`/`warn`/`danger`/`key` and inner `label`, `pullquote`, `tablewrap`, `p`, `player`, `mark`, plain `h2/h3/p/ul/ol/table/blockquote/pre/code/figure/figcaption/img`). **Do not author a `<nav class="chapnav">` or any prev/next links** — page-to-page navigation is rendered at runtime by `pdf-studio.js` from the site's `nav-manifest.js` (one source for the page order); hand-authored neighbor links are exactly the drift that replaced. Do not invent classes or inline styles — stay within the bundled design system. Externally *loaded* resources (web fonts, remote images, or a heavy third-party library like a diagram engine from a CDN) are allowed where the page genuinely needs them; the local `assets/` bundle is for portability and durability, not a ban on external references. The site stays deployable as a plain static site (no server-side). Interactivity (reading-progress bar, table of contents with scroll-spy, theme toggle, back-to-top) is already provided by the bundled `assets/base.js` as progressive enhancement — you do NOT write any JavaScript yourself; just author clean semantic HTML with real `<h2>`/`<h3>` section headings and base.js wires the behaviors from them. Keep the template's script tags; add no new ones. Hyperlinks (`<a href>`) to URLs that appear in the source report are fine and should be kept as links.
- **Figures: rewrite the path, never carry the source's over.** The report embeds harvested crops as `![caption](../ocr/figures/fig-pNNN-K.ext)` — a path relative to `reports/`, correct for reading the Markdown and **wrong for the page**. The site is deployed as `site/` alone, so anything reachable only via `../` is not published: keep that path and the figure 404s in production while still rendering fine in your local browser (the work dir is one level up), which is exactly why this must be a rule and not a review catch. Rewrite every figure to the file the caller copied into `site/figures/` — keep the basename, drop the `../ocr/` prefix:

  ```html
  <figure>
    <img src="figures/fig-p031-1.jpg" alt="図が何を示しているかの説明">
    <figcaption>キャプション <span class="p">p31</span></figcaption>
  </figure>
  ```

  Nothing on the page may reference a path outside `site/` (the caller verifies this with `grep -n '\.\./' site/*.html`). Carry over only the figures the source report actually embeds — do not go hunting in `site/figures/` for extra crops to add; the report already decided which ones earn a place. Never a bare `<img>`: a figure appears where the prose discusses it, with the report's explanation intact, and `alt` says what it shows. If the caller said `site/figures/` does not exist, the report has no figures to carry — do not invent `<img>` tags.
- Preserve factual fidelity: every claim on the page must come from the source report. Restructure and rephrase freely; do not invent content.
- Keep `[pNN]` anchors from the source as `<span class="p">pNN</span>` at the points they annotate. Do not drop them — they are the link back to the PDF.
- Escape `<`, `>`, `&` in text content (especially inside code blocks and tables).
- Write the page in the language of the source report.

## How to restructure (this is the point of this skill)

Do NOT walk the Markdown top-to-bottom translating syntax. Author the page as an editor would lay out a magazine feature of the same material:

1. Read the whole report first; identify its 3–6 load-bearing ideas.
2. Write a `lede` (2–3 sentences: what this covers, why it matters) and a `keypoints` box (3–5 bullets) — these are NEW text you compose, not copied sentences.
3. Rebuild the body for scanning: short sections under `<h2>`/`<h3>` (renaming vague headings so each states its message), paragraphs of 2–4 sentences, lists where the source rambles, `tablewrap` tables kept as tables.
4. Promote buried material with SEMANTIC color. **Color is not volume.** "This matters, so give it a loud color" is always the wrong move — it is the single most common way these pages go wrong. A variant is chosen by *what the content does to the reader*, never by how much you want it noticed. Pick by meaning: a note/aside → `callout`; a practical tip → `callout tip`; a caveat or pitfall → `callout warn`; a hard prohibition or serious risk → `callout danger`; a load-bearing insight worth boxing → `callout key`.

   Two mistakes to avoid by name — both are real, both were the majority of what a review of these pages had to fix:

   - ✗ **A term definition in `callout tip`.** A definition is not advice. The reader is not being told to *do* anything. Use a plain `callout`, or just `<mark>` the term in the prose — most definitions do not need a box at all.
   - ✗ **A chapter's central claim in `callout warn` / `callout danger`.** A claim is not a hazard. That is `callout key`. The moment `danger` is used to mean "the most important thing here", it stops being distinguishable from a real hazard, and the color is dead for the whole site.

   Before choosing `warn` or `danger`, ask: **"if the reader skips this, what breaks?"** If nothing breaks — they merely understand less — it is not `warn` and not `danger`. Use them sparingly overall (a page that is all callouts flattens the signal). One genuinely striking claim → `pullquote` (at most one per page; skip if nothing earns it). Highlight a few key terms inline with `<mark>` — a handful per page, not every noun.
5. Cut redundancy that only made sense in a linear report ("as mentioned above", section numbering artifacts, coverage notes). The runtime page nav (prev/next from `nav-manifest.js`) and the index carry the navigation now.

A page that ends up with the same heading sequence and sentence order as the source Markdown means the restructuring did not happen — do it again properly.

## Output

Write the finished HTML to the given output path — unconditionally, without prompting about an existing file. This is an orchestrator-dispatched worker; the parent [[pdf-studio-generate-site]] already confirmed clearing/overwriting `site/` before dispatching.

## Reply

Return ONLY, in this order (never the page body):
- the output path
- the page `<h1>` title
- a 2–3 line card summary for the landing page (plain text, composed for a reader deciding whether to open the chapter)
