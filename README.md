# Explainer Studio

> AI output, shaped for human understanding.

Explainer Studio is a Claude Code plugin and reusable explanation system for
reducing the effort required to understand complex information. Its shared
authoring contract turns semantic Markdown into structured, navigable HTML;
the bundled codebase, PDF, academic-paper, and git-diff workflows are concrete
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

- **Books, manuals, EPUBs, and long PDFs** become an overview, chapter reports, and a
  source-anchored reading site.
- **Academic papers** become an overview plus background, method, experiments,
  discussion, and related-work views.
- **Git diffs** become a reviewer-facing page organized around behavior,
  mental models, risks, verification, and review points.
- **Codebases** become snapshot explanations that connect architecture and module
  boundaries to representative execution paths and code evidence.

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

To understand how the current codebase, a module, or a feature works, run:

```text
/explainer-studio:codebase-explainer Explain how authentication is implemented and where I would extend it.
```

The result is usually one snapshot HTML document. Broad subjects automatically
expand into a navigable site when they require several independent mental models.

The document pipelines are richer applications of the same HTML system. They
also require [poppler](https://poppler.freedesktop.org/) for PDF inspection and
rendering.

For a book in PDF or DRM-free reflowable EPUB form:

```text
/explainer-studio:book-explainer /absolute/path/to/book.epub
```

The coordinator selects the PDF or EPUB adapter from the source. EPUB text,
structure, tables, notes, images, and SVGs are read natively; the pipeline does
not rasterize or convert the book to PDF.

The same profile entry point also continues or rebuilds an existing work
directory. For example, to create or rebuild only audio after book reports
already exist:

```text
/explainer-studio:book-explainer /absolute/path/to/work-dir
```

The coordinator validates existing artifacts, asks which terminal outputs are
wanted, and runs only the smallest required slice. A new execution gets an
immutable run request and manifest; exact-run resume requires naming its
manifest explicitly.

For a conference paper, journal paper, or preprint:

```text
/explainer-studio:paper-explainer /absolute/path/to/paper.pdf
```

Pass an existing paper work directory to the same command to add or rebuild
selected audio/site outputs without regenerating valid reports.

Book and paper coordinators share this complete workflow:

```text
source
  -> profile-specific extraction, structure, and evidence
  -> overview and detail reports
  -> report consistency
  -> media-independent Content brief
  -> immutable run Manifest
  -> optional dialogue/audio and/or reading site
  -> possible cross-medium consistency
  -> handoff
```

Each phase can run in a fresh AI session from declared artifacts alone. A
profile selects the source-specific report structure and site owner; Content
briefs, run planning, audio, cross-medium checks, and coordination semantics are
shared. The source remains authoritative, and later phases may consult it,
structure/evidence, and reports whenever needed. With no optional human
checkpoints selected, the coordinator runs continuously through the requested
local outputs. Publishing is separate and never automatic.

## 🧭 Choose the right workflow

| Goal | Primary output | Skill (Claude Code syntax) |
| --- | --- | --- |
| Explain any source material | Understandable HTML | `/explainer-studio:explainer-html-docs` |
| Understand current code | Snapshot HTML or reading site | `/explainer-studio:codebase-explainer` |
| Understand a long PDF | Markdown overview | `/explainer-studio:pdf-explainer-summarize` |
| Explore a long PDF in depth | Reports, optional audio, and/or reading site | `/explainer-studio:book-explainer` |
| Understand a reflowable EPUB | Markdown overview | `/explainer-studio:epub-explainer-summarize` |
| Explore, continue, or selectively rebuild a PDF or EPUB book explanation | Reports, optional audio, and/or reading site | `/explainer-studio:book-explainer` |
| Understand an academic paper | Structured Markdown reports | `/explainer-studio:paper-explainer-summarize` |
| Explore, continue, or selectively rebuild an academic-paper explanation | Reports, optional audio, and/or reading site | `/explainer-studio:paper-explainer` |
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
| Codebase explanation | Git plus the HTML runtime | May follow purpose-relevant documentation or related repositories when available |
| Long-PDF reports | poppler (`pdfinfo`, `pdftotext`, `pdftoppm`) | Required for PDF inspection, text-layer extraction, and page rendering |
| Reflowable-EPUB reports | Python 3 | Uses only the standard library; fixed-layout, image-only, and DRM-protected books are detected and stopped explicitly |
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

Repository validation uses `skill-validator` v1.6.0 and `claude plugin validate`.
The EPUB adapter's optional development checks use `pytest` and `ruff`.
End users do not need these tools to run the installed plugin.

## 🎯 Accuracy and trust model

Explainer Studio separates semantic judgment from mechanical page generation,
and source reading from synthesis where the source requires it.

- **HTML authoring** expresses meaning—key points, warnings, evidence, sequence,
  and review status—in semantic Markdown. The generator validates the vocabulary
  and deterministically produces navigation, tables, assets, and page structure.
- **Long PDFs** are extracted in page chunks, stitched into one canonical
  structure, and only then summarized. Chapter reports resolve their scope back
  to the source pages.
- **Reflowable EPUBs** are read from the OPF spine and authored navigation,
  preserving XHTML semantics and original media. Reports resolve to stable
  spine-resource/fragment locators instead of invented page numbers.
- **Academic papers** produce a shared fact spine before independent perspective
  reports are written. A final whole-report sweep checks contradictions and
  drift from the paper's argument.
- **Related-work citations** must come from the paper's own references and are
  checked against the public dblp API. Unverified entries are labeled rather
  than assigned a guessed URL.
- **Git diffs** are grouped into a guided behavioral walkthrough rather than
  presented as an undifferentiated sequence of changed lines.
- **Codebases** distinguish observed implementation, documented intent,
  inference, and incidental concerns, and disclose both investigated and excluded
  scope.

## 📌 Current scope

- The current plugin provides four applications of the shared HTML explanation
  system: codebase and git-diff explainers, long-PDF reading guides, and
  academic-paper reading guides.
- The supported installation path is the Claude Code plugin. The underlying
  packages follow the Agent Skills layout and can be read by other compatible
  agents, but the parallel worker wrappers are optimized for Claude Code.
- `paper-explainer` targets papers of roughly 8–30 pages, primarily in computer
  science. Use `book-explainer` for dissertations, books, and longer documents.
- Audio synthesis currently uses Japanese VOICEVOX voices.
- Report language follows the source or the conversation. Version 0.3.0 does
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
