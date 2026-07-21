#!/usr/bin/env python3
"""Manage the pdf-studio site library under $XDG_DATA_HOME/pdf-studio.

The library is a single, persistent deploy root that accumulates books as
subpaths, so one Cloudflare Pages project (and one Access policy) serves the
whole collection. This script does only local filesystem + JSON work — no
network, no wrangler. The skills run wrangler separately.

Layout:
  <root>/                       $XDG_DATA_HOME/pdf-studio (or ~/.local/share/...)
  ├── library.json              metadata (NOT deployed): project, books
  └── public/                   the deploy root (uploaded whole by wrangler)
      ├── index.html            library index, rebuilt from library.json
      ├── assets/base.css       shared base design system (from understanding-html-docs)
      ├── assets/pdf-studio.css pdf-studio content layer (from pdf-studio-site-base)
      ├── assets/reading-nav.css reading-nav widget chrome (from understanding-html-docs component)
      ├── assets/base.js        base PE kit: theme toggle, back-to-top (from understanding-html-docs)
      ├── assets/reading-nav.js card live filter + page nav (from understanding-html-docs component)
      └── <slug>/               one book's authored site (copied from a work dir)

Subcommands:
  path                          print the library root
  status                        print library.json (or a not-initialized notice)
  project                       print the recorded Cloudflare Pages project name
  public                        print the deploy root (<root>/public)
  init --project NAME [--title T] [--force]
                                create the library and an empty index
  add --slug S --title T [--desc D] --from DIR [--force]
                                copy DIR into public/<S>/, record it, rebuild index
                                (refuses to replace an existing slug without --force)
"""

import argparse
import datetime
import html
import json
import os
import re
import shutil
import sys
from pathlib import Path

SLUG_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")


def root():
    base = os.environ.get("XDG_DATA_HOME") or os.path.join(
        os.path.expanduser("~"), ".local", "share"
    )
    return Path(base) / "pdf-studio"


def meta_path():
    return root() / "library.json"


def public_dir():
    return root() / "public"


def load_meta():
    p = meta_path()
    if not p.exists():
        sys.exit(
            "error: library not initialized (%s missing). Run the initialize-site "
            "skill first." % p
        )
    return json.loads(p.read_text(encoding="utf-8"))


