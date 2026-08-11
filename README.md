# Explainer Studio

> AI output, shaped for human understanding.

Explainer Studio is a Claude Code plugin and reusable explanation system for
reducing the effort required to understand complex information. Its shared
authoring contract turns semantic Markdown into structured, navigable HTML;
the bundled PDF, academic-paper, and git-diff workflows are concrete
applications of that system.

## ✨ Why Explainer Studio?

- **Out of the box, not boxed in.** Run complete pipelines for git diffs, long
  PDFs, and academic papers, or build new explainers on the same semantic
  Markdown and deterministic HTML foundation.
- **Designed around human attention.** Content is reorganized into orientation,
  key points, progressive detail, and focused review paths instead of being
  converted 1:1.
- **Evidence stays within reach.** Source anchors, figures, changed files,
  risks, and verification status travel with the explanation.
- **Yours to review and share.** The result is static HTML you can inspect
  locally, share as a document, or publish as a reading site when you choose.

## 📦 From source to understandable HTML

Every workflow uses the same basic shape:

```text
complex source
      │
      ▼
domain-aware analysis
      │
      ▼
semantic explanation
(orientation, key points, evidence, sequence, risks)
      │
      ▼
validated HTML generator
      │
      ▼
understandable HTML
(one explainer page or a navigable reading site)
```

The bundled workflows specialize the analysis stage:

- **Books, manuals, and long PDFs** become an overview, chapter reports, and a
  source-anchored reading site.
- **Academic papers** become an overview plus background, method, experiments,
  discussion, and related-work views.
- **Git diffs** become a reviewer-facing page organized around behavior,
  mental models, risks, verification, and review points.

Dialogue scripts and audio guides are optional companion artifacts. They are
not required to produce the HTML explanation.

## 🚀 Quick start

### 1. Install the plugin

