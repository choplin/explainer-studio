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

From a git repository with changes, run:

```text
/explainer-studio:explainer-diff
```

The result is a self-contained HTML explanation that gives the reviewer
context, a mental model, a guided walkthrough, risks, verification status, and
focused review points.

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

Choose the source-specific workflow that feeds the shared HTML explanation
system. Invoke a narrower skill when you already have intermediate material.

| Goal | Skill |
| --- | --- |
| Explain a git diff as a reviewer-facing HTML page | `/explainer-studio:explainer-diff` |
| Full guide for a book, manual, thesis, or long PDF | `/explainer-studio:pdf-explainer-full-guide` |
| Source-anchored overview of a long PDF | `/explainer-studio:pdf-explainer-summarize` |
| Full guide for an academic paper | `/explainer-studio:paper-explainer-full-guide` |
| Overview and perspective reports for a paper | `/explainer-studio:paper-explainer-summarize` |
| Build a local site from existing PDF reports | `/explainer-studio:pdf-explainer-generate-site` |
| Build a local site from existing paper reports | `/explainer-studio:paper-explainer-generate-site` |
| Turn Markdown into a two-speaker script | `/explainer-studio:explainer-audio-dialogue` |
| Narrate an existing two-speaker script | `/explainer-studio:explainer-audio-narrate` |
| Initialize or publish the shared reading-site library | `/explainer-studio:explainer-reading-site-initialize` / `/explainer-studio:explainer-reading-site-deploy` |

Claude can also select a skill automatically from a natural-language request.
The explicit commands above are useful when you already know which artifact you
want.

## 🧰 Optional capabilities and requirements

Install only the dependencies needed by the outputs you want.

| Capability | Requirements | Behavior when unavailable |
| --- | --- | --- |
| Core HTML generation | `pandoc` on `PATH` or Nix | HTML output cannot be built |
| Long-PDF text reports | poppler | Required; the pipeline stops with setup guidance |
| Long-PDF figure extraction | `uv` or Nix for local MinerU resolution | Optional; reports continue without extracted figure crops |
| Academic-paper reports | poppler plus `uv` or Nix; `curl` and `jq` for dblp verification | MinerU OCR is required; the first run downloads several GB of model data |
| Audio synthesis | VOICEVOX ENGINE, `ffmpeg`, Python 3, and `curl` | Dialogue scripts remain available; synthesis is skipped |
| Site publishing | authenticated `wrangler` and a Cloudflare account | Local site generation is unaffected |

The bundled preflight scripts resolve supported runtimes from `PATH` first and
use the bundled Nix environment when available. They do not silently install
global packages.

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

## 🔒 Network and privacy boundaries

- Source PDFs and MinerU OCR stay local; documents are not uploaded to an OCR
  service.
- VOICEVOX synthesis uses a local engine on `localhost`.
- Paper related-work verification queries the public dblp API.
- Optional diagram, diff, and syntax-highlighting components may load their
  renderer from a CDN.
- Publishing uses Cloudflare Pages and requires explicit confirmation. The
  initialization skill can place the shared library behind Cloudflare Access.

## 📌 Current scope

- Version 0.1.0 provides three applications of the shared HTML explanation
  system: git-diff explainers, long-PDF reading guides, and academic-paper
  reading guides.
- The supported installation path is the Claude Code plugin. The underlying
  packages follow the Agent Skills layout and can be read by other compatible
  agents, but the parallel worker wrappers are optimized for Claude Code.
- `paper-explainer` targets papers of roughly 8–30 pages, primarily in computer
  science. Use `pdf-explainer` for dissertations, books, and longer documents.
- Audio synthesis currently uses Japanese VOICEVOX voices.
- Report language follows the source or the conversation. Version 0.1.0 does
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
