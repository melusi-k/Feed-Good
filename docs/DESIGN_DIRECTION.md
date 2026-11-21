# Feed Good — Visual Direction

## Design intent

Feed Good is a gardening companion with the practical reliability of an assistant and the personality of a journal.

The visual identity should help people build a relationship with their plants, rather than simply reminding them to water. It should feel calm, observant, optimistic and quietly useful.

The supplied visual references are inspiration, not templates. Feed Good should not reproduce their layouts, iconography, component styling or screen compositions.

## What we are taking from the references

- A botanical palette grounded in greens and warm, natural neutrals.
- Plant photography treated as meaningful content, not decoration.
- A welcoming home experience with a clear sense of what needs attention.
- Plant profiles that combine visual identity with practical care information.
- Care schedules that are understandable at a glance.
- Generous spacing, restrained surfaces and approachable interactions.

## What makes Feed Good distinct

- **Relationship over reminders:** care actions sit within the ongoing story of each plant.
- **A living plant journal:** observations, photos and milestones should feel as important as scheduled tasks.
- **Encouragement without guilt:** the interface never shames someone for a missed task or a struggling plant.
- **Guidance with context:** explain why an action may help and distinguish general guidance from confirmed plant-specific facts.
- **A sense of progress:** highlight new growth, recovery and small moments worth noticing.

## Visual principles

### 1. Botanical, not ornamental

Use a restrained range of greens, soft off-whites and earthy supporting tones. Avoid turning every surface green or filling the interface with decorative leaves. Botanical character should come from the palette, photography, typography and small details working together.

### 2. Warm, readable surfaces

Use a warm neutral canvas with clear surface hierarchy. Cards should be purposeful and lightweight. Prefer subtle tonal separation and fine borders over heavy shadows, excessive gradients or stacked containers.

### 3. Plants are the protagonists

Give plant photography room to breathe. Use consistent image framing and avoid cropping that hides the plant's defining shape. Where a user has not added a photo, provide a considered illustrated or neutral placeholder rather than a generic stock-looking image.

### 4. Editorial moments

Use short, thoughtful copy for daily reflections, plant milestones and journal prompts. Pair these moments with practical actions, but do not make every screen feel like a feed or quote card.

### 5. Quietly clear interaction

Use obvious labels, accessible touch targets, readable contrast and predictable navigation. Motion should be gentle and purposeful: confirming an action, revealing a detail or marking a milestone.

## Initial semantic colour direction

These are proposed design tokens, not final accessibility-approved values. Validate contrast in light and dark appearances before shipping.

| Token | Direction | Intended use |
| --- | --- | --- |
| Canvas | Warm botanical ivory | Main app background |
| Surface | Soft white | Cards, sheets and grouped content |
| Canopy | Deep leafy green | Primary actions and selected states |
| Sage | Muted grey-green | Secondary emphasis and quiet surfaces |
| Moss | Mid botanical green | Supporting accents and care indicators |
| Soil | Warm charcoal-brown | Primary text and grounding details |
| Mist | Pale cool green-grey | Dividers, subtle backgrounds and placeholders |
| Bloom | Restrained warm accent | Occasional milestones and positive moments |

Avoid assigning meaning based on colour alone. Pair care states with labels and symbols.

## Typography

Use the native iOS system type family as the starting point. Establish a clear hierarchy:

- Editorial headline for welcome messages and meaningful plant moments.
- Strong section title for screen structure.
- Readable body text for care guidance and journal entries.
- Compact secondary text for dates, metadata and status.

Keep type sizes comfortable and support Dynamic Type. Avoid overly delicate weights for essential information.

## Core experience direction

### Home — Today in your garden

The home screen should feel like a thoughtful check-in, not a dashboard of overdue work.

Suggested content order:
1. A warm welcome and a short daily thought or seasonal observation.
2. A concise care check-in showing only the most relevant actions.
3. A visual view of the user's plants, with gentle status context.
4. A journal prompt or recent plant moment that invites observation.

Do not use urgency-red task badges as the default visual language. Distinguish due, upcoming and optional care without implying every schedule is a hard deadline.

### Plant profile — A story and a care guide

A plant profile should combine:
- A prominent plant photo and its chosen name.
- A small, useful summary of its current care context.
- The next relevant care action, with a reason where possible.
- A readable care guide for light, water, soil and other relevant needs.
- A timeline of journal entries, care activities and milestones.

The profile should not become a dense diagnostic dashboard. Only show measurements when the user has supplied them or a trustworthy source supports them.

### Care — Helpful, explainable routines

Care schedules should be plant-specific and user-controlled. Show the last completed action and the next suggested check-in. Avoid implying that a fixed watering interval is universally correct.

### Journal — The relationship over time

Make it easy to add a dated note or photo in a few seconds. Entries should be attached to a plant and form a chronological story. Celebrate observations such as a new leaf, a change in position, flowering or recovery.

## Navigation direction

Keep the primary navigation small and focused. The initial information architecture can be:

- **Today** — check-in, relevant care and recent moments.
- **My Plants** — the collection and plant discovery/add flow.
- **Journal** — observations and milestones across the garden.

Settings and notification preferences should remain accessible without competing with these core destinations. Revisit navigation after the first working prototype rather than locking in a complex tab bar prematurely.

## Component character

- Rounded corners, but not excessively pill-shaped containers everywhere.
- Primary buttons use the deep green token with clear text labels.
- Secondary actions use quiet outlines or text buttons.
- Care status uses a small icon plus a plain-language label.
- Plant cards prioritise photo, plant name and one useful piece of context.
- Empty states invite a first action and explain the value of taking it.
- Forms should feel short, friendly and forgiving.

## Product voice

Feed Good should sound like a knowledgeable, encouraging plant friend: warm, observant and practical.

Prefer:
- “Your Monstera has a new leaf. Add it to its story.”
- “Time to check the soil.”
- “Your plant was last watered 6 days ago.”
- “Not sure? Take a moment to see how it’s doing.”

Avoid:
- “You failed to water your plant.”
- “Your plant is dying” without reliable evidence.
- Overconfident diagnosis or prescriptive quantities without adequate context.

## Design acceptance checklist

A screen is aligned when:

- The plant and its story are more prominent than app chrome.
- The next useful action is easy to identify.
- Care guidance is understandable and appropriately qualified.
- The screen feels calm rather than busy or gamified.
- Colour is not the only way status is communicated.
- Text remains legible with accessibility settings.
- The experience encourages curiosity and care, never guilt.
- The composition feels recognisably Feed Good rather than a recreation of either reference.

## Implementation sequence

1. Refine semantic theme tokens and reusable typography/spacing styles.
2. Build the Today and My Plants foundations with realistic sample content.
3. Establish a plant profile layout with a clear distinction between care and journal history.
4. Add the journal entry pattern before introducing complex care analytics.
5. Validate the visual system in simulator at multiple device sizes and Dynamic Type settings.
6. Review light and dark appearance, accessibility contrast and empty states before expanding the component set.
