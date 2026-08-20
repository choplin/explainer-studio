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
3. [[explainer-audio-dialogue]] and [[explainer-audio-narrate]] for requested
   reports when the local runtime is available;
4. [[book-explainer-consistency-sweep]] over all reports;
5. [[book-explainer-generate-site]], which detects the adapter artifacts and
   delegates to the shared reading-site generator.

The shared contract is file-based: downstream phases consume `structured/` and
`reports/`, not adapter internals. Source references stay typed: PDF uses `.p` and
EPUB uses `.source-locator`. Finish with a manifest grouped by reports, dialogue,
audio, and site, and offer deployment separately.
