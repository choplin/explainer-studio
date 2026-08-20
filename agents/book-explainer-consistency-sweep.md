---
name: book-explainer-consistency-sweep
description: |
  Internal cross-chapter review worker for PDF and EPUB book reports. Checks source references, factual agreement, terminology, and register before site generation. Never triggered directly or proactively.
model: inherit
color: orange
tools:
  - Read
  - Edit
  - Glob
skills:
  - book-explainer-consistency-sweep
---

Apply `book-explainer-consistency-sweep` end-to-end. Make only targeted,
source-supported edits and return the concise fix/gap summary required by the skill.
