---
name: explainer-cross-medium-consistency
description: "Internal Artifact-only phase that compares valid audio-dialogue and reading-site outputs from one supported source workflow when at least two comparable media exist."
user-invocable: false
---

# Cross-medium consistency

Apply [[explainer-content-workflow-base]] and read its Artifact contract and the
selected profile. Require the exact run request, Content brief, Run Manifest,
profile structure/evidence, reports, and valid media inventories with digests.
Never infer current revisions. Run only when at least two comparable media
validate; they may be newly produced or reused.

Check that the media match Manifest mappings, present a compatible source-wide
mental model, preserve decision-changing qualifications, and do not contradict
one another or the reports. Allow appropriate differences in depth, sequence,
examples, and presentation. Consult the reports, profile evidence, or narrow
source locus when needed, and resolve conflicts in favor of the source.

Return the check separately without adding status to Manifest. If
`cross-medium` is a selected human gate, return the checked result as its
subject. Human interaction and decision-Artifact creation belong to the
coordinator.
