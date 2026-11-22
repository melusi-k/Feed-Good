# PRD-021 — Optional Plant Tags

**Status:** Proposal consistent; filtering design gate open  
**Priority:** P2  
**Release:** Post-MVP, after archive compatibility  
**Primary surfaces:** My Plants, Plant Profile, collection search/filter, Settings if tag management is centralised

## 1. One-line goal
Help people find and group plants in a growing collection without introducing multiple gardens, folders, sharing or organisational pressure.

## 2. Users and use cases
A user wants lightweight labels such as “bedroom”, “herbs” or “needs attention” to organise a personal collection. They need tags to remain optional and survive archive/restore.

## 3. Capability targets
| Capability | Acceptance evidence | Ship threshold |
| --- | --- | --- |
| Optional use | UI tests | Collection works without tags |
| Name integrity | Normalisation tests | Case/whitespace duplicates handled consistently |
| Filtering | Filter tests | Multi-tag semantics explicitly documented |
| Archive compatibility | Relationship tests | Archived plants retain tag assignments |
| Portability | Round-trip tests | Tag identity, names and assignments preserved |

## 4. Behavior changes
- Support optional user-created tags on plants.
- Allow creating, renaming, assigning and removing tags.
- Support collection search and tag filtering alongside existing search/sort behavior.
- Keep tags visible and manageable for active and archived plants.
- Preserve tag relationships through export/restore.
- Normalize names consistently and handle duplicates safely.

## 5. Out of scope
Multiple gardens, nested folders, shared spaces, collaboration, permissions, social sharing, automatic/AI categorisation and a complex query builder.

## 6. Surfaces
Tag create/rename/delete controls; plant tag assignment; collection filter; clear-filter action; archived plant tag view.

## 7. Pricing
Included in the local-first app. No account or network service is required.

## 8. Safety and data integrity
- Collection and plant creation remain fully usable without tags.
- Tags are user-authored and never inferred from photos, location or private notes.
- Deleting a tag does not delete a plant or its other records; assignment-removal behavior is explicit.
- Define normalization for leading/trailing whitespace, case and duplicate names.
- Archived plants retain tags; archive/restore must not duplicate or drop assignments.
- Filtering semantics (AND or OR across selected tags) must be decided before multi-tag UI ships.
- “Recently observed” is not a tag; include it only if an existing supported view provides it.

## 9. Launch plan
1. Decide canonical tag-name normalization and duplicate behavior.
2. Decide AND/OR semantics for multi-tag filtering.
3. Implement tag model and assignment with migration strategy.
4. Add collection filtering and easy clear-filter behavior.
5. Extend archive/export/restore and test active/archived relationships.
6. Test normalization, duplicate prevention, rename/delete, filtering, performance and accessibility.

## 10. Replaces
Replaces ad hoc naming/search alone for lightweight collection grouping. It does not replace folders or multiple gardens.

## 11. Decisions and dependencies
- Builds on Plant Collection #1 and Data Portability #15.
- Hard archive compatibility prerequisite: PRD-015 / issue #69.
- Not dependent on PRD-016; Archived is a collection state and must not be encoded as a tag or lifecycle category.
- Name normalization and AND/OR filtering are explicit design gates.

## 12. Delivery tracking
- GitHub issue: [#75 — Add optional plant tags and lightweight collection organisation](https://github.com/melusi-k/Feed-Good/issues/75).
- Status: proposal consistent; design and implementation outstanding.
