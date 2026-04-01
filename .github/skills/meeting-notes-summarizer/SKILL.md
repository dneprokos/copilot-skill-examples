---
name: meeting-notes-summarizer
description: >-
  Turn raw meeting transcripts, messy notes, or unstructured bullet points into a
  clean, structured summary for Microsoft Teams or email. Extracts a short summary,
  key decisions, action items with owners and due dates, main discussion topics,
  and a parking lot for unresolved items. Flags unclear content instead of guessing.
  Preserves people's names as they appear in the source. Use when the user asks to
  summarize meeting notes, clean up notes, or prepare a shareable recap.
argument-hint: "raw notes or transcript text"
---

# Meeting Notes Summarizer

Transform rough input into a **paste-ready** recap suitable for Teams or email.

## When this skill fits

Use it for requests like:

- "summarize these meeting notes"
- "clean up this transcript"
- "turn these bullets into a meeting recap"
- "prepare notes I can paste into Teams"

Do **not** use it for:

- live meeting capture or transcription (no real-time Teams integration)
- legal or compliance review (use a human reviewer)
- inventing decisions or actions that are not supported by the text

## Inputs

The user may provide one or more of:

- raw **transcripts**
- **messy** notes or copy-paste
- **unstructured bullet points**

If no text is provided, ask the user to paste the meeting content before summarizing.

## Output format

Produce **exactly one** response using the section order below. Use plain structure (headings and bullets) so it pastes cleanly into Teams or email.

Mirror the structure in [references/output-template.md](./references/output-template.md) for consistency.

### Required sections (always include these headings)

1. **Summary** — 2–3 sentences capturing what the meeting was about and the overall outcome.
2. **Key decisions** — Bullet list of decisions **explicitly** stated in the input. If none: write exactly `No decisions captured.` (or one line stating none were stated).
3. **Action items** — Bullets with **owner** and **due date** when the source gives them (e.g. `Name — task — due YYYY-MM-DD`). If none: write exactly `No action items captured.` or `No action items were stated in the notes.`
4. **Discussion topics** — Main themes or topics discussed. If none: say so explicitly.
5. **Parking lot** — Items deferred, unresolved, or explicitly parked for later. If none: say so explicitly.

## Workflow

### 1. Ingest the source

Read the user's text as the only source of truth. Do not add facts from outside the message.

### 2. Draft the structured summary

Use the required sections and the template. Keep wording tight and professional.

### 3. Handle gaps and ambiguity

- If something is **unclear** or **contradictory**, say so in the relevant section (e.g. "Unclear: …") rather than guessing.
- If an **owner** or **due date** is missing for an action, state the action and mark owner/date as unclear or omitted.

### 4. Names and tone

- Use **people's names exactly as they appear** in the notes (spelling and form).
- Do not rename or normalize names unless the user asks.

### 5. Empty sections

- Do **not** remove a section because it is empty. Use the explicit empty-state lines from the Output format section.

## Hard rules

- Never invent decisions, action items, or commitments not supported by the input.
- Prefer flagging uncertainty over filling gaps.
- Keep the output usable with **no required editing** for a typical Teams post or email (optional greeting/sign-off one line each if the user asks).
