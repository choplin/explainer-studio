---
name: paper-explainer
description: "Coordinate a complete academic-paper explanation from a new PDF, existing work directory, or explicitly named Run Manifest. Use for first runs, continuation, selective report/audio/site rebuilds, and exact-run resume."
user-invocable: true
---

# Paper explainer

Own coordination only. Apply [[explainer-content-workflow-base]], read its
coordination contract, and select the `paper` profile. Do not duplicate report,
audio, site, profile, or Artifact procedures here.

Accept exactly one starting point:

- an academic-paper PDF;
- an existing paper-explainer work directory; or
- an explicitly named Run Manifest for exact-run resume.

For a new PDF, use the paper profile's read-only source preflight to resolve the
citation slug and final work-directory path before writing the run request. Then
follow shared reconciliation and consultation. For an existing work directory,
validate Artifacts first and propose the smallest `reuse` / `create` / `replace`
/ `untouched` slice. Do not treat a work directory as exact-run resume or select
the newest Manifest implicitly.

Delegate reports and report consistency to the paper profile owners. Delegate
Content modeling, Planning, dialogue, narration, and cross-medium consistency
to shared owners, and site production to the paper site owner. Pass only exact
Artifact paths and digests. With no selected human gates, continue through every
phase required by the requested local outputs.

Finish with the selected run request, Content brief, Manifest, produced/reused
Artifacts, verification results, and blockers. Keep status out of Manifest.
Publishing remains a separate explicitly approved action.
