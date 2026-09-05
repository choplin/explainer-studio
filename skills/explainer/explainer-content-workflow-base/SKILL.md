---
name: explainer-content-workflow-base
description: "Shared internal contract for complete source-explainer workflows from source-specific extraction and reports through reusable content modeling, immutable run planning, optional audio/site production, verification, and handoff. Use when coordinating or implementing a book or paper workflow phase."
user-invocable: false
---

# Explainer content workflow base

Define the complete workflow and phase contracts. Do not execute phases here.

```text
source
  -> profile-specific extraction, structure, and evidence
  -> overview and detail reports
  -> report consistency
  -> content model / Content brief
  -> planning / Run Manifest
  -> optional dialogue and narration
  -> optional reading site
  -> possible cross-medium consistency
  -> handoff
```

The workflow always includes the report stages. Starting from valid existing
reports is a partial execution of this workflow, not a separate audio or site
workflow.

## Invariants

- Keep the source authoritative for its claims, qualifications, authored
  structure, and progression.
- Treat the Content brief as a media-independent aid to understanding the
  source, never as a replacement curriculum or structure.
- Let downstream phases consult the source, profile structure/evidence, and
  reports whenever needed. Planning Artifacts are not information bottlenecks.
- Make every phase executable in a fresh session from declared Artifacts alone.
  Never depend on earlier prompts, scratchpads, or agent memory.
- Put run-specific choices in immutable run Artifacts before invoking a phase.
- Keep the Manifest immutable and free of status, progress, retries, and
  completion fields.
- Run AI checks unconditionally. Human gates are optional and selected per run.

## Phase boundary

Every phase skill must:

1. declare required Artifact types and accepted schema versions;
2. receive exact paths rather than infer "current" files;
3. validate identity, provenance, and digests before work;
4. derive no required choice from conversational context;
5. return a precise missing/incompatible-input result instead of guessing;
6. write self-identifying outputs with their input provenance;
7. run its own AI acceptance checks; and
8. leave coordination and human interaction to the workflow coordinator.

Read `references/artifact-contract.md` for schemas and validity. Read
`references/coordination.md` when coordinating, rebuilding, or resuming. Read
`references/profiles.md` before selecting profile-specific Artifact authorities
or phase owners.