def save_meta(meta):
    meta_path().write_text(
        json.dumps(meta, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )


def base_css_source():
    # The shared base design system, owned by the sibling understanding-html-docs
    # skill (skills install as flat siblings under the skills root):
    # <root>/pdf-studio-site-base/scripts/library.py
    #   -> <root>/understanding-html-docs/assets/base.css
    return (
        Path(__file__).resolve().parents[2]
        / "understanding-html-docs"
        / "assets"
        / "base.css"
    )


def context_css_source():
    # This skill's own pdf-studio context layer, applied on top of base.css:
    # pdf-studio-site-base/scripts/library.py -> pdf-studio-site-base/assets/pdf-studio.css
    return Path(__file__).resolve().parents[1] / "assets" / "pdf-studio.css"


def base_js_source():
    # The base progressive-enhancement kit (theme toggle, back-to-top, etc.),
    # owned by the sibling understanding-html-docs skill:
    # <root>/pdf-studio-site-base/scripts/library.py
    #   -> <root>/understanding-html-docs/assets/base.js
    return (
        Path(__file__).resolve().parents[2]
        / "understanding-html-docs"
        / "assets"
        / "base.js"
    )


def reading_nav_css_source():
    # The reading-nav widget chrome, owned by the sibling understanding-html-docs
    # skill as an opt-in component (the card filter / page-nav styling):
    # <root>/pdf-studio-site-base/scripts/library.py
    #   -> <root>/understanding-html-docs/assets/components/reading-nav/reading-nav.css
    return (
        Path(__file__).resolve().parents[2]
        / "understanding-html-docs"
        / "assets"
        / "components"
        / "reading-nav"
        / "reading-nav.css"
    )


def reading_nav_js_source():
    # The reading-nav enhancement (the card live filter; the page nav no-ops on the
    # index, which carries no nav manifest), shared by the generate-site landing page
    # and this library index. Owned by understanding-html-docs as an opt-in component:
    #   -> <root>/understanding-html-docs/assets/components/reading-nav/reading-nav.js
    return (
        Path(__file__).resolve().parents[2]
        / "understanding-html-docs"
        / "assets"
        / "components"
        / "reading-nav"
        / "reading-nav.js"
    )


def today():
    return datetime.date.today().isoformat()


# ---------------------------------------------------------------- index render

# Progressive-enhancement scripts for the index (theme toggle from base.js, card
# live filter from the reading-nav component's reading-nav.js). Passed to INDEX as a
# preformatted value so its `{`/`}` JS braces never reach str.format(). The boot
# snippet's storage key must match base.js's THEME_KEY; it applies the saved theme
# before first paint.
INDEX_SCRIPTS = (
    "<script>try{var t=localStorage.getItem('html-docs-theme');"
    "if(t==='dark')document.documentElement.classList.add('theme-dark');"
    "else if(t==='light')document.documentElement.classList.add('theme-light');}"
    "catch(e){}</script>\n"
    '<script src="assets/base.js" defer></script>\n'
    '<script src="assets/reading-nav.js" defer></script>'
)

INDEX = """\
<!DOCTYPE html>
<html lang="ja">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="generator" content="pdf-studio">
<title>{title}</title>
<link rel="stylesheet" href="assets/base.css">
<link rel="stylesheet" href="assets/pdf-studio.css">
<link rel="stylesheet" href="assets/reading-nav.css">
{scripts}
</head>
<body>
<main>
  <div class="hero">
    <p class="kicker">蔵書</p>
    <h1>{title}</h1>
    <p class="lede">{lede}</p>
    <div class="meta"><span class="chip">{count}冊</span></div>
  </div>
{body}
</main>
<footer>Generated by pdf-studio</footer>
</body>
</html>
"""


def render_index(meta):
    books = meta.get("books", [])
    title = html.escape(meta.get("title") or "Reading Library")
    if books:
        lede = "これまでに読んだ本のガイド。各カードから本文と音声ガイドを開けます。"
        # data-reading-filter opts this index into the reading-nav live filter
        # (empty attribute = neutral placeholder).
        cards = ['<ol class="cards" data-reading-filter>']
        for b in books:
            slug = html.escape(b["slug"])
            bt = html.escape(b.get("title") or b["slug"])
            desc = html.escape(b.get("desc") or "")
            chip = '<span class="chip">🔊 音声ガイドあり</span>' if b.get("audio") else ""
            cards.append(
                '  <li><a href="%s/"><span class="t">%s</span>'
                '<span class="s">%s</span>%s</a></li>' % (slug, bt, desc, chip)
            )
        cards.append("</ol>")
        body = "\n".join(cards)
    else:
        lede = "まだ本がありません。deploy-site スキルで本を追加してください。"
        body = "  <p>（蔵書は空です）</p>"
    return INDEX.format(
        title=title,
        lede=html.escape(lede),
        count=len(books),
        body=body,
        scripts=INDEX_SCRIPTS,
    )


def write_public_scaffold(meta):
    pub = public_dir()
    assets = pub / "assets"
    assets.mkdir(parents=True, exist_ok=True)

    base = base_css_source()
    if base.exists():
        shutil.copy2(base, assets / "base.css")
    else:
        # Fallback: minimal readable stylesheet if understanding-html-docs is not
        # installed as a sibling, so the index still renders.
        (assets / "base.css").write_text(
            "body{font-family:sans-serif;max-width:45rem;margin:0 auto;padding:1rem;}",
            encoding="utf-8",
        )

    ctx = context_css_source()
    if ctx.exists():
        shutil.copy2(ctx, assets / "pdf-studio.css")
    else:
        # The context layer is optional styling; an empty file keeps the link valid.
        (assets / "pdf-studio.css").write_text("", encoding="utf-8")

    rn_css = reading_nav_css_source()
    if rn_css.exists():
        shutil.copy2(rn_css, assets / "reading-nav.css")
    else:
        # The widget chrome is optional styling; an empty file keeps the link valid.
        (assets / "reading-nav.css").write_text("", encoding="utf-8")

    # Progressive-enhancement scripts. They are optional (the index is fully
    # readable without them), so a missing source is simply skipped — the tag
    # 404s silently rather than breaking the page.
    for src, name in ((base_js_source(), "base.js"), (reading_nav_js_source(), "reading-nav.js")):
        if src.exists():
            shutil.copy2(src, assets / name)

    (pub / "index.html").write_text(render_index(meta), encoding="utf-8")


# ---------------------------------------------------------------- commands


def cmd_init(args):
    if not SLUG_RE.match(args.project):
        sys.exit("error: project name must be lowercase a-z0-9- (got %r)" % args.project)
    mp = meta_path()
    if mp.exists() and not args.force:
        existing = json.loads(mp.read_text(encoding="utf-8"))
        sys.exit(
            "error: library already initialized (project %r at %s). Use --force to "
            "reinitialize." % (existing.get("project"), root())
        )
    root().mkdir(parents=True, exist_ok=True)
    # No `access` field: Cloudflare Access is configured in the dashboard, and
    # nothing here can set it or read it back. A local mirror of state another
    # system owns can only ever drift — and a stale `"access": false` is worse
    # than no record, because it gets believed. The live URL is the only source
    # of truth (`curl -sI` → 302 = protected); the deploy skill checks it there.
    meta = {
        "project": args.project,
        "title": args.title or "Reading Library",
        "created": today(),
        "books": [],
    }
    save_meta(meta)
    write_public_scaffold(meta)
    print("library root: %s" % root())
    print("deploy root:  %s" % public_dir())
    print("project:      %s" % args.project)


def cmd_add(args):
    if not SLUG_RE.match(args.slug):
        sys.exit("error: slug must be lowercase a-z0-9- (got %r)" % args.slug)
    meta = load_meta()
    src = Path(args.src).resolve()
    if not (src / "index.html").is_file():
        sys.exit("error: --from %s has no index.html (point it at a generate-site site/ dir)" % src)

    dest = public_dir() / args.slug
    existing = dest.exists() or any(b["slug"] == args.slug for b in meta.get("books", []))
    if existing and not args.force:
        sys.exit(
            "error: a book with slug %r is already in the library; re-adding replaces its "
            "published files and index card in place. Pass --force to confirm the replace." % args.slug
        )
    if dest.exists():
        shutil.rmtree(dest)
    shutil.copytree(src, dest)
    has_audio = (dest / "audio").is_dir() and any((dest / "audio").iterdir())

    books = [b for b in meta.get("books", []) if b["slug"] != args.slug]
    replaced = len(books) != len(meta.get("books", []))
    books.append(
        {
            "slug": args.slug,
            "title": args.title,
            "desc": args.desc or "",
            "audio": has_audio,
            "added": today(),
        }
    )
    # Keep a stable order: most-recently-added last.
    meta["books"] = books
    save_meta(meta)
    write_public_scaffold(meta)

    print("%s book %r at public/%s/" % ("updated" if replaced else "added", args.title, args.slug))
    print("url path: /%s/" % args.slug)
    print("deploy root: %s" % public_dir())


def main():
    ap = argparse.ArgumentParser(description="Manage the pdf-studio site library.")
    sub = ap.add_subparsers(dest="cmd", required=True)

    sub.add_parser("path")
    sub.add_parser("status")
    sub.add_parser("project")
    sub.add_parser("public")

    pi = sub.add_parser("init")
    pi.add_argument("--project", required=True)
    pi.add_argument("--title")
    pi.add_argument("--force", action="store_true")

    pa = sub.add_parser("add")
    pa.add_argument("--slug", required=True)
    pa.add_argument("--title", required=True)
    pa.add_argument("--desc")
    pa.add_argument("--from", dest="src", required=True)
    pa.add_argument("--force", action="store_true")

    args = ap.parse_args()
    if args.cmd == "path":
        print(root())
    elif args.cmd == "public":
        print(public_dir())
    elif args.cmd == "status":
        p = meta_path()
        if not p.exists():
            print("not initialized (%s missing)" % p)
        else:
            print(p.read_text(encoding="utf-8"), end="")
    elif args.cmd == "project":
        print(load_meta().get("project", ""))
    elif args.cmd == "init":
        cmd_init(args)
    elif args.cmd == "add":
        cmd_add(args)


if __name__ == "__main__":
    main()
