---
name: pdf-studio-site-base
description: Shared resources for the pdf-studio site skills — the persistent Cloudflare Pages "library" manager (`scripts/library.py`) and the pdf-studio site context layer (`assets/pdf-studio.css` + `assets/pdf-studio.js`), which layers on top of the understanding-html-docs base design system. pdf-studio-initialize-site and pdf-studio-deploy-site delegate here to run library.py; pdf-studio-generate-site delegates here for the context assets its report pages share with the library index. Use this skill when another pdf-studio skill asks to run the library manager or copy the context assets. Not typically invoked on its own.
user-invocable: false
---

# pdf-studio site base

Owns the two resources shared across the pdf-studio hosting skills, so there is one source of truth for both and no cross-skill path reference:

- **`scripts/library.py`** — manages the persistent **library**: a single deploy root under `${XDG_DATA_HOME:-$HOME/.local/share}/pdf-studio/` that accumulates every book as a subpath, so one Cloudflare Pages project (and one Access policy) serves the whole collection. Local filesystem + JSON only — no network, no wrangler (the site skills run wrangler themselves). **It writes outside the workspace, so a sandboxed agent must run it with the sandbox off** (under Claude Code: `dangerouslyDisableSandbox: true`); the XDG library is not a path a command sandbox grants write access to, and `init`/`add` die with a `PermissionError` there. Needing no network does not make a command sandbox-safe — *where it writes* is what decides that.
- **`assets/pdf-studio.css`** — the pdf-studio **context layer** of the site design system. It holds only the pdf-studio-specific components (page anchor, player, chapnav, hero, cta, chapter cards, index filter, plus the `.hero .lede` tweak); the foundation and Tier 1 reading UI (typography, color model, callouts, chips, tables, pullquote, kicker, lede, keypoints, progressive-enhancement styles) come from the **[[understanding-html-docs]]** base and must be linked first.
- **`assets/pdf-studio.js`** — the pdf-studio **context enhancement**: the live filter over chapter/book cards, and the **manifest-driven page-to-page navigation** (prev/next at the article foot, plus a list FAB (three horizontal lines) opening a slide-up **全ページ** drawer with the current page highlighted — a different axis from base.js's ☰ section TOC: pages vs sections; both rendered at runtime from `window.__PDF_STUDIO_NAV`). The FAB stack and the drawer are aligned to the article's column (not the viewport corner/full width) so they sit beside the content on wide screens. It runs alongside the base PE kit (`base.js`) and enhances both the generate-site landing page and the library index. Vanilla JS, no dependencies; each block no-ops when its markup/manifest is absent, and the page is fully readable without it. The nav's **single source of truth is a per-site generated `nav-manifest.js`** (written by `pdf-studio-generate-site` Phase 3 from the fixed page order) — it is data, not one of the four copied assets, so a page list change means regenerating that one file, never touching each page's markup.

`pdf-studio-generate-site` builds its pages through the [[understanding-html-docs-generate]] generator, passing this dir as the generator's `--context` — so both context files are copied into each built site's `assets/` next to `base.css`/`base.js` (the base substrate the generator copies from its `--assets`). `library.py` copies all four into the library's `public/assets/` for the index page — so the library index and every book page share one visual language and one interaction kit.

The base design system itself (`base.css` / `base.js`) is **not** owned here — it lives in the sibling **[[understanding-html-docs]]** skill, which pdf-studio consumes as a copy-mode base (see that skill's "Consuming this base"). Color carries meaning only: chapters are not color-coded, and anything colored without a meaning uses `--accent`.

## Delegation

Other pdf-studio skills reference these by the base-skill-relative path (all skills install as siblings under the skills root):

- `python3 pdf-studio-site-base/scripts/library.py <subcommand>` — run the library manager.
- `pdf-studio-site-base/assets/pdf-studio.css` and `.../pdf-studio.js` — the context assets to copy into a site's `assets/`.
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

- **Layout it manages:** `<root>/library.json` (metadata — project name and book list; **never deployed**) and `<root>/public/` (the deploy root uploaded whole by wrangler: `index.html`, `assets/{base.css, pdf-studio.css, base.js, pdf-studio.js}`, and one `<slug>/` per book).
- **`library.json` deliberately does NOT record whether Access is on.** Cloudflare Access is configured in the dashboard; nothing here can set it or read it back, so a local copy could only drift — and a stale flag is worse than no record, because it gets believed and reported as fact. State another system owns is not mirrored here. Ask the live URL instead (`curl -sI` → 302 = protected).
- **`init`** refuses to clobber an existing library unless `--force`; **`add`** copies a `generate-site` `site/` dir into `public/<slug>/` (rejecting a source with no `index.html`), records/updates the book (same slug updates in place), and rebuilds `public/index.html` from `library.json`.
- The script copies `base.css`/`base.js` from the sibling **understanding-html-docs** skill and its own bundled `pdf-studio.css`/`pdf-studio.js` into `public/assets/`; if `base.css` is somehow missing it falls back to a minimal readable stylesheet so the index still renders, and a missing PE script is skipped (its `<script>` 404s silently — the index stays readable). The rendered index carries the theme toggle and the card filter as progressive enhancement, like every book page.
