---
name: explainer-reading-site-deploy
description: "Publish an already-built <WORK_DIR>/site/ to the shared Access-protected Cloudflare Pages library. Use when a local site exists and the user wants it online; use explainer-reading-site-initialize if hosting is not set up."
user-invocable: true
---

# Deploy Site — add a book to the hosted library

Publish a pre-built reading site (`<WORK_DIR>/site/`, from the matching PDF,
EPUB, or paper site consumer) by adding it as a subpath to the shared **library**
created by [[explainer-reading-site-initialize]], then deploying the whole library
to its one Cloudflare Pages project. The book lands at
`https://<project>.pages.dev/<slug>/`; earlier books stay put; the one Cloudflare
Access policy already covers it.

Kept separate from [[book-explainer-generate-site]] and the paper consumer (which
only build `site/`) so generated sites can be reviewed before they go online and
all hosting knowledge lives here.

The library manager (`library.py`) is owned by the **`explainer-reading-site-library-base`** skill; this skill runs it and drives wrangler. If `explainer-reading-site-library-base` is not installed, stop and say so rather than guessing a path.

## When this applies

The inputs are a built `<WORK_DIR>/site/` and an already-initialized library. If
`site/` does not exist, run the source format's site consumer first. If the library
is not set up yet (first ever deploy), run [[explainer-reading-site-initialize]]
first — this skill only adds to an existing library.

## Prerequisites

- The book site exists: `<WORK_DIR>/site/index.html` is present.
- The library is initialized: `python3 explainer-reading-site-library-base/scripts/library.py status --namespace pdf-explainer`. If it prints "not initialized", stop and run [[explainer-reading-site-initialize]] first.
- **`wrangler` is an essential prerequisite — this skill cannot publish without it.** Verify it is authenticated (`wrangler whoami`); if missing or unauthenticated, stop and have the user set it up before re-running. Do not attempt a non-wrangler deploy path.

## Procedure

Run **both `library.py` and wrangler without the command sandbox** (`dangerouslyDisableSandbox: true`). Two different reasons: wrangler needs the network, and `library.py` writes into the XDG library (`~/.local/share/pdf-explainer/`) — **outside the workspace**, which the sandbox denies with a `PermissionError` on `shutil.rmtree`/`copytree`. "Local-only" is not the same as "sandbox-safe": what decides it is *where a command writes*, not whether it touches the network.

`library.py` renders a document-type-neutral index (the deploy root is shared across studios), and the XDG library namespace is caller-chosen via `--namespace` (**it must come after the subcommand**, e.g. `library.py add --namespace pdf-explainer …`). These pdf-explainer skills always pass `--namespace pdf-explainer`, so the library stays at `${XDG_DATA_HOME:-$HOME/.local/share}/pdf-explainer/` exactly as before — no migration.

1. **Decide the book's slug and card text.**
   - `<slug>`: the URL subpath, lowercase `a-z0-9-`, derived from the work dir name. For a Japanese name, propose a romanized slug and confirm it. Reusing an existing slug **replaces** that already-published book in place — so `library.py add` refuses an existing slug unless `--force`. Check `library.py status` first; if the slug is already listed, confirm with the user that they mean to replace the published book before re-running with `--force`.
   - `<title>`: the book's display title (from `reports/overview.md`'s heading).
   - `<desc>`: one line for the library index card — compose a short blurb from the overview's opening (not a copied sentence).
2. **Add the book to the library** (copies `site/` into `public/<slug>/`, records it, and rebuilds the library index):
   ```sh
   python3 explainer-reading-site-library-base/scripts/library.py \
     add --namespace pdf-explainer --slug <slug> --title "<title>" --desc "<desc>" --from "<WORK_DIR>/site"
   ```
   Append `--force` **only** when deliberately replacing an existing slug, after the user confirmed the replace in step 1; without it, `add` stops rather than silently overwriting a published book.
3. **Deploy the whole library** to the recorded project:
   ```sh
   PROJECT=$(python3 explainer-reading-site-library-base/scripts/library.py project --namespace pdf-explainer)
   PUBLIC=$(python3 explainer-reading-site-library-base/scripts/library.py public --namespace pdf-explainer)
   wrangler pages deploy "$PUBLIC" --project-name="$PROJECT"
   ```
4. **Verify and report.** `curl -sI https://<project>.pages.dev/<slug>/` should return a 302 to the Access login (protected) — or 200 only if the user deliberately left Access off. Report the book URL `https://<project>.pages.dev/<slug>/` and the index URL.

## Gotchas

- **`wrangler` needs the network — run it without the command sandbox** (`dangerouslyDisableSandbox: true`). Under the sandbox it fails with TLS/connection errors that look like auth problems.
- **`library.py` also needs the sandbox off, for a different reason.** It never touches the network, but it writes to `~/.local/share/pdf-explainer/` — outside the workspace the sandbox permits — so under the sandbox `add` dies with `PermissionError` while copying `site/` into `public/<slug>/`. Do not read that as a broken script or a bad path; run it unsandboxed.
- **Deploy always targets the whole `public/`, never one book.** `wrangler pages deploy` replaces the project's entire content with the given directory, so deploying a single book's `site/` would wipe every other book. Always deploy the library root from `library.py public`. `library.py add` is what puts the book into that root first.
- **Access is already handled by [[explainer-reading-site-initialize]].** It covers the whole project, so a new subpath is protected automatically — no per-book Access step. If `curl` unexpectedly returns 200, Access was never enabled; point the user to initialize-site step 4.
- **Never report the protection state from a local file.** Access lives in the Cloudflare dashboard; `library.json` does not record it (by design — see [[explainer-reading-site-library-base]]). The only way to know whether the site is protected is to ask the deployed URL, which is what step 4's `curl -sI` does. Telling the user "the site is public" on the strength of a local record is how you hand them a confident falsehood.
- **Regenerate, then redeploy.** The matching PDF, EPUB, or paper consumer rebuilds
  `<WORK_DIR>/site/` from source; this skill copies whatever is there now. Re-run
  that consumer before redeploying a changed book (same slug replaces it in place —
  gated behind a user-confirmed `--force`).
- **Pages limits: 25 MiB per file, 20,000 files across the whole library.** [[explainer-audio-narrate]]'s 64 kbps m4a (~5 MB/10 min) is fine; a hand-added WAV can exceed 25 MiB and the deploy will reject it — re-encode it.

## Success criteria

- [ ] `library.py add` reported the book at `public/<slug>/`, and `library.py status` lists it once (replacing an existing slug went through a user-confirmed `--force`; no duplicate slug).
- [ ] `wrangler pages deploy` targeted the library root (`library.py public`), not the book's own `site/`, so previously deployed books are still present.
- [ ] `curl -sI` against the book URL returned a 302 Access redirect (or 200 only if the user chose to keep the site public), and the state was reported.
- [ ] The book URL `https://<project>.pages.dev/<slug>/` was reported to the user.
