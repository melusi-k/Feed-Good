# Feed Good — Product Review and Next Features

**Review status:** Complete  
**Repository baseline:** `main` at `357f2b1` (`build-39`)  
**Documentation branch:** `docs/product-review-next-features`

## Executive summary

Feed Good already has a strong local-first MVP foundation: plant collection and profiles, optional growing context, care routines and reminders, care history, journal entries and photos, milestones, a combined plant story, Today, daily learning, offline care guidance and local archive/recovery. The product direction is coherent: practical enough to trust, but personal enough to feel like a journal rather than a watering alarm.

The most valuable next work should deepen trust and relationship with existing records before adding more surfaces or integrations. The review therefore recommends four focused follow-ups:

1. **Care History Corrections** — let people repair a mistaken record without silently changing schedules.
2. **Growth Review** — make change easier to notice using existing journal photos.
3. **Weekly Garden Reflection** — offer a quiet look-back without streaks, scores or guilt.
4. **Plant Check-ins and Cautious Troubleshooting** — record observations and provide reviewed offline next checks without diagnosis.

The first three are primarily product and interaction work over existing local data. The fourth is explicitly safety- and editorial-gated.

## Current strengths

- **Clear relationship-first promise.** The existing surfaces connect care, observation, learning and plant story rather than treating plants as task containers.
- **Local-first reliability.** Core records remain useful without accounts or network access, matching the product's privacy and resilience principles.
- **Useful MVP boundaries.** The repository already defers diagnosis, social features, weather and sensor integrations instead of implying unsupported capabilities.
- **Strong record foundation.** Care events, journal entries, photos, milestones and archive/recovery create enough durable material for meaningful derived experiences.
- **Safety-conscious guidance.** The Care Guide direction uses qualification, provenance and offline availability rather than overconfident recommendations.
- **Respectful motivation.** The product avoids guilt-based mechanics, universal watering assumptions and unnecessary streaks.

## Gaps worth addressing next

### 1. Mistakes are difficult to repair

The current care history is effectively append-only from the user's perspective. A wrong plant, date or note can remain visible indefinitely, which weakens the assistant-like reliability of the product. Correction must be deliberately separated from schedule changes so a repair does not create a second kind of surprise.

### 2. Growth is present but hard to see

Journal photos and milestones already exist, but users must manually traverse the story to compare change. A derived per-plant review can add relationship value without introducing computer vision, cloud storage or health claims.

### 3. The garden has no calm look-back

Today helps with the present, while Plant Story preserves chronology. A weekly reflection can connect the two: not as a performance report, but as a small reminder of what the person noticed and did.

### 4. “Something looks different” lacks a safe path

Users can journal observations, but the app does not yet offer a structured way to move from noticing to checking. This is a promising learning feature only if the first release stays small, qualified, offline and editorially owned.

## Recommended priority sequence

| Priority | Proposal | Why now | Main dependency |
| --- | --- | --- | --- |
| P1 | [PRD-011 — Care History Corrections](PRDS/PRD-011-care-history-corrections.md) · [Issue #63](https://github.com/melusi-k/Feed-Good/issues/63) | Repairs a direct trust failure in an existing core surface | Confirm history-only schedule policy |
| P1/P2 | [PRD-012 — Growth Review](PRDS/PRD-012-growth-review.md) · [Issue #64](https://github.com/melusi-k/Feed-Good/issues/64) | Turns existing photos and milestones into visible relationship value | Confirm temporary comparison interaction |
| P2 | [PRD-013 — Weekly Garden Reflection](PRDS/PRD-013-weekly-garden-reflection.md) · [Issue #65](https://github.com/melusi-k/Feed-Good/issues/65) | Makes the journal-like promise visible over time | Validate tone and Today cadence |
| P2 / safety-gated | [PRD-014 — Plant Check-ins](PRDS/PRD-014-plant-check-ins.md) · [Issue #66](https://github.com/melusi-k/Feed-Good/issues/66) | Helps users learn from observations without claiming diagnosis | Name editorial owner and review process |

## Recommended delivery shape

Ship the first tranche as focused, independently reviewable PRs. Start with care-history correction because it addresses user trust and clarifies a reusable principle: correcting a record must not silently mutate an active routine. Follow with Growth Review because it is a bounded projection over existing journal data. Reflection should follow once Today tone and local-calendar behavior are agreed. Check-ins should not enter implementation until the content safety gate is staffed.

Each PR should preserve local-first behavior, archive compatibility, accessibility and explicit physical-device verification. Derived surfaces should read current records rather than create duplicate sources of truth.

## Explicitly deferred ideas

The review does **not** recommend starting with home-screen widgets, Live Activities, multiple gardens or shared spaces, social/community features, weather and sensor integrations, plant identification or AI diagnosis. These may become useful later, but they add notification, privacy, data-quality or product-complexity commitments before the current relationship loop is fully understood.

In particular, AI diagnosis is intentionally deferred. Feed Good's strongest differentiation is careful noticing and trustworthy guidance, not certainty from an image. Any future exploration should begin with a separate safety and product decision, not be smuggled into Plant Check-ins.

## Open product decisions

- Whether care-history correction remains history-only permanently or later offers an explicit “use as latest completion” schedule action.
- Whether Growth Review uses side-by-side or swipe comparison at narrow iPhone widths.
- Whether Weekly Reflection appears every local calendar week, only after activity, or only when manually opened.
- Who owns editorial review, source selection and correction turnaround for troubleshooting content.
- Whether check-ins extend `JournalEntry` or use a separate model while preserving the existing story and archive contracts.

## Conclusion

Feed Good does not need more breadth to prove its direction. It needs a few carefully chosen ways to make existing records more trustworthy, more visible and more emotionally meaningful. The four linked PRDs and issues provide that next development sequence without weakening the product's privacy, offline, accessibility or no-guilt commitments.
