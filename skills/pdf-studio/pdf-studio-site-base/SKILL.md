---
name: pdf-studio-site-base
description: Shared resources for the pdf-studio site skills — the persistent Cloudflare Pages "library" manager (`scripts/library.py`) and the pdf-studio site context layer (`assets/pdf-studio.css`, content styling only), which layers on top of the understanding-html-docs base design system. The reading-site navigation widgets are NOT here — they are understanding-html-docs' `reading-nav` opt-in component. pdf-studio-initialize-site and pdf-studio-deploy-site delegate here to run library.py; pdf-studio-generate-site delegates here for the context asset its report pages share with the library index. Use this skill when another pdf-studio skill asks to run the library manager or copy the context asset. Not typically invoked on its own.
user-invocable: false
---

# pdf-studio site base

Owns the two resources shared across the pdf-studio hosting skills, so there is one source of truth for both and no cross-skill path reference:

- **`scripts/library.py`** — manages the persistent **library**: a single deploy root under `${XDG_DATA_HOME:-$HOME/.local/share}/pdf-studio/` that accumulates every book as a subpath, so one Cloudflare Pages project (and one Access policy) serves the whole collection. Local filesystem + JSON only — no network, no wrangler (the site skills run wrangler themselves). **It writes outside the workspace, so a sandboxed agent must run it with the sandbox off** (under Claude Code: `dangerouslyDisableSandbox: true`); the XDG library is not a path a command sandbox grants write access to, and `init`/`add` die with a `PermissionError` there. Needing no network does not make a command sandbox-safe — *where it writes* is what decides that.
- **`assets/pdf-studio.css`** — the pdf-studio **context layer** of the site design system, **content styling only**. It holds the pdf-studio-specific content components (page anchor, player, hero, cta, index cards, plus the `.hero .lede` tweak); the foundation and Tier 1 reading UI (typography, color model, callouts, chips, tables, pullquote, kicker, lede, keypoints, progressive-enhancement styles) come from the **[[understanding-html-docs]]** base and must be linked first. The reading-site nav *widgets* (the card filter, prev/next, and the all-pages drawer) are **not** here — see below.

The reading-site navigation widgets are owned by the understanding-html-docs **`reading-nav` opt-in component** (`reading-nav.css` / `reading-nav.js`: the live index-card filter, prev/next at the article foot, and a list FAB opening a slide-up **全ページ** drawer, all document-type-neutral). pdf-studio pulls them in through the generator's `--component reading-nav` (and `library.py` copies them for the index). The nav's **single source of truth is still a per-site generated `nav-manifest.js`** (written by `pdf-studio-generate-site` — via the shared reading-site build pipeline — from the fixed page order, assigning `window.__HTMLDOCS_NAV`) — it is data, not a copied design-system asset, so a page list change means regenerating that one file, never touching each page's markup.

`pdf-studio-generate-site` builds its pages through the [[understanding-html-docs]] generator, passing this dir as the generator's `--context` (so `pdf-studio.css` is copied into each built site's `assets/`) and `--component reading-nav` (so the widget bundle is copied alongside `base.css`/`base.js`, which come from `--assets`). `library.py` copies all of them into the library's `public/assets/` for the index page — so the library index and every book page share one visual language and one interaction kit.

The base design system itself (`base.css` / `base.js`) is **not** owned here — it lives in the sibling **[[understanding-html-docs]]** skill, which pdf-studio consumes as a copy-mode base (see that skill's "Consuming this base"). Color carries meaning only: chapters are not color-coded, and anything colored without a meaning uses `--accent`.

## Delegation

Other pdf-studio skills reference these by the base-skill-relative path (all skills install as siblings under the skills root):

- `python3 pdf-studio-site-base/scripts/library.py <subcommand>` — run the library manager.
- `pdf-studio-site-base/assets/pdf-studio.css` — the pdf-studio content context asset to copy into a site's `assets/`.
- `understanding-html-docs/assets/components/reading-nav/reading-nav.css` and `.../reading-nav.js` — the reading-nav widget bundle (pulled in via the generator's `--component reading-nav`).
- `understanding-html-docs/assets/base.css` and `.../base.js` — the base substrate to copy alongside them.

If this base skill (or understanding-html-docs) is not installed, the dependent skill should say so and stop rather than guessing a path — the library layout lives here and the base design system lives in understanding-html-docs by definition. `library.py` resolves `base.css` from the sibling understanding-html-docs skill and falls back to a minimal stylesheet if it is absent.

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

- **Layout it manages:** `<root>/library.json` (metadata — project name and book list; **never deployed**) and `<root>/public/` (the deploy root uploaded whole by wrangler: `index.html`, `assets/{base.css, pdf-studio.css, reading-nav.css, base.js, reading-nav.js}`, and one `<slug>/` per book).
- **`library.json` deliberately does NOT record whether Access is on.** Cloudflare Access is configured in the dashboard; nothing here can set it or read it back, so a local copy could only drift — and a stale flag is worse than no record, because it gets believed and reported as fact. State another system owns is not mirrored here. Ask the live URL instead (`curl -sI` → 302 = protected).
- **`init`** refuses to clobber an existing library unless `--force`; **`add`** copies a `generate-site` `site/` dir into `public/<slug>/` (rejecting a source with no `index.html`), records/updates the book (same slug updates in place), and rebuilds `public/index.html` from `library.json`.
- The script copies `base.css`/`base.js` and the `reading-nav` component (`reading-nav.css`/`reading-nav.js`) from the sibling **understanding-html-docs** skill, plus its own bundled `pdf-studio.css`, into `public/assets/`; if `base.css` is somehow missing it falls back to a minimal readable stylesheet so the index still renders, and a missing PE script is skipped (its `<script>` 404s silently — the index stays readable). The rendered index carries the theme toggle and the card filter as progressive enhancement, like every book page.
