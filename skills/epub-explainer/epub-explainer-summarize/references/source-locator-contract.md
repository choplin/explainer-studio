# EPUB source locator contract

An EPUB source locator has two deliberately separate forms.

- **Canonical locator** — `<spine-resource>#<fragment>`, for example
  `OEBPS/Text/ch03.xhtml#section-2`. The resource is the normalized archive path
  from the OPF manifest. The fragment is the source `id` when present.
- **Display locator** — the source-authored navigation path, for example
  `Chapter 3 › Storage engines`. This is reader-facing and may be translated for
  display without changing the canonical locator.

When a heading has no source fragment, the adapter assigns
`generated-sNNNN-nNNNNNN`, where the first number is the one-based spine position
and the second is the heading's deterministic DOM-block position. The mapping is
stored in `epub/locators.json`; it never mutates the source EPUB.

`structured/toc.md` records source headings as:

```text
- [loc:OEBPS/Text/ch03.xhtml#section-2] L2 | Storage engines |
```

Reports and sites use this prose form:

```markdown
[Chapter 3 › Storage engines]{.source-locator data-locator="OEBPS/Text/ch03.xhtml#section-2"}
```

The visible label aids reading. `data-locator` is the traceability authority.
Site validation checks it against the `valid_locators` union in
`epub/locators.json`, which includes actual spine resources and source IDs.
Authored navigation or print-page targets that do not resolve remain visible as
source discrepancies; they are not silently admitted as valid locators.
Do not invent `[pNN]` for reflowable EPUBs. If the source contains an EPUB
`page-list`, keep its print-page values as optional metadata; they do not replace
the canonical locator.
