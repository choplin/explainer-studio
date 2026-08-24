---
name: book-explainer-full-guide
description: "Run the source-neutral full book pipeline for a PDF or DRM-free reflowable EPUB: overview, chapter reports, optional audio, consistency review, and a local reading site."
user-invocable: true
---

# Full book guide

Select the input adapter from the file content and extension: PDF delegates to
[[pdf-explainer-summarize]] and [[pdf-explainer-pdf-detail]]; EPUB delegates to
[[epub-explainer-summarize]] and [[epub-explainer-epub-detail]]. Never convert
EPUB to PDF. If the input is neither, stop.

Confirm scope once before work: chapters (default all top-level), audio targets
(default overview and selected chapters), optional audio length, source-file
collection, and local site build (default yes). The selected adapter may add only
input-specific preflight choices. Publishing is never part of this run.

Run in this order:

1. adapter summarize → `structured/toc.md`, `structured/outline.md`, and
   `reports/overview.md`;
2. adapter detail for every selected top-level chapter, in parallel where safe;
3. [[explainer-audio-dialogue]] for requested reports, with a guide-design pilot
   before any multi-report fan-out and a diagnostic comparison of the set;
4. [[explainer-audio-narrate]] for the finished scripts when the local runtime is
   available;
5. [[book-explainer-consistency-sweep]] over all reports;
6. [[book-explainer-generate-site]], which detects the adapter artifacts and
   delegates to the shared reading-site generator.

The shared contract is file-based: downstream phases consume `structured/` and
`reports/`, not adapter internals. Source references stay typed: PDF uses `.p` and
EPUB uses `.source-locator`. Finish with a manifest grouped by reports, dialogue,
audio, and site, and offer deployment separately.

When audio covers one report, follow [[explainer-audio-dialogue]] in full,
including its required guide-design procedure and diagnostic size check.

When audio covers more than one report, do not generate every dialogue in the
first fan-out. Choose one representative pilot first: prefer the selected detail
report with the most speakable source prose, or the overview when no detail report
is selected. Generate it with [[explainer-audio-dialogue]] and review its listener
destination, explanatory spine, evidence selection, and altitude. Use that
content-selection pattern—not its runtime—as calibration when generating the
remaining targets in parallel.

Before narration, make a compact table for every script containing its slug,
source characters, spoken characters, compression ratio, and estimated duration.
Use [[explainer-audio-dialogue]]'s warnings to find scripts whose creation choices
need another look. Among three or more detail guides, a duration or compression
ratio above twice the detail-guide median is another prompt to recheck the spine
and evidence selection—not a demand for equal runtimes. Revise when the guide has
drifted into a spoken report. A warning alone does not block a faithful guide; ask
the user only when the proposed remedy changes the confirmed deliverable, such as
splitting one guide into a series. [[book-explainer-consistency-sweep]] remains
responsible only for report accuracy and consistency.
