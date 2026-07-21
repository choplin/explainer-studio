---
name: pdf-studio-site-page
description: Internal procedure for the pdf-studio-generate-site skill — read one report Markdown and author a restructured, web-native page as semantic Markdown (Markdown + fenced divs), NOT a 1:1 conversion and NOT hand-written HTML. The understanding-html-docs generator binds the semantic Markdown to the markup contract deterministically; this procedure writes only the meaning (which passage is a hazard, the key point, the takeaways) and the editorial restructuring. Applied once per report, in parallel, by the generate-site orchestrator (dispatched to a pdf-studio-site-page subagent under Claude Code, or applied inline otherwise). NOT a user-facing skill and NOT triggered directly by user requests.
user-invocable: false
---

# Site page authoring

You turn one report Markdown file into one **semantic Markdown file** (Markdown + fenced divs) that is *designed for the web*: restructured for scanning on a phone, not a mechanical rendering of the source. The [[understanding-html-docs]] generator turns your semantic Markdown into the final HTML page — you never write HTML, `<head>`, classes, or asset links, and you never rewrite figure paths or escape characters. Those are the generator's job and it cannot get them wrong. **Your whole job is meaning and structure**: which passage is a hazard vs the key point, what the takeaways are, and how to lay the material out for reading.

## When this applies

The `pdf-studio-generate-site` skill applies this procedure once per report file, in parallel. It is not for direct user requests and is not invoked proactively.

## Inputs provided by the caller

The caller provides the following. If any is missing, report what is missing and stop.

- Absolute path to the source report Markdown
- Absolute output path for the source (`<WORK_DIR>/src/<slug>.md`)
- Site title, and this page's kicker label (e.g. 第2章 / 全体レポート)
- Whether `<WORK_DIR>/ocr/figures/` exists (harvested figure crops the caller copies into `site/figures/`)
- Audio file name under `site/audio/` if a matching guide exists (else "none")

## The source you write

Write a Markdown file with this frontmatter, then the body in the semantic-Markdown vocabulary below. The frontmatter is boilerplate — keep it **verbatim except** `title` and the kicker text; it wires the page chrome and the asset order (the generator owns `<head>`, theme-boot, and asset links from it):

```yaml
---
title: <PAGE_TITLE> — <SITE_TITLE>
site-name: "← <SITE_TITLE>"        # header link back to the index
context-css: pdf-studio.css
context-js:
  - nav-manifest.js                # page-nav data — must load before the script that reads it
  - pdf-studio.js
---
```

Body vocabulary — reach only for these; the generator rejects anything else (an invented class or raw HTML cannot pass, an unknown callout variant is a hard build error):

