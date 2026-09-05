---
name: explainer-content-model
description: "Internal Artifact-only phase that creates or reuses one media-independent Content brief from a supported source profile's canonical structure, evidence, and source-grounded reports. Use after report consistency and before Planning."
user-invocable: false
---

# Build the content model

Apply [[explainer-content-workflow-base]] and read its Artifact contract and the
selected profile. Own only the Content model phase.

Require exact paths for one immutable run request, the profile's canonical
structure/evidence, the complete in-scope report set, and source identity/digest
when available. Validate every input, profile, adapter, and locator kind. Never
use prior conversation, scratchpads, or an inferred latest file. Consult a
narrow source locus when derived Artifacts are insufficient, but permit an
otherwise valid reports-ready run when the source is unavailable.

Reuse a Content brief only when shared validity rules pass. Otherwise create the
next complete immutable `structured/content-brief-vN.yaml`. Preserve authored
source divisions in order and record their roles, relationships, reader
destinations, and media-independent obligations. For papers, keep editorial
perspectives distinct from source-authored sections. Never redesign the source
into an independent curriculum.

Run an AI check for source fidelity, authored-order preservation, missing
decision-changing qualifications, structure/perspective confusion, and
accidental media policy. If `content-brief` is a selected human gate, return the
checked brief as its subject and continue only when the coordinator supplies a
matching decision Artifact.

Return the exact brief path, SHA-256 digest, reuse/create disposition, checks,
and any structured missing/incompatible-input blocker.
