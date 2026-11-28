# Feed Good diagram atlas

Diagrams are grouped by their owning product requirements document (PRD). Directory names use the PRD identifier and kebab-case title. The PRD remains the source of truth; diagrams are explanatory views and must not silently resolve open product decisions.

## Foundational atlas

| PRD | Diagram | Status |
|---|---|---|
| [PRD-001 — My Plants](../PRDS/PRD-001-my-plants.md) | [Application architecture](PRD-001-my-plants/application-architecture.svg) | Current architecture snapshot; cross-cutting anchor |
| [PRD-022 — Care Activity Lifecycle and Occurrence Management](../PRDS/PRD-022-care-activity-lifecycle.md) | [Care activity lifecycle](PRD-022-care-activity-lifecycle/care-activity-lifecycle.svg) | Delivered lifecycle foundation and opportunity ledger; skip/snooze deferred |
| [PRD-020 — Seasonal and Quiet Periods](../PRDS/PRD-020-seasonal-quiet-periods.md) | [Quiet period scheduling contract](PRD-020-seasonal-quiet-periods/quiet-period-scheduling.svg) | Delivered pause-clock contract (#121–125); issue #74 closed |
| [PRD-009 — Settings & Data Portability](../PRDS/PRD-009-settings-data-portability.md) | [Export and recovery](PRD-009-settings-data-portability/export-recovery.svg) | Delivered archive v1–v6; check-in extension included; additive versions governed by owning PRDs |
| [PRD-024 — Care Insights and Plant Health Story](../PRDS/PRD-024-care-insights-and-plant-health-story.md) | [Care insights and plant story](PRD-024-care-insights-and-plant-health-story/care-insights-data-lineage.svg) | Approved contract; analytics, streaks and insights slice delivered; check-ins gated |

## Maintenance rules

- Update the relevant diagram when its PRD's approved behavior or implementation contract changes materially.
- Label unresolved decisions as open; never convert a proposal into an implementation fact.
- Prefer SVG for portable, reviewable vector output. Keep source files in Git and avoid opaque exports.
- Review diagram changes alongside the PRD and implementation diff.
- Cross-cutting diagrams live under the most relevant owning PRD and identify that scope explicitly.
