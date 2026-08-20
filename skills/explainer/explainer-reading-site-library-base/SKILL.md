---
name: explainer-reading-site-library-base
description: "Internal resource package invoked by reading-site initialize, deploy, and generate flows. Provides the persistent Cloudflare library manager and shared reading-site context assets."
user-invocable: false
---

# Reading-site library base

Owns the three resources shared across the reading-site skills, so there is one
source of truth for each and no cross-skill path reference:

- **`scripts/library.py`** — manages a persistent, document-type-neutral **library**: one deploy root accumulates documents as subpaths, so one Cloudflare Pages project (and one Access policy) can serve the whole collection. The namespace is selected with `--namespace <name>` (or `LIBRARY_NAMESPACE`); it defaults to `pdf-explainer`, preserving the existing `${XDG_DATA_HOME:-$HOME/.local/share}/pdf-explainer/` library. Local filesystem + JSON only — no network, no wrangler (the site skills run wrangler themselves). **It writes outside the workspace, so a sandboxed agent must run it with the sandbox off** (under Claude Code: `dangerouslyDisableSandbox: true`); the XDG library is not a path a command sandbox grants write access to, and `init`/`add` die with a `PermissionError` there. Needing no network does not make a command sandbox-safe — *where it writes* is what decides that.
- **`assets/reading-site.css`** — the shared **context layer** of the reading-site design system, **content styling only**. It holds reading-site content components (source anchors, player, hero, cta, index cards, plus the `.hero .lede` tweak); the foundation and Tier 1 reading UI (typography, color model, callouts, chips, tables, pullquote, kicker, lede, keypoints, progressive-enhancement styles) come from the **[[explainer-html-docs]]** base and must be linked first. The reading-site nav *widgets* (the card filter, prev/next, and the all-pages drawer) are **not** here — see below.
- **`filters/reading-site.lua`** — binds reading-site structure provenance. It
  expands `.editorial-structure` headings into a visible disclosure plus a
  subdued real-text origin marker, so the article and generated TOC/sidebar retain
  the same attribution without competing with the heading. `.source-structure`
  headings remain the source-derived layer.

The reading-site navigation widgets are owned by the explainer-html-docs **`reading-nav` opt-in component** (`reading-nav.css` / `reading-nav.js`: the live index-card filter, prev/next at the article foot, and a list FAB opening a slide-up **全ページ** drawer, all document-type-neutral). Book and paper consumers pull them in through the generator's `--component reading-nav` (and `library.py` copies them for the index). The nav's **single source of truth is still a per-site generated `nav-manifest.js`** (written via the shared reading-site build pipeline from the fixed page order, assigning `window.__HTMLDOCS_NAV`) — it is data, not a copied design-system asset, so a page list change means regenerating that one file, never touching each page's markup.

[[book-explainer-generate-site]] and the paper consumer build pages through the
[[explainer-html-docs]] generator, passing this directory as `--context`, its
filter as `--filter`, and `--component reading-nav`. `library.py` copies the same
assets into the library index, so every reading site shares one visual language
and interaction kit.

The base design system itself (`base.css` / `base.js`) is **not** owned here — it lives in the sibling **[[explainer-html-docs]]** skill, which pdf-explainer consumes as a copy-mode base (see that skill's "Consuming this base"). Color carries meaning only: chapters are not color-coded, and anything colored without a meaning uses `--accent`.

## Delegation

Reading-site consumers reference these by the base-skill-relative path (all skills install as siblings under the skills root):

- `python3 explainer-reading-site-library-base/scripts/library.py <subcommand> [--namespace <name>]` — run the library manager. The option follows the subcommand; omit it for the compatible `pdf-explainer` default.
- `explainer-reading-site-library-base/assets/reading-site.css` — the shared content context asset to copy into a site's `assets/`.
- `explainer-reading-site-library-base/filters/reading-site.lua` — the
  source/editorial structure-provenance filter passed to the generator.
- `explainer-html-docs/assets/components/reading-nav/reading-nav.css` and `.../reading-nav.js` — the reading-nav widget bundle (pulled in via the generator's `--component reading-nav`).
- `explainer-html-docs/assets/base.css` and `.../base.js` — the base substrate to copy alongside them.

If this base skill (or explainer-html-docs) is not installed, the dependent skill should say so and stop rather than guessing a path — the library layout lives here and the base design system lives in explainer-html-docs by definition. `library.py` resolves `base.css` from the sibling explainer-html-docs skill and falls back to a minimal stylesheet if it is absent.

## library.py subcommands

```
path                       print the library root
status                     print library.json (or a not-initialized notice)
project                    print the recorded Cloudflare Pages project name
public                     print the deploy root (<root>/public)
init --project NAME [--title T] [--force]
                           create the library and an empty index
add --slug S --title T [--desc D] --from DIR
                           copy DIR into public/<S>/, record it, rebuild index
```

- **Layout it manages:** `<root>/library.json` (metadata — project name and book list; **never deployed**) and `<root>/public/` (the deploy root uploaded whole by wrangler: `index.html`, `assets/{base.css, reading-site.css, reading-nav.css, base.js, reading-nav.js}`, and one `<slug>/` per book).
- **`library.json` deliberately does NOT record whether Access is on.** Cloudflare Access is configured in the dashboard; nothing here can set it or read it back, so a local copy could only drift — and a stale flag is worse than no record, because it gets believed and reported as fact. State another system owns is not mirrored here. Ask the live URL instead (`curl -sI` → 302 = protected).
- **`init`** refuses to clobber an existing library unless `--force`; **`add`** copies a `generate-site` `site/` dir into `public/<slug>/` (rejecting a source with no `index.html`), records/updates the book (same slug updates in place), and rebuilds `public/index.html` from `library.json`.
- The script copies `base.css`/`base.js` and the `reading-nav` component (`reading-nav.css`/`reading-nav.js`) from the sibling **explainer-html-docs** skill, plus its own bundled `reading-site.css`, into `public/assets/`; if `base.css` is somehow missing it falls back to a minimal readable stylesheet so the index still renders, and a missing PE script is skipped (its `<script>` 404s silently — the index stays readable). The rendered index carries the theme toggle and the card filter as progressive enhancement, like every book page.
