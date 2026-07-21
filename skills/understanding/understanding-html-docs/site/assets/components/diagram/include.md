# `diagram` component — render diagrams with mermaid

A **Tier 2 opt-in component** of the understanding-html-docs design system (see
`docs/components.md`). Include it only in a
document that shows diagrams — a consumer with no diagrams never copies this
folder and never loads mermaid.

**Third-party engine:** [mermaid](https://mermaid.js.org/) v11, imported from a
CDN inside `diagram.js`. This component **assumes an online viewer** for the
diagram rendering — the base substrate still works offline; only the diagram
render here needs the network. To run fully offline, vendor the mermaid ESM
build locally and change the `import` in `diagram.js` to point at it (the offline
opt-in).

## Files

- `diagram.css` — makes `pre.mermaid` blocks transparent and centered so they sit
  on the page background in both themes.
- `diagram.js` — imports and initializes mermaid; resolves the document theme.

## How to include

Copy-mode (multi-page site):

```html
<!-- in <head>, after base.css -->
<link rel="stylesheet" href="assets/diagram.css">
<script type="module" src="assets/diagram.js"></script>
```

Inline-mode (single self-contained file, e.g. explain-diff): paste `diagram.css`
into a `<style>` block after the base stylesheet, and paste `diagram.js` into a
`<script type="module">` in `<head>`. Only the mermaid CDN `import` stays
external.

`diagram.js` imports the `mermaid@11` major range (exact pinning is not required
here); vendor the ESM build locally if you need the offline opt-in.

## Markup contract

One `<pre class="mermaid">` per diagram, holding mermaid source:

```html
<pre class="mermaid">
flowchart LR
  A["existing"] --> B["new step"]:::added
  A --> C["old step"]:::removed
  classDef added   stroke:#3ca370,stroke-width:2px;
  classDef removed stroke:#d93526,stroke-width:2px,stroke-dasharray:4 3;
  classDef changed stroke:#e8a13c,stroke-width:2px;
</pre>
```

- **Quote node labels** that contain spaces or punctuation (`A["new step"]`), or
  mermaid fails to parse them.

## Palette hook (base-owned) vs. meaning (consumer-owned)

mermaid `classDef` strokes cannot read CSS custom properties, so the base
provides a **recommended stroke set** that matches the design system's semantic
hues (theme-agnostic mid-tones that read on both light and dark backgrounds):

| Hook | Stroke | Aligns with base hue |
|------|--------|----------------------|
| green  | `#3ca370` | `--tip` |
| red    | `#d93526` | `--bad` |
| amber  | `#e8a13c` | `--warn` |

That is the palette hook the base owns. **Which change-role gets which hue is the
consuming skill's decision** (e.g. explain-diff maps added→green, removed→red,
changed→amber to speak its risk/change language). Use stroke-only classDefs so
nodes read in both themes; prefer prose over inventing a hue the set can't
express.
