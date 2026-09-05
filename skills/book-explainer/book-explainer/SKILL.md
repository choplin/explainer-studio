---
name: book-explainer
description: "Coordinate a complete PDF or EPUB book explanation from a new source, existing work directory, or explicitly named Run Manifest. Use for first runs, continuation, selective report/audio/site rebuilds, and exact-run resume."
user-invocable: true
---

# Book explainer

Own coordination only. Apply [[explainer-content-workflow-base]], read its
coordination contract, and select the `book` profile. Do not duplicate phase
procedures, profile contracts, or Artifact schemas here.

Accept exactly one starting point:

- a PDF or DRM-free reflowable EPUB source;
- an existing book-explainer work directory; or
- an explicitly named Run Manifest for exact-run resume.

Resolve the current Artifact graph before asking questions. For a new run,
consult once about terminal outputs, scope, policy, replacement choices, and
optional human gates, then materialize those answers as the run-request
Artifact. For a subsequent run, present the smallest proposed `reuse` /
`create` / `replace` / `untouched` slice and ask only about material ambiguity.

Delegate each selected phase to its profile or shared owner. Pass exact Artifact
paths and digests, never conversational recollection. Resolve missing or
incompatible inputs through the dependency graph instead of inventing context.

With no selected human gates, continue through every phase required by the
requested local outputs. At a selected gate, persist the human decision as an
immutable checkpoint-decision Artifact before continuing.

Do not select the newest Manifest implicitly. Create a new Manifest for a new
execution and reuse one only when the user explicitly selects that exact run.

Finish with the selected run request, Content brief, Manifest, produced/reused
Artifacts, verification results, and blockers. Keep status out of Manifest.
Publishing remains a separate explicitly approved action.
