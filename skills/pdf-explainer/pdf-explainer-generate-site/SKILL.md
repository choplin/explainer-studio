---
name: pdf-explainer-generate-site
description: "Compatibility entry point for building a local reading site from existing pdf-explainer reports. Use for an explicit pdf-explainer-generate-site request; otherwise use book-explainer-generate-site."
user-invocable: true
---

# Generate a PDF reading site

Require a PDF work directory, then apply [[book-explainer-generate-site]] with the
source format fixed to PDF. Preserve the existing command surface, but do not own
or repeat page ordering, landing vocabulary, authoring, build, or verification
rules here. Publishing remains [[explainer-reading-site-deploy]]'s job.
