---
name: pdf-studio-initialize-site
description: This skill should be used once, before the first deploy, to set up the shared hosting target for pdf-studio sites — a single Cloudflare Pages project (plus a local library directory under XDG) that books deploy into as subpaths, with a Cloudflare Access policy so the collection is not left public. Triggers on "サイトのセットアップをして", "配信の初期設定", "Pagesプロジェクトを用意して", "initialize the site", "set up hosting", "set up Cloudflare Pages". Should NOT trigger for deploying a book (use pdf-studio-deploy-site), building a book's site (use pdf-studio-generate-site), or once the library already exists (deploy-site handles subsequent deploys).
version: 0.1.0
user-invocable: true
---

# Initialize Site — one-time hosting setup

Set up the **single hosting target** that every pdf-studio book is later published into. Run this **once**; afterward [[pdf-studio-deploy-site]] adds each book as a subpath to the same Cloudflare Pages project, so there is one URL and one Cloudflare Access policy for the whole collection.

Why a shared target: `wrangler pages deploy` replaces a project's entire content each run, and a `*.pages.dev` name is **globally unique across all of Cloudflare** (a taken name gets random characters appended). Deploying each book as its own project would therefore claim a new global name every time and leave the old ones orphaned. Instead, this skill claims one project name and one local **library** directory that accumulates every book; deploys push that whole directory.

The library manager (`library.py`) is owned by the **`pdf-studio-site-base`** skill; this skill runs it and drives wrangler. If `pdf-studio-site-base` is not installed, stop and say so rather than guessing a path.

## What it creates (once)

1. A local library under XDG: `${XDG_DATA_HOME:-$HOME/.local/share}/pdf-studio/`, holding `library.json` (metadata — the project name and book list; never deployed) and `public/` (the deploy root: an index page plus one subdir per book).
2. One **Cloudflare Pages project** with a globally-unique name, recorded in `library.json`.
3. A **Cloudflare Access policy** on that project, enabled while it is still empty — so there is no public window.
4. The first (empty) deploy, to verify the project, URL, and Access all work.

## Prerequisites

- **`wrangler` is an essential prerequisite for this skill — it cannot proceed without it.** Verify it is installed and authenticated: `wrangler whoami`. If it is missing or unauthenticated, stop and have the user set it up (`npm i -g wrangler && wrangler login`), then re-run. Do not attempt a non-wrangler deploy path.
- Not already initialized: `python3 pdf-studio-site-base/scripts/library.py status`. If it prints existing metadata, the library exists — skip this skill and use [[pdf-studio-deploy-site]].

## Procedure

Run wrangler steps **without the command sandbox** (`dangerouslyDisableSandbox: true`); it needs the network and fails under the sandbox with TLS-looking errors.

1. **Choose a globally-unique project name.** `<name>.pages.dev` must be free across all of Cloudflare, so avoid generic words. Propose a distinctive slug (e.g. a personal prefix + short random suffix like `okuno-library-3f9a`), and confirm it with the user. Also ask for a display title for the index (e.g. その人の「書斎」名); default `Reading Library`.
2. **Create the local library:**
   ```sh
   python3 pdf-studio-site-base/scripts/library.py \
     init --project <project> --title "<display title>"
   ```
   This writes `library.json` and an empty `public/index.html`. It refuses if a library already exists (pass `--force` only to deliberately reinitialize).
3. **Create the Pages project:** `wrangler pages project create <project> --production-branch=main`. If wrangler reports the name is taken, the deployed URL would get a random suffix — pick another name and redo steps 1–3 (re-run `library.py init --force --project <new>`).
4. **Protect the production URL with a Self-hosted Access application, before any real content** (dashboard-only — wrangler cannot do this). **Do not rely on the Pages project's Settings → Access policy toggle: it protects only the preview `<hash>.<project>.pages.dev` URLs, NOT the production `<project>.pages.dev`.** To cover production, create an Access application directly:
   - Cloudflare dashboard → **Zero Trust** (`one.dash.cloudflare.com`) → Access → Applications → **Add an application** → **Self-hosted**.
   - Application domain: hostname `<project>.pages.dev` (subdomain field empty). To also lock preview URLs, add a second hostname `*.<project>.pages.dev`.
   - Add a policy: Action **Allow**, Include → **Emails** → the user's address(es). Access is free for up to 50 users. Save.
   Doing this while `public/` is still just an empty index means the site is never publicly readable. Have the user confirm the application and policy exist.
5. **First deploy (empty index) and verify:**
   ```sh
   wrangler pages deploy "$(python3 pdf-studio-site-base/scripts/library.py public)" \
     --project-name=<project>
   ```
   Then `curl -sI https://<project>.pages.dev` — expect a **302 to a Cloudflare Access login** (not 200). A 200 means Access is not active yet; send the user back to step 4 before deploying any book.

Report the production URL and that the library is ready for [[pdf-studio-deploy-site]] to add books.

## Gotchas

- **`.pages.dev` names are globally unique, not per-account.** A generic name will already be taken and silently get a random suffix, so the real URL won't match what you typed. Pick a distinctive name and verify the deployed URL in step 5.
- **The Pages "Access policy" toggle covers previews only — not production.** The toggle under the Pages project's Settings → Access policy protects just the `<hash>.<project>.pages.dev` preview URLs; the production `<project>.pages.dev` stays public. Protect production with a Self-hosted Access application whose hostname is `<project>.pages.dev` (step 4). This is a long-standing Cloudflare behavior, not a recent UI change.
- **Set up Access on the empty project, before adding books.** The project must exist (step 3) before an Access application can target its hostname, but content need not — creating the application between project-create and the first content deploy is what closes the public window entirely. Verify with the curl check in step 5.
- **`library.json` lives outside `public/`** so the project name and book list are never uploaded. Do not move it into `public/`.
- **Do not commit the XDG library to a repo** — it holds the deployable copies of book-derived content. It is machine-local state, not source.

## Success criteria

- [ ] `library.py status` prints metadata with the chosen `project` and an empty `books` list.
- [ ] `wrangler pages project create` succeeded and the deployed URL matches `<project>` (no unexpected random suffix).
- [ ] `curl -sI https://<project>.pages.dev` returns a 302 Access-login redirect, confirming the collection is not public.
- [ ] The user was told the library is initialized and that [[pdf-studio-deploy-site]] adds books to it.
