---
name: author-skill
description: Author, review, or improve a skill. Trigger whenever a skill itself is the subject — any request to create, add, write, edit, update, review, critique, improve, fix, or tweak a skill, however loosely phrased.
---

For a new skill, confirm the name and whether it lives in the project or home before writing anything.

Describe the outcome the agent should reach and why, in a direct imperative. Frame it as what to do rather than what to avoid — the agent follows positive direction far better than prohibitions. Keep each skill focused on a single purpose, and keep SKILL.md concise: under 100 words, prose, no headings or lists.

Lean on progressive disclosure: push detail into flat, caps-named docs in the skill folder, linked from SKILL.md as `[SOME-REF.md](./SOME-REF.md)`. Those docs can be as structured as they need to be.

When work is deterministic — validation, formatting, the same boilerplate every run — bundle a script in the folder and have the skill call it; that beats regenerating code for reliability and tokens.

The description is all the agent sees when deciding whether to load the skill. Write it third person, under 1024 chars: one sentence on what it does, then a trigger clause. Generalize — name the range of verbs and contexts, let "however loosely phrased" carry the variants. Skip quoted examples; they bloat it and bias matching toward that exact wording.
