---
name: pdf-studio-site-base
description: Shared resources for the pdf-studio site skills — the persistent Cloudflare Pages "library" manager (`scripts/library.py`) and the shared site design system (`assets/style.css`). pdf-studio-initialize-site and pdf-studio-deploy-site delegate here to run library.py; pdf-studio-generate-site delegates here for the stylesheet its report pages share with the library index. Use this skill when another pdf-studio skill asks to run the library manager or copy the shared stylesheet. Not typically invoked on its own.
version: 0.1.0
user-invocable: false
---

# pdf-studio site base

Owns the two resources shared across the pdf-studio hosting skills, so there is one source of truth for both and no cross-skill path reference:

- **`scripts/library.py`** — manages the persistent **library**: a single deploy root under `${XDG_DATA_HOME:-$HOME/.local/share}/pdf-studio/` that accumulates every book as a subpath, so one Cloudflare Pages project (and one Access policy) serves the whole collection. Local filesystem + JSON only — no network, no wrangler (the site skills run wrangler themselves).
- **`assets/style.css`** — the shared site design system. `pdf-studio-generate-site` copies it into each built site's `assets/`, and `library.py` copies it into the library's `public/assets/` for the index page — so the library index and every book page share one visual language.

## Delegation

Other pdf-studio skills reference these by the base-skill-relative path (all skills install as siblings under the skills root):

- `python3 pdf-studio-site-base/scripts/library.py <subcommand>` — run the library manager.
- `pdf-studio-site-base/assets/style.css` — the stylesheet to copy into a site's `assets/`.

If this base skill is not installed, the dependent skill should say so and stop rather than guessing a path — the library layout and the design system live here by definition.

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

- **Layout it manages:** `<root>/library.json` (metadata — project name, book list, access flag; **never deployed**) and `<root>/public/` (the deploy root uploaded whole by wrangler: `index.html`, `assets/style.css`, and one `<slug>/` per book).
- **`init`** refuses to clobber an existing library unless `--force`; **`add`** copies a `generate-site` `site/` dir into `public/<slug>/` (rejecting a source with no `index.html`), records/updates the book (same slug updates in place), and rebuilds `public/index.html` from `library.json`.
- The script copies its own bundled `assets/style.css` into `public/assets/`; if that file is somehow missing it falls back to a minimal readable stylesheet so the index still renders.
