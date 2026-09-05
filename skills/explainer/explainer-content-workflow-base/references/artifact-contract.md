# Artifact contract

## Contents

- Artifact graph
- Validity
- Run request
- Content brief
- Run Manifest
- Checkpoint decision
- Phase result

## Artifact graph

```text
source
  -> profile structure and evidence
  -> reports/overview.md + profile detail reports
  -> structured/content-brief-vN.yaml
  -> structured/manifest-vN.yaml
  -> dialogue/*.txt -> audio/*.m4a
  -> src/*.md -> site/
```

The selected profile defines its exact structure, evidence, and report
Artifacts. `structured/run-request-vN.yaml` records the requested terminal state
and feeds every selected phase. Optional
`structured/checkpoints/manifest-vN/<checkpoint>.yaml` files carry human
decisions across sessions.

## Validity

Reuse an Artifact only when:

- its file exists and is parseable in an accepted schema or format;
- every declared input path still identifies the intended Artifact;
- every declared input digest matches;
- its profile and source-locator kind match; and
- its owning skill's acceptance checks pass.

Classify discovered Artifacts as `valid`, `missing`, `stale`, or
`incompatible`. File existence alone never means complete. A stale Artifact
invalidates every downstream Artifact that records its old digest.

Never infer the current request, brief, or Manifest from the highest version.
The coordinator supplies exact selected paths. Use SHA-256 for file identity.
For a directory, validate its owner-defined manifest or deterministic inventory
rather than its modification time.

## Run request

Before invoking a phase for a new execution, write one immutable
`structured/run-request-vN.yaml`. It is the Artifact form of the initial user
consultation, not a plan or status record.

```yaml
schema_version: 1
request: 3
created_at: 2026-09-05T12:00:00+09:00
profile: book | paper
adapter: pdf | epub
work_directory: /absolute/path/to/work-directory
starting_point:
  kind: source | work-directory
  path: /absolute/path
targets:
  reports: all | [chapter-1, chapter-3] | [method, experiments]
  dialogue: none | [overview] | [overview, chapter-1]
  narration: true
  site: true
policy:
  language: ja
  audience: newcomer
  depth: explanatory
  supporting_detail: selective
  pacing: structured
  segmentation: source-structure
  duration: derived
existing_outputs:
  dialogue/overview.txt: replace
  audio/overview.m4a: replace
  site/: untouched
human_gates:
  dialogue-pilot: true
```

Record only selected human gates as `true`; absence means `false`. Never put AI
checks in `human_gates`. Record the resolved profile, adapter, and absolute work
directory so early phases need no session context. Resolve all values before
saving. If the request changes, write a new revision rather than editing the old
one.

`targets` name desired terminal Artifacts. The coordinator computes prerequisite
closure; users do not choose internal phases.

## Content brief

The Content model phase writes an immutable
`structured/content-brief-vN.yaml`. It records exact profile structure/evidence
and report inputs with digests, then captures:

- source identity, purpose, and authored progression;
- source divisions in authored order;
- each division's role and reader destination;
- important relationships between divisions; and
- media-independent explanatory obligations anchored to source divisions.

An obligation is a principal claim, mechanism, decision rule,
decision-changing condition, or necessary prerequisite whose omission would
materially change understanding. Do not create obligations for headings,
examples, repeated paraphrases, exhaustive lists, or incidental detail.

The brief is canonical only among derived interpretations for the recorded
input revision. It remains subordinate to the source. Reuse it only when every
recorded structure, evidence, and report digest matches and any available source
digest also matches. If an available source changed while reports did not,
classify the reports as stale.

Create a complete new brief revision when its inputs change. Never patch an
earlier revision. Obligation IDs are stable only within one brief; identify them
elsewhere by `(content_brief_sha256, obligation_id)`.

## Run Manifest

The Planning phase consumes an exact run request, Artifact inventory, and
Content brief, then writes one immutable `structured/manifest-vN.yaml`.

Record at least:

```yaml
schema_version: 1
manifest: 3
created_at: 2026-09-05T12:10:00+09:00
workflow_revision: "<repository commit, package version, or unknown>"
profile: book
adapter: epub
inputs:
  request:
    path: structured/run-request-v3.yaml
    sha256: "..."
  source:
    path: /absolute/path/to/source
    sha256: "..."
    availability: available
  structure:
    structured/toc.md: "..."
    structured/outline.md: "..."
  evidence: {}
  reports:
    reports/overview.md: "..."
  content_brief:
    path: structured/content-brief-v2.yaml
    sha256: "..."
execution:
  reports/overview.md: reuse
  structured/content-brief-v2.yaml: reuse
  dialogue/overview.txt: replace
  audio/overview.m4a: replace
  site/: untouched
outputs:
  dialogue/overview.txt:
    kind: dialogue
    source_reports: [reports/overview.md]
    source_divisions: [whole-source]
    destination: "..."
    obligations: [C01, C03]
  audio/overview.m4a:
    kind: audio
    input: dialogue/overview.txt
human_gates:
  dialogue-pilot: true
```

The `structure` and `evidence` mappings use the selected profile's Artifact
names. Allowed execution actions are:

- `reuse`: validate and use an existing Artifact;
- `create`: produce a missing Artifact;
- `replace`: deliberately produce an Artifact at an existing path;
- `untouched`: leave an existing Artifact outside this execution.

These are immutable planning decisions, not runtime status. Output paths are
mapping keys and must be unique. Include resolved output policy even when the
compact example omits it.

Use obligation mappings to check likely omissions within selected scope. Never
let them determine source divisions, top-level order, or navigation.

Create a new Manifest for every new execution. Reuse one only when explicitly
resuming that exact run. Never mutate it after Planning.

## Checkpoint decision

When a selected human gate must survive a session boundary, persist one
immutable decision Artifact:

```yaml
schema_version: 1
manifest:
  path: structured/manifest-v3.yaml
  sha256: "..."
checkpoint: dialogue-pilot
subject:
  path: dialogue/overview.txt
  sha256: "..."
decision: approved | revise
created_at: 2026-09-05T13:00:00+09:00
feedback: ""
```

For a pre-Manifest `content-brief` gate, reference the run request and Content
brief instead. Continue past a gate only when the coordinator supplies a
matching decision Artifact. A `revise` decision creates new affected revisions;
it never mutates an immutable input.

This is an authorization input, not execution status. Do not create it when the
gate is not selected.

## Phase result

A phase returns exact produced paths, digests, acceptance-check results, and a
structured blocker when applicable. Do not append this result to the Manifest.
Durable phase outputs, rather than mutable status, are the evidence used for
later discovery.
