# Bundled daily moments, content version 1

Implements issue #16. Seven reflections and seven general houseplant tips ship in the app, with no content fetch, account, notification or plant-data dependency. The optional source link needs internet; the content and its provenance sheet do not.

## Editorial boundary

Reflections are original Feed Good copy written for this slice. They have an assistant editorial check for brevity, warmth, absence of guilt and separation from factual advice. They are labelled as reflections, not care instructions.

Tips are paraphrased general education, not quotations, diagnoses or instructions tailored to a user's plants. Each has a stable ID, kind, source title/URL/section, review status, review date and reviewer description in `DailyMoments.swift`. The source-check date is 2026-11-21. Review status is explicitly **source checked, not expert reviewed**. No horticulturist sign-off or human editorial approval is claimed. The PR reviewer should review the bundled copy before merge.

## Source ledger and scope

- University of Missouri Extension, *Caring for Houseplants*, revised by David H. Trinklein, July/October 2017: https://extension.missouri.edu/publications/g6510
  - `tip.check-first`: Watering, no one schedule fits all plants; conditions affect drying.
  - `tip.drainage`: Drainage, outer coverings can hide standing water.
  - `tip.light-change`: Lighting, abrupt moves into stronger light can damage leaves.
  - `tip.heat`: Temperature, hot air from heaters can damage leaves.
  - `tip.fertiliser`: Fertilizing, follow product directions and avoid excess.
  - `tip.observe-light`: Lighting and Fertilizing, extra water/fertiliser does not fix poor light.
- University of Wisconsin Extension, *Houseplant Care*: https://hort.extension.wisc.edu/articles/houseplant-care/
  - `tip.inspect`: Pests and Diseases, inspect leaf undersides and growing tips.

Both pages were read, not inferred from search excerpts. No species-specific schedules, fertiliser doses, pesticide advice, hemisphere-based seasonal rules or diagnosis claims are bundled. Broad recommendations from sources are narrowed to observation and low-risk general principles. Sources contain additional advice that is not endorsed or copied into this library.

## Day selection

Selection uses the local civil date with Gregorian arithmetic, anchored to 2000-01-01, and positive modulo for dates before the anchor. The user's calendar timezone is kept; the calendar identifier does not change the rotation. Each library cycles every seven days. There is no randomness or persisted rotation state. Travelling across a date boundary can change the item.

Today checks the date every minute while active, so content changes within a minute after midnight. Reopening Today also computes the current selection. The day calculation uses calendar days, not 86,400-second intervals, to avoid DST skips/repeats. Empty, wrong-kind or unreviewed candidate libraries use a checked bundled fallback.

## Review and correction process

The repository owner reviews changes through PRs. For a correction, edit or remove the affected stable ID in the bundled library, re-check the cited source and generality, update its reviewer/date/status, and increment `contentVersion`. Do not silently turn an unchecked tip into source-checked copy. Run date/metadata/fallback tests and the Today UI journey, inspect the simulator screenshots, and ship the correction in an app update. There is no remote content switch in v1.

Seven-day repeat length and visible source/review sheet are implementation defaults for this PR, not a claim that the draft PRD's open editorial-owner or library-size questions have been approved.

## Verification

Unit tests cover same-day stability, seven-day uniqueness/repeat, midnight/year/leap-day transitions, DST, timezone and calendar-identifier behavior, pre-anchor dates, metadata and safe fallback. UI tests keep reflection and tip distinct, inspect the source/review sheet and save labelled simulator attachments. CI is the executable check; physical-device and accessibility visual acceptance remain separate.
