---
name: author-skill
description: Author, review, or improve a skill. Trigger whenever a skill itself is the subject — any request to create, add, write, edit, update, review, critique, improve, fix, or tweak a skill, however loosely phrased.
---

For a new skill, confirm the name and whether it lives in the project or home before writing anything.

Describe the outcome the agent should reach and why, as a direct imperative — what to do, not what to avoid, stated plainly rather than sold — and keep each skill to a single purpose. A skill steers the agent through words: where the procedure turns on a concept, name it precisely, define it, and hold the agent to that name rather than letting synonyms drift. Consistent language is what makes the behaviour reliable; for some skills, aligning meaning between user, code, and agent is the whole job.

A skill runs in a vacuum: the agent that runs it has none of the conversation you authored it in. That context is easy to leak onto the page — write for a stranger, and keep the content independent of the task at hand.

## Three tiers

A skill spreads its content across three tiers, each paid for differently; put each piece where its frequency-of-need matches its cost.

The **description** is all the agent sees when deciding whether to load the skill, so keep it tiny and tuned for matching. It has two readers: a sentence on what the skill does for the user, then a trigger clause for the agent — the range of verbs and contexts, "however loosely phrased" covering the variants. Third person, under 1024 chars; no quoted examples, which bias matching toward that wording.

**SKILL.md** loads when the skill fires; keep it the always-relevant spine and no more.

A **linked doc** (`[NAME.md](./NAME.md)`) loads only when the agent opens it, so split a piece out only when it is conditional, bulky boilerplate you copy rather than reason with, shared across skills, or a fuller version of something summarised inline — and never fragment the spine, since a doc the agent fails to open at the right moment is worse than inline.

## Structure

Prose is the default; structure is a cost the content has to earn. Reach for headings only when the skill is large enough that the reader holds several things at once — thematic `##` sections when order doesn't matter, numbered steps when the procedure is a genuine sequence the agent walks in order. A short skill needs neither: a `## Process` wrapped around three sentences is more frame than content, and the sequence already reads in the prose. Match the markup to the shape of the work, not to a wish to look organised.

## Reviewing

When asked to review or critique a skill, see [REVIEW.md](./REVIEW.md).

## Simplifying

When asked to simplify or compress a skill, see [SIMPLIFY.md](./SIMPLIFY.md).
