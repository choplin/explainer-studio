---
name: pdf-studio-site-base
description: Shared resources for the pdf-studio site skills — the persistent Cloudflare Pages "library" manager (`scripts/library.py`) and the pdf-studio site context layer (`assets/pdf-studio.css` + `assets/pdf-studio.js`), which layers on top of the understanding-html-docs base design system. pdf-studio-initialize-site and pdf-studio-deploy-site delegate here to run library.py; pdf-studio-generate-site delegates here for the context assets its report pages share with the library index. Use this skill when another pdf-studio skill asks to run the library manager or copy the context assets. Not typically invoked on its own.
version: 0.2.0
user-invocable: false
---

# pdf-studio site base

Owns the two resources shared across the pdf-studio hosting skills, so there is one source of truth for both and no cross-skill path reference:

- **`scripts/library.py`** — manages the persistent **library**: a single deploy root under `${XDG_DATA_HOME:-$HOME/.local/share}/pdf-studio/` that accumulates every book as a subpath, so one Cloudflare Pages project (and one Access policy) serves the whole collection. Local filesystem + JSON only — no network, no wrangler (the site skills run wrangler themselves).
- **`assets/pdf-studio.css`** — the pdf-studio **context layer** of the site design system. It holds only the pdf-studio-specific components (kicker, lede, keypoints, page anchor, player, chapnav, hero, cta, chapter cards, index filter); the foundation (typography, color model, callouts, chips, tables, pullquote, progressive-enhancement styles) comes from the **[[understanding-html-docs]]** base and must be linked first.
- **`assets/pdf-studio.js`** — the pdf-studio **context enhancement**: the live filter over chapter/book cards. It runs alongside the base PE kit (`base.js`) and enhances both the generate-site landing page and the library index. Vanilla JS, no dependencies; the page is fully readable without it.

`pdf-studio-generate-site` copies both context files into each built site's `assets/` next to `base.css`/`base.js`, and `library.py` copies all four into the library's `public/assets/` for the index page — so the library index and every book page share one visual language and one interaction kit.

The base design system itself (`base.css` / `base.js`) is **not** owned here — it lives in the sibling **[[understanding-html-docs]]** skill, which pdf-studio consumes as a copy-mode base (see that skill's "Consuming this base"). The categorical wayfinding variable is `--cat`/`--cat-soft` (set by base.css's `hue-N`); pdf-studio.css does not redefine the hues.

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

- **Layout it manages:** `<root>/library.json` (metadata — project name, book list, access flag; **never deployed**) and `<root>/public/` (the deploy root uploaded whole by wrangler: `index.html`, `assets/{base.css, pdf-studio.css, base.js, pdf-studio.js}`, and one `<slug>/` per book).
- **`init`** refuses to clobber an existing library unless `--force`; **`add`** copies a `generate-site` `site/` dir into `public/<slug>/` (rejecting a source with no `index.html`), records/updates the book (same slug updates in place), and rebuilds `public/index.html` from `library.json`.
- The script copies `base.css`/`base.js` from the sibling **understanding-html-docs** skill and its own bundled `pdf-studio.css`/`pdf-studio.js` into `public/assets/`; if `base.css` is somehow missing it falls back to a minimal readable stylesheet so the index still renders, and a missing PE script is skipped (its `<script>` 404s silently — the index stays readable). The rendered index carries the theme toggle and the card filter as progressive enhancement, like every book page.
