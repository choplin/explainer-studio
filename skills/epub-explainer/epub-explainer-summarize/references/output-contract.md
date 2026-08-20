# EPUB adapter output contract

The adapter writes under one `<WORK_DIR>`:

```text
epub/
  preflight.json       # kind, support verdict, package/nav facts
  metadata.json        # title, creator, language, identifier when present
  source.json          # OPF spine index (`linear` flag) and media inventory
  locators.json        # canonical/display locator mapping
  spine/item-NNNN.json # semantic blocks plus original XHTML fragments
  media/...            # original image and SVG bytes, manifest paths preserved
extract/
  chunk-*.md           # isolated-worker reading material
structured/
  toc.md               # source-authored heading spine
  outline.md           # stitched, compressed source material
reports/
  overview.md
```

Each block in a spine JSON file keeps normalized text, a useful Markdown view,
EPUB semantics, language, canonical locator, and its serialized source XHTML.
The XHTML field is the fidelity backstop for tables, ruby, notes, and other
semantics that Markdown cannot represent without loss.

`linear: true` entries define primary reading order. `linear: false` entries are
kept as auxiliary addressable documents so cross-resource footnotes/endnotes and
other semantic supplements remain resolvable; they are not promoted into the
primary chapter sequence.

`epub_extract.py` replaces only its adapter-owned `epub/` directory when
`--force` is supplied. The parent skill owns confirmation before passing that
flag. Reports and other pipeline outputs are never deleted by the adapter.
