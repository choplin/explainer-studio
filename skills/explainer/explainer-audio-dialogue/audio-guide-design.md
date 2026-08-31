# Audio guide design

An audio guide is not a spoken copy of its source. A report is a reference
artifact: it preserves definitions, procedures, figures, numbers, examples,
evidence, and caveats so a reader can inspect them later. An audio guide is a
sequential explanation: after one listen, the listener should be able to follow
the main claims, their causal links, and the conclusion.

Use this procedure before planning speaker turns. Dialogue craft cannot repair a
guide whose content was selected at the wrong level.

## Start from the listener's destination

Before selecting content, record this planning block in the private scratchpad:

```text
source_title:
guide_kind: overview | focused
spoken_topic:
listener_destination:
opening_orientation:
central_hook:
```

Resolve `source_title` from an explicit document title, a caller-provided title,
or a source heading, in that order. Do not invent a title. If the source has no
formal title, use an accurate spoken description that identifies it.

Write `listener_destination` as one sentence describing what the listener should
understand or be able to explain at the end. `opening_orientation` must carry the
source title, guide kind, spoken topic, and destination into the first 2–4 spoken
turns; a private plan or comment alone does not satisfy this requirement. Keep
`central_hook` separate so that the hook follows the orientation rather than
replacing it.

Then write the **explanatory spine**: the ordered claims and causal links needed
to reach that destination.

The spine is not the source's heading list. If it mirrors the report section by
section, it is probably an inventory rather than an explanation. Reorder source
material when the listener needs a different sequence to understand cause,
contrast, or consequence.

## Select by explanatory job

Classify source material against the spine:

- **Core** — a claim on the spine; a definition or mechanism needed to understand
  it; representative evidence needed to believe it; or an exception/caveat that
  changes the conclusion or action. Keep it.
- **Supporting** — another figure, number, example, procedure, or piece of
  evidence that reinforces an already-supported core claim. Choose the clearest
  representative item and combine equivalent items.
- **Reference-only** — exhaustive lists, repeated evidence, secondary examples,
  and implementation details that do not change the listener's understanding or
  action. Leave them in the report.

Faithfulness means preserving the source's claims and qualifications, not
narrating every source detail. Never omit a caveat that changes a conclusion,
reverse a comparison, or harden a hedged claim. Conversely, do not keep a detail
merely because the report took care to preserve it.

## Set the altitude

- An overview is a broad guide: visit every top-level section lightly and connect
  them into one whole-document explanation.
- A detail report becomes a focused guide: explain that part's central mechanism
  more deeply, but still select representative evidence rather than walking every
  subsection, figure, and example.

Group the selected spine into roughly 3–6 **conversational acts**. This is a
structuring aid, not a cap on source topics and not permission to drop a necessary
causal link. Each act should advance the listener toward the destination.

## Calibrate a set with one pilot

When producing guides for several reports, write one representative detail guide
first—prefer the selected detail report with the most speakable prose, or the
overview when no detail report is selected. Review whether its spine, evidence
density, and depth feel like an audio guide rather than a converted report. Use
that content-selection pattern to calibrate the remaining guides; do not use its
runtime as a uniform target.

## Use length only as a diagnostic

After drafting, report:

- **spoken characters:** non-whitespace spoken text after removing speaker
  prefixes, comments, and blank lines;
- **estimated duration:** spoken characters ÷ 340 characters/minute;
- **compression ratio:** spoken characters ÷ the source's speakable
  non-whitespace prose characters, excluding Markdown syntax, page anchors, code
  blocks, URLs, and other material not intended to be read aloud.

When the user supplied a length, treat it as a coverage budget, not a quota.
Without a user budget, more than 10,200 spoken characters (about 30 minutes) or a
compression ratio above 40% is a warning that the source may have been converted
sequentially. The numbers are not acceptance targets and do not justify cutting a
core link.

For a warned guide, inspect the creation choices first:

- Does the sequence mirror the report's headings?
- Did every figure or example become its own exchange?
- Do several pieces of evidence prove the same claim?
- Is reference-only detail being spoken because it was present rather than
  because the listener needs it?

Return to the spine, consolidate supporting material, and draft again. If the
smallest faithful spine still triggers the warning, keep the warning visible. Ask
the user only when the proposed remedy changes the agreed deliverable—for example,
splitting one guide into a series. A warning alone is not a reason to block an
otherwise faithful guide or force it toward a number.

## Selection check

- [ ] The source title, guide kind, spoken topic, listener destination, opening
  orientation, central hook, and explanatory spine are explicit in the private
  plan.
- [ ] The opening orientation appears in the first 2–4 spoken turns rather than
  only in the private plan or comments.
- [ ] Every included detail has a core or representative supporting job.
- [ ] Repeated examples, figures, numbers, and evidence were consolidated.
- [ ] Decision-changing caveats and source qualifications remain intact.
- [ ] Three to six acts organize the selected content without capping it.
- [ ] Size diagnostics informed a qualitative recheck rather than becoming a
  runtime target.