You need a current version of [Claude Code](https://code.claude.com/docs/en/overview).
Run these commands inside Claude Code:

```text
/plugin marketplace add choplin/explainer-studio
/plugin install explainer-studio@explainer-studio
/reload-plugins
```

### 2. Install an HTML build runtime

The shared generator resolves `pandoc` from `PATH` or from its bundled Nix
environment:

```bash
# macOS
brew install pandoc

# Debian / Ubuntu
sudo apt-get install pandoc
```

If Nix is already installed, you can skip this step.

### 3. Generate your first explanation

Invoke an installed skill by name. The examples below use Claude Code syntax;
invocation syntax may differ in other compatible agents.

From a git repository with changes, run:

```text
/explainer-studio:diff-explainer
```

The result is a single-file HTML explanation that gives the reviewer context, a
mental model, a guided walkthrough, risks, verification status, and focused
review points.

The document pipelines are richer applications of the same HTML system. They
also require [poppler](https://poppler.freedesktop.org/) for PDF inspection and
rendering.

For a book, manual, thesis, or other long PDF:

```text
/explainer-studio:pdf-explainer-full-guide /absolute/path/to/book.pdf
```

For a conference paper, journal paper, or preprint:

```text
/explainer-studio:paper-explainer-full-guide /absolute/path/to/paper.pdf
```

Each full guide confirms its scope once, builds the local HTML site, and
finishes with a manifest of the reports and optional companion artifacts.
Publishing is offered separately and is never automatic.

## 🧭 Choose the right workflow

| Goal | Primary output | Skill (Claude Code syntax) |
| --- | --- | --- |
| Explain any source material | Understandable HTML | `/explainer-studio:explainer-html-docs` |
| Understand a long PDF | Markdown overview | `/explainer-studio:pdf-explainer-summarize` |
| Explore a long PDF in depth | Reports and reading site | `/explainer-studio:pdf-explainer-full-guide` |
| Understand an academic paper | Structured Markdown reports | `/explainer-studio:paper-explainer-summarize` |
| Explore an academic paper in depth | Reports and reading site | `/explainer-studio:paper-explainer-full-guide` |
| Review code changes | Reviewer-facing HTML | `/explainer-studio:diff-explainer` |

Compatible agents can also select a skill automatically from a natural-language
request. Explicit invocation is useful when you already know which artifact you
want.

## 🧰 External dependencies

Explainer Studio does not silently install global tools. Each workflow checks
its own requirements and uses tools already on `PATH`; where a bundled Nix
environment exists, its preflight script can use that instead.

### Local tools by capability

Install only what the outputs you want require.

| Capability | Local requirements | Notes |
| --- | --- | --- |
| Supported plugin installation | Current Claude Code and a Bash-compatible shell | macOS and Linux provide the expected shell environment; native Windows needs WSL or Git Bash for the bundled scripts |
| HTML generation | `pandoc` on `PATH`, or Nix with flakes enabled | Required by every workflow that produces HTML |
| Git-diff explanation | Git plus the HTML runtime | Reads the current repository diff and produces one HTML file |
| Long-PDF reports | poppler (`pdfinfo`, `pdftotext`, `pdftoppm`) | Required for PDF inspection, text-layer extraction, and page rendering |
| Long-PDF figure extraction | `uv`, or an installed MinerU plus Python 3; Nix can supply the runtime | Optional; the report pipeline continues without extracted figure crops |
| Academic-paper reports | poppler plus `uv`, or poppler plus an installed MinerU and Python 3; `curl` and `jq` for related-work bibliography verification | MinerU is required; `uv` resolves it with `uvx --from 'mineru[core]'` when it is not installed |
| Audio synthesis | VOICEVOX ENGINE, Python 3, `curl`, and `ffmpeg` | Optional; dialogue scripts remain available when synthesis is skipped |
| Reading-site publishing | Python 3, authenticated `wrangler`, `curl`, and a Cloudflare account | Optional; local site generation does not require Cloudflare |

The bundled Nix environments are capability-specific:

- HTML generation supplies `pandoc` with Lua support.
- Long-PDF processing supplies poppler, `uv`, and Python 3.
- Academic-paper processing supplies poppler, `uv`, Python 3, `curl`, and `jq`.

Nix does not bundle MinerU itself. `uv` resolves MinerU into its shared tool
cache on demand, and the first run downloads the package and several gigabytes
of model data.

### Network services and remote assets

Source PDFs are not uploaded to an OCR service. Network use is limited to the
capabilities below and to the agent's configured model provider.

- **MinerU bootstrap** — `uvx` resolves the MinerU package from PyPI, and MinerU
  downloads its model data on first use. OCR itself then runs locally.
- **Nix bootstrap** — first use downloads the pinned flake inputs and runtime
  packages; later runs reuse the local Nix store.
- **dblp** — the academic-paper related-work workflow queries the public dblp
  API to verify bibliography metadata. No API key is required.
- **jsDelivr** — the optional highlight.js, diff2html, and Mermaid components
  load their renderers from a CDN unless they are vendored. Base HTML, reading
  navigation, and browser-side comments use local assets; reviewer-facing diff
  pages need network access for rich diff and diagram rendering.
- **Cloudflare** — publishing uses the Cloudflare API through `wrangler` and
  hosts the shared reading-site library on Cloudflare Pages. No Cloudflare
  connection is made during local generation.
- **VOICEVOX** — narration talks only to a local VOICEVOX ENGINE on
  `localhost`; it does not call a hosted speech API.

### Development-only dependency

Repository validation uses `skill-validator` v1.6.0 in addition to
`claude plugin validate`. End users do not need `skill-validator` to run the
installed plugin.

## 🎯 Accuracy and trust model

Explainer Studio separates semantic judgment from mechanical page generation,
and source reading from synthesis where the source requires it.

- **HTML authoring** expresses meaning—key points, warnings, evidence, sequence,
  and review status—in semantic Markdown. The generator validates the vocabulary
  and deterministically produces navigation, tables, assets, and page structure.
- **Long PDFs** are extracted in page chunks, stitched into one canonical
  structure, and only then summarized. Chapter reports resolve their scope back
  to the source pages.
- **Academic papers** produce a shared fact spine before independent perspective
  reports are written. A final whole-report sweep checks contradictions and
  drift from the paper's argument.
- **Related-work citations** must come from the paper's own references and are
  checked against the public dblp API. Unverified entries are labeled rather
  than assigned a guessed URL.
- **Git diffs** are grouped into a guided behavioral walkthrough rather than
  presented as an undifferentiated sequence of changed lines.

## 📌 Current scope

- Version 0.2.0 provides three applications of the shared HTML explanation
  system: git-diff explainers, long-PDF reading guides, and academic-paper
  reading guides.
- The supported installation path is the Claude Code plugin. The underlying
  packages follow the Agent Skills layout and can be read by other compatible
  agents, but the parallel worker wrappers are optimized for Claude Code.
- `paper-explainer` targets papers of roughly 8–30 pages, primarily in computer
  science. Use `pdf-explainer` for dissertations, books, and longer documents.
- Audio synthesis currently uses Japanese VOICEVOX voices.
- Report language follows the source or the conversation. Version 0.2.0 does
  not provide a single pipeline-wide language selector.
- Generated sites are local by default. The bundled publishing workflow targets
  a shared Cloudflare Pages library.

## 📚 Documentation

- [PDF pipeline guide](skills/pdf-explainer/README.md)
- [Academic-paper pipeline guide](skills/paper-explainer/README.md)
- [HTML design-system reference site](skills/explainer/explainer-html-docs/site/index.html)
- [Release history](CHANGELOG.md)

## 🛠️ Develop and validate locally

Load the checkout directly while developing:

```bash
claude --plugin-dir .
```

Validate the plugin manifest:

```bash
claude plugin validate .
```

Validate every Agent Skill package with the repository-pinned
`skill-validator` version described by the check script:

```bash
./scripts/check-skills.sh
```

## ⚖️ License

[MIT](LICENSE) © 2026 Akihiro Okuno
