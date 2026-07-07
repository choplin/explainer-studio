---
name: pdf-studio-deploy-site
description: This skill should be used when the user wants to publish an already-generated pdf-studio book site (a <WORK_DIR>/site/ dir) to the internet — adding it as a subpath to the shared Cloudflare Pages library set up by pdf-studio-initialize-site, then deploying so it is reachable (Access-protected) from a phone. Triggers on "サイトをデプロイして", "この本を公開して", "ホストして", "ネットで読めるようにして", "deploy the site", "publish this book", "put it online". Should NOT trigger for the one-time hosting setup (use pdf-studio-initialize-site first), for building the site (use pdf-studio-generate-site), for producing reports (use pdf-studio-summarize / pdf-studio-deep-dive), or for the audio guide (use pdf-studio-audio-dialogue / pdf-studio-audio-narrate).
version: 0.2.0
user-invocable: true
---

# Deploy Site — add a book to the hosted library

Publish a pre-built book site (`<WORK_DIR>/site/`, from [[pdf-studio-generate-site]]) by adding it as a subpath to the shared **library** created by [[pdf-studio-initialize-site]], then deploying the whole library to its one Cloudflare Pages project. The book lands at `https://<project>.pages.dev/<slug>/`; earlier books stay put; the one Cloudflare Access policy already covers it.

Kept separate from [[pdf-studio-generate-site]] (which only builds `site/`) so the generated site can be reviewed before it goes online, and so all hosting knowledge lives here.

The library manager (`library.py`) is owned by the **`pdf-studio-site-base`** skill; this skill runs it and drives wrangler. If `pdf-studio-site-base` is not installed, stop and say so rather than guessing a path.

## When this applies

The inputs are a built `<WORK_DIR>/site/` and an already-initialized library. If `site/` does not exist, run [[pdf-studio-generate-site]] first. If the library is not set up yet (first ever deploy), run [[pdf-studio-initialize-site]] first — this skill only adds to an existing library.

## Prerequisites

- The book site exists: `<WORK_DIR>/site/index.html` is present.
- The library is initialized: `python3 pdf-studio-site-base/scripts/library.py status`. If it prints "not initialized", stop and run [[pdf-studio-initialize-site]] first.
- **`wrangler` is an essential prerequisite — this skill cannot publish without it.** Verify it is authenticated (`wrangler whoami`); if missing or unauthenticated, stop and have the user set it up before re-running. Do not attempt a non-wrangler deploy path.

## Procedure

Run wrangler **without the command sandbox** (`dangerouslyDisableSandbox: true`) — it needs the network. The `library.py` steps are local-only and need no special handling.

1. **Decide the book's slug and card text.**
   - `<slug>`: the URL subpath, lowercase `a-z0-9-`, derived from the work dir name. For a Japanese name, propose a romanized slug and confirm it. Reusing an existing slug **updates** that book in place (intended for re-deploying a regenerated site).
   - `<title>`: the book's display title (from `reports/overview.md`'s heading).
   - `<desc>`: one line for the library index card — compose a short blurb from the overview's opening (not a copied sentence).
2. **Add the book to the library** (copies `site/` into `public/<slug>/`, records it, and rebuilds the library index):
   ```sh
   python3 pdf-studio-site-base/scripts/library.py \
     add --slug <slug> --title "<title>" --desc "<desc>" --from "<WORK_DIR>/site"
   ```
3. **Deploy the whole library** to the recorded project:
   ```sh
   PROJECT=$(python3 pdf-studio-site-base/scripts/library.py project)
   PUBLIC=$(python3 pdf-studio-site-base/scripts/library.py public)
   wrangler pages deploy "$PUBLIC" --project-name="$PROJECT"
   ```
4. **Verify and report.** `curl -sI https://<project>.pages.dev/<slug>/` should return a 302 to the Access login (protected) — or 200 only if the user deliberately left Access off. Report the book URL `https://<project>.pages.dev/<slug>/` and the index URL.

## Gotchas

- **`wrangler` needs the network — run it without the command sandbox** (`dangerouslyDisableSandbox: true`). Under the sandbox it fails with TLS/connection errors that look like auth problems.
- **Deploy always targets the whole `public/`, never one book.** `wrangler pages deploy` replaces the project's entire content with the given directory, so deploying a single book's `site/` would wipe every other book. Always deploy the library root from `library.py public`. `library.py add` is what puts the book into that root first.
- **Access is already handled by [[pdf-studio-initialize-site]].** It covers the whole project, so a new subpath is protected automatically — no per-book Access step. If `curl` unexpectedly returns 200, Access was never enabled; point the user to initialize-site step 4.
- **Regenerate, then redeploy.** [[pdf-studio-generate-site]] rewrites `<WORK_DIR>/site/` in place; this skill copies whatever is there now. Re-run [[pdf-studio-generate-site]] before redeploying a changed book (same slug updates it in place).
- **Pages limits: 25 MiB per file, 20,000 files across the whole library.** [[pdf-studio-audio-narrate]]'s 64 kbps m4a (~5 MB/10 min) is fine; a hand-added WAV can exceed 25 MiB and the deploy will reject it — re-encode it.

## Success criteria

- [ ] `library.py add` reported the book at `public/<slug>/`, and `library.py status` lists it once (a re-deploy updates in place, no duplicate slug).
- [ ] `wrangler pages deploy` targeted the library root (`library.py public`), not the book's own `site/`, so previously deployed books are still present.
- [ ] `curl -sI` against the book URL returned a 302 Access redirect (or 200 only if the user chose to keep the site public), and the state was reported.
- [ ] The book URL `https://<project>.pages.dev/<slug>/` was reported to the user.
