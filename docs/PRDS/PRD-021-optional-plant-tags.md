# PRD-021 — Optional Plant Tags and Lightweight Collection Organisation

**Status:** Proposed for post-MVP product review  
**Priority:** P2 usability feature  
**Release:** After core collection and archive behavior are stable  
**Primary surfaces:** My Plants, Plant Profile, search and filters

## 1. One-line goal

Help people find and group plants in a growing collection while keeping tags optional, local and simpler than multiple gardens or folders.

## 2. Users and use cases

A user keeps plants in different rooms, has a propagation group, or wants to find plants that need observation. They want lightweight personal labels without completing extra setup or adopting a complex organization system.

## 3. Capability targets

| Capability | Eval / acceptance check | Baseline | Ship threshold | Owner / date |
| --- | --- | --- | --- | --- |
| Optionality | Use collection normally without tags | [measure] | [target: no-tag journey passes] | [owner] / [date] |
| Findability | Filter/search by user-authored tags | [measure] | [target: collection tests pass] | [owner] / [date] |
| Safe editing | Rename/remove tags without record loss | [measure] | [target: relationship tests pass] | [owner] / [date] |
| Portability | Preserve tags in export/restore | [measure] | [target: archive round-trip passes] | [owner] / [date] |

## 4. Behavior changes

- Add optional user-created tags to plants.
- Let users add, remove, rename and delete tags without requiring tags for any plant.
- Support collection search and filtering by tags alongside existing search and sorting.
- Keep active/archived and recently observed views as domain filters rather than forcing users to recreate them as tags.
- Normalize duplicate names by trimming whitespace and applying a documented case policy.
- Preserve tags through export and restore.
- Keep the feature usable offline and with long tag names or many plants.

## 5. Out of scope

- Multiple independently managed gardens or shared spaces.
- Folder hierarchies, permissions, collaboration or social sharing.
- Automatic tagging, AI categorization or location-based tags.
- A complex query builder in the first release.

## 6. Surfaces

- Plant Profile tag editor.
- Collection tag filter/search controls.
- Tag management view.
- Empty, no-match and reset-filter states.
- Export/restore behavior.

## 7. Pricing

Included in the local-first app. No account, subscription or network service is required.

## 8. Safety bar

- Tags are user-authored labels, not facts inferred by Feed Good.
- Never require tags during onboarding or plant creation.
- Do not expose private tags in notifications.
- Make filter state visible and easy to clear.
- Support VoiceOver, Dynamic Type, long names and colour-independent meaning.

## 9. Launch plan

1. Confirm the smallest tag model and matching behavior; start with one-tag filtering if needed.
2. Define normalization, duplicate handling, deletion and archive contracts.
3. Implement collection filtering without a second source of plant truth.
4. Add persistence, migration, export/restore and UI tests.
5. Verify performance with many plants and accessibility on device.

## 10. Replaces

Replaces the need for multiple gardens or folder hierarchies for basic personal grouping. It does not replace shared spaces or advanced collection management.

## 11. Decisions and open questions

Decide whether multi-tag filtering uses AND or OR semantics; a single-tag first release is the safest scope. Decide whether tags are globally managed or edited primarily from plant profiles. Keep tags optional regardless of the final management surface.

## 12. Delivery tracking

- GitHub implementation issue: [#75 — Add optional plant tags and lightweight collection organisation](https://github.com/melusi-k/Feed-Good/issues/75).
- Existing PRD: [PRD-001 — My Plants](PRD-001-my-plants.md).
- Explicitly deferred: multiple gardens/spaces and shared organization.
