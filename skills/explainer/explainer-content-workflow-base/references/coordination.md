# Workflow coordination

## Contents

- Invocation modes
- Reconciliation
- First execution
- Subsequent execution
- Phase order
- Human gates
- Handoff

## Invocation modes

Use the selected profile's one coordinator entry point for the complete
workflow. Resolve one mode from explicit input and valid Artifacts:

- `new`: start from a source or begin a new execution from a work directory;
- `rebuild`: create, replace, or continue selected terminal outputs from valid
  upstream Artifacts;
- `resume`: continue the exact execution named by an existing Manifest.

`rebuild` is not a separate audio or site workflow. It is a partial execution of
the complete workflow from the earliest invalid or newly required phase.

Do not silently interpret a work directory as resume. A new invocation normally
creates a new run request and Manifest. Resume requires an explicitly selected
Manifest. If "continue" could name multiple incomplete runs, ask the user to
select one unless exactly one is unambiguous.

## Reconciliation

At every invocation:

1. locate the supplied source, work directory, or Manifest;
2. select and validate its profile and adapter;
3. inventory source, profile structure/evidence, reports, briefs, Manifests,
   checkpoint decisions, dialogue, audio, and site Artifacts;
4. classify each Artifact by the shared validity contract;
5. determine the desired terminal Artifacts;
6. compute prerequisite closure and the earliest phase that must run;
7. classify each relevant path as `reuse`, `create`, `replace`, or `untouched`;
8. show a compact proposed slice before materializing the run request when a
   destructive replacement or material ambiguity exists.

Ask only questions that change terminal outputs, scope, policy, human gates, or
replacement. Never ask users to choose internal phases.

## First execution

For a source with no valid work directory, consult once about:

- profile report scope, defaulting to its complete standard report set;
- requested dialogue, narration, and site terminal outputs;
- medium policy such as audience, depth, pacing, segmentation, and optional
  duration;
- profile/adapter-specific source options;
- named human gates, defaulting to none; and
- collection or replacement choices that materially affect files.

Write a new immutable run request, then execute dependency closure. With no
human gates, continue through the last requested local Artifact. Publishing is
never part of this run.

## Subsequent execution

Validate an existing work directory before deciding what to rerun. For example:

```text
Request: rebuild overview audio
reuse:     profile structure/evidence, reports, matching Content brief
create:    new run request and Manifest
replace:   dialogue/overview.txt, audio/overview.m4a
untouched: other dialogue/audio, site
```

```text
Request: build the missing site
reuse:     profile structure/evidence, reports, matching Content brief
create:    new run request, Manifest, src pages, site
untouched: dialogue and audio
```

An explicit rebuild request authorizes replacement of named terminal outputs
and necessary derived inputs only. When an upstream Artifact is stale, include
every requested dependent Artifact in the replacement closure or leave it
untouched and outside the requested terminal state. Never reuse a downstream
Artifact whose recorded input digest is stale.

## Phase order

Coordinate owner skills in this dependency order:

1. profile extraction, canonical structure/evidence, and reports;
2. profile report consistency;
3. [[explainer-content-model]];
4. [[explainer-run-plan]];
5. requested [[explainer-audio-dialogue]] and [[explainer-audio-narrate]];
6. requested profile reading-site owner;
7. [[explainer-cross-medium-consistency]] when at least two comparable media
   validate, whether newly produced or reused;
8. handoff.

Read `profiles.md` for exact owners and Artifact authorities. Independent work
inside a phase may run in parallel. Dependent phases remain sequential. Pass
exact paths and digests returned by one owner to the next.

Reuse a Content brief before invoking Content model only when all inputs
validate. Planning always creates a new Manifest for a new execution.

## Human gates

Run request and Manifest contain only selected gates as `true`. AI checks always
run and are not configurable gates.

At a selected gate:

1. let the owner finish its Artifact and AI checks;
2. present that exact Artifact or check result to the user;
3. write the response as a checkpoint-decision Artifact;
4. supply that decision Artifact to the next fresh phase session.

If feedback changes the Content brief, plan, or media, create new affected
revisions and a new Manifest when inputs or execution decisions change. Never
edit frozen Artifacts.

## Handoff

Report the run request, Content brief, Manifest, produced and reused Artifacts,
AI checks, checkpoint decisions, and unresolved blockers. Compare actual files
with the planned slice without recording mutable completion state in Manifest.