| To express | Write in the semantic Markdown |
|---|---|
| The kicker label (第N章 / 全体レポート) | `::: {.kicker}` … `:::` (the label passed by the caller) |
| The page title | `# <PAGE_TITLE>` |
| Opening 2–3 sentences (what this covers, why it matters) | `::: {.lede}` … `:::` |
| The takeaways box (3–5 bullets) | `::: {.keypoints}` with `### この章のポイント` + a `- ` list `:::` |
| Section / subsection headings | `## …` / `### …` |
| General note / aside | `::: {.callout}` … `:::` (bare = note) |
| Advice / caution / hazard / key insight | `::: {.callout variant=tip\|warn\|danger\|key}` … `:::` |
| A colored lead-in inside a callout | `[結論:]{.label}` at the paragraph start |
| One striking sentence (≤1 per page) | `::: {.pullquote}` … `:::` |
| An inline highlighted term | `[term]{.mark}` |
| A source-PDF page anchor | `[p31]{.p}` |
| A harvested figure | `![説明](../ocr/figures/fig-p031-1.jpg)` — **carry the source path as-is**; the generator rewrites `../ocr/figures/` → `figures/` so nothing points outside the site |
| An in-page audio player (only if the caller gave an audio file) | `::: {.player src=audio/<file>}` `:::` |
| Tabular data | a plain Markdown table — wrapped in `.tablewrap` automatically |
| A code sample | a ` ```{.nohighlight} ` fenced block |
| Prose, lists, blockquotes, links | plain Markdown |

## Constraints (meaning only)

Everything mechanical is the generator's guarantee — you do **not** write HTML, `<head>`, classes, asset/script tags, prev/next nav, figure-path rewrites, `<`/`>`/`&` escaping, or `.tablewrap`. What remains yours:

- **Factual fidelity**: every claim in the source must come from the source report. Restructure and rephrase freely; do not invent content.
- **Keep every `[pNN]` anchor** from the source, written as `[pNN]{.p}` at the point it annotates. Do not drop them — they are the link back to the PDF.
- **Write in the language of the source report.**
- **Carry only the figures the source report actually embeds** — do not go hunting in `figures/` for extra crops. If the caller said `ocr/figures/` does not exist, the report has no figures; do not invent any. Never a bare figure: it appears where the prose discusses it, with the report's explanation intact, and the alt text says what it shows.
- **Do not author prev/next links.** Page-to-page navigation is rendered at runtime by `pdf-studio.js` from the site's `nav-manifest.js` (loaded via the `context-js` frontmatter) — one source for the page order. Hand-authored neighbor links are exactly the drift a single source removes.

## How to restructure (this is the point of this skill)

Do NOT walk the source top-to-bottom translating syntax. Author the page as an editor would lay out a magazine feature of the same material:

1. Read the whole report first; identify its 3–6 load-bearing ideas.
2. Write a `lede` (2–3 sentences: what this covers, why it matters) and a `keypoints` box (3–5 bullets) — these are NEW text you compose, not copied sentences.
3. Rebuild the body for scanning: short sections under `##`/`###` (renaming vague headings so each states its message), paragraphs of 2–4 sentences, lists where the source rambles, tables kept as tables.
4. Promote buried material with SEMANTIC color. **Color is not volume.** "This matters, so give it a loud color" is always the wrong move — it is the single most common way these pages go wrong. A variant is chosen by *what the content does to the reader*, never by how much you want it noticed. Pick by meaning: a note/aside → `::: {.callout}`; a practical tip → `::: {.callout variant=tip}`; a caveat or pitfall → `variant=warn`; a hard prohibition or serious risk → `variant=danger`; a load-bearing insight worth boxing → `variant=key`.

   Two mistakes to avoid by name — both are real, both were the majority of what a review of these pages had to fix:

   - ✗ **A term definition in `variant=tip`.** A definition is not advice. The reader is not being told to *do* anything. Use a plain `::: {.callout}`, or just `[term]{.mark}` in the prose — most definitions do not need a box at all.
   - ✗ **A chapter's central claim in `variant=warn` / `variant=danger`.** A claim is not a hazard. That is `variant=key`. The moment `danger` is used to mean "the most important thing here", it stops being distinguishable from a real hazard, and the color is dead for the whole site.

   Before choosing `warn` or `danger`, ask: **"if the reader skips this, what breaks?"** If nothing breaks — they merely understand less — it is not `warn` and not `danger`. Use them sparingly overall (a page that is all callouts flattens the signal). One genuinely striking claim → `::: {.pullquote}` (at most one per page; skip if nothing earns it). Highlight a few key terms inline with `[term]{.mark}` — a handful per page, not every noun.
5. Cut redundancy that only made sense in a linear report ("as mentioned above", section numbering artifacts, coverage notes). The runtime page nav (prev/next from `nav-manifest.js`) and the index carry the navigation now.

A page that ends up with the same heading sequence and sentence order as the source means the restructuring did not happen — do it again properly.

## Output

Write the finished source to the given output path (`<WORK_DIR>/src/<slug>.md`) — unconditionally, without prompting about an existing file. This is an orchestrator-dispatched worker; the parent [[pdf-studio-generate-site]] already confirmed clearing/overwriting before dispatching. Do NOT run the generator yourself — the orchestrator builds every source into HTML in one pass afterward.

## Reply

Return ONLY, in this order (never the source body):
- the output path
- the page title (the `# …` heading text)
- a 2–3 line card summary for the landing page (plain text, composed for a reader deciding whether to open the chapter)
