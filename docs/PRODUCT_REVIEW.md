# Feed Good — Product Review and Proposal Portfolio

**Review status:** Updated proposal and dependency review  
**Repository baseline reviewed:** `main` at `0ab2535`  
**Proposal status:** Issues #63–66 and #69–75 are marked **Proposal Consistent** in their issue bodies. This is not an implementation-complete or release-approved status.

## Executive summary

Feed Good's product direction remains coherent: practical enough to trust, but personal enough to feel like a journal rather than a watering alarm. The product should deepen trust and relationship with existing records before adding integrations or broad new surfaces.

The current proposal portfolio now covers eleven follow-ups across care-history integrity, growth and reflection, observations, archive/restore, lifecycle semantics, routine review, plant changes, journal prompts, quiet periods and collection organisation. The portfolio is deliberately split into independent workstreams and explicit dependency chains rather than treated as one large release.

The repository already contains a local journal archive/recovery capability under the data-portability work. That must not be confused with the proposed **plant archive** in PRD-015, which is a reversible collection state for an individual plant.

## Current strengths

- **Clear relationship-first promise.** Existing surfaces connect care, observation, learning and plant story rather than treating plants as task containers.
- **Local-first reliability.** Core plant records, care history, journal and guidance are designed to remain useful without an account or network connection.
- **Useful MVP boundaries.** Diagnosis, social features, weather and sensor integrations are deferred rather than presented as supported capabilities.
- **Strong record foundation.** Care events, journal entries, photos, milestones and the existing journal archive/recovery provide durable material for derived experiences.
- **Safety-conscious guidance.** The Care Guide direction uses qualification, provenance and offline availability rather than overconfident recommendations.
- **Respectful motivation.** The product avoids guilt-based mechanics, universal watering assumptions and unnecessary streaks.

## Portfolio overview

### 1. Trust and relationship
- **PRD-011 — Care History Corrections (#63):** PR #68 is merged and supports history-only event correction/deletion. Remaining Today consistency, reminder validity and export/recovery verification remain explicit acceptance work and form a release gate for the #69 parent merge.
- **PRD-012 — Growth Review (#64):** PR #76 contains an initial photo-derived per-plant flow and side-by-side comparison, but remains unmerged. Populated comparison UI coverage, two-photo selection and correct source-observation navigation still need verification.
- **PRD-013 — Weekly Garden Reflection (#65):** a local derived recap from current care/journal records, without streaks, scores or guilt.
- **PRD-014 — Plant Check-ins (#66):** a distinct observation record and cautious offline guidance. No troubleshooting content may ship before editorial/safety ownership, source rules and review approval are in place.

### 2. Data foundation and dependent collection capabilities
- **PRD-015 — Plant Archive and Restore (#69):** reversible persisted collection state; preserves plant identity, story, media, care history and export/restore. This is the selected next foundation. The #63 verification gate must pass before its parent implementation PR merges.
- **PRD-016 — Plant Lifecycle States (#70):** reuses PRD-015 archive state; any additional state needs a distinct user need and an approved transition table. Blocks #74.
- **PRD-018 — Plant Changes Timeline (#72):** structured change records in Plant Story. Requires #69 compatibility and an explicit model decision (typed JournalEntry metadata versus dedicated PlantChange).
- **PRD-021 — Optional Plant Tags (#75):** optional user-authored tags for active and archived plants. Requires #69 compatibility; AND/OR filtering semantics must be decided before multi-tag UI.

### 3. Independent routine and journal capabilities
- **PRD-017 — Care Routine Review (#71):** a review/explanation layer over the existing CareTaskEditor and Plant profile editors. CareTaskEditor owns task type/title, interval, next-care date, enabled state and reminder setting; growing environment/light remain Plant profile properties. This work blocks #74 but is not blocked by #69.
- **PRD-019 — Plant Journal Prompts (#73):** optional bundled prompts whose answers create ordinary JournalEntry records. Weekly Reflection integration is optional; neither issue blocks the other.

### 4. Coordinated care adjustment
- **PRD-020 — Seasonal and Quiet Periods (#74):** user-controlled care pause with explicit preview and resume behavior. It has an AND dependency on both #70 lifecycle decisions and #71 routine/reminder behavior. Pause/resume policy, open-ended due-task handling and all-vs-selected task scope are design gates.

## Dependency rules

| Relationship | Rule |
| --- | --- |
| #63 → #69 | #63 Today/reminder/export verification must pass before the #69 parent PR merges; do not bundle #63 into #69 |
| #69 → #70, #66, #72, #75 | Archive identity and relationship contract is a hard compatibility prerequisite |
| #70 AND #71 → #74 | Both lifecycle transition and routine/reminder policies are required |
| #64, #65, #71, #73 | Independent of #69; must still respect archived visibility and disable active-care actions |
| #65 ↔ #73 | Optional integration only; neither blocks the other |
| #64 ↔ #65 | Independent workstreams |

## Delivery and product gates

1. **Do not confuse proposal consistency with delivery.** The status in an issue confirms that scope, acceptance criteria and dependencies are internally aligned. It does not mean implementation is complete, scheduled, tested or approved for release.
2. **Preserve source-of-truth boundaries.** Derived experiences read existing records; journal prompts write ordinary JournalEntry records; archive is not deletion; lifecycle state is not a tag; quiet period is not archive.
3. **Keep safety gates real.** Plant Check-in troubleshooting content requires accountable editorial/safety ownership and reviewed source material before shipping.
4. **Resolve design gates before coding.** Plant-change model choice, lifecycle transition table, quiet-period pause/resume rules and multi-tag filter semantics must be decided and recorded.
5. **Verify at exact head.** CI, unit/UI coverage, accessibility, privacy, offline behavior and physical-device evidence are recorded separately. A green build alone is not acceptance.

## Explicitly deferred ideas

The review does not recommend starting with home-screen widgets, Live Activities, multiple gardens or shared spaces, social/community features, weather and sensor integrations, plant identification or AI diagnosis. These add notification, privacy, data-quality or product-complexity commitments before the core relationship loop is mature.

AI diagnosis is intentionally deferred. Feed Good's differentiation is careful noticing and trustworthy guidance, not certainty from an image. Any future exploration needs a separate product and safety decision.

## Conclusion

The eleven proposals now form a coherent portfolio with explicit scope, boundaries and dependencies. The next implementation decision remains the archive foundation (#69), subject to the independent #63 release gate. Other work should proceed only where dependencies and capacity permit, with design gates resolved before implementation and no proposal described as delivered prematurely.
