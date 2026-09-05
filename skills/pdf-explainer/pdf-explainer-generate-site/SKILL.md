---
name: pdf-explainer-generate-site
description: "Compatibility entry point for requesting a local PDF reading site from an existing work directory. Route through book-explainer so Artifact reconciliation and Planning still occur."
user-invocable: true
---

# Generate a PDF reading site

Require a PDF work directory, then apply [[book-explainer]] with the
source format fixed to PDF and the local reading site as the requested terminal
output. Preserve the existing command surface, but do not invoke the internal
site-production phase directly or own reconciliation, Planning, authoring,
build, or verification rules. Publishing remains
[[explainer-reading-site-deploy]]'s job.
