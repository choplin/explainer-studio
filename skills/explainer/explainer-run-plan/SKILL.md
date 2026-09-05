---
name: explainer-run-plan
description: "Internal Artifact-only Planning phase that resolves one supported source-explainer execution into an immutable Run Manifest. Use after selecting a valid Content brief and before optional audio or site production."
user-invocable: false
---

# Plan one explainer execution

Apply [[explainer-content-workflow-base]] and read its Artifact contract and the
selected profile. Own only Planning; do not create reports, Content briefs,
dialogue, audio, or site files.

Require exact paths/digests for one immutable run request, validated Artifact
inventory, profile structure/evidence, all in-scope reports, and one exact
Content brief. Validate them without conversation history or an inferred latest
revision. Resolve policy, compute terminal outputs and prerequisite closure,
assign unique paths, map outputs to source divisions and reports, and classify
each relevant Artifact as `reuse`, `create`, `replace`, or `untouched`.

Write the next immutable `structured/manifest-vN.yaml`. Create a new Manifest
for every new execution. Accept an existing Manifest only for explicitly
selected exact-run resume when all recorded input digests still match.

Run an AI check for complete policy resolution, unique paths, valid dependency
closure, profile consistency, source mapping, selected-scope omissions, and
unintended replacement. If `manifest` is a selected human gate, return the
checked Manifest as its subject and continue only with a matching decision
Artifact.

Return the exact Manifest path, SHA-256 digest, checks, and any structured
missing/incompatible-input blocker.
