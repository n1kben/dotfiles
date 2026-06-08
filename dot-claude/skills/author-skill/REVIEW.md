# Reviewing a skill

Audit the skill against each convention in [SKILL.md](./SKILL.md). The convention is stated there; this is how you catch it breaking — the smell, not the rule. Take SKILL.md for what it says, not how it says it: apply its conventions, but never carry its prose style, voice, or stock phrasing into the skill under review — judge the skill's content on its own terms. Work the checks in order: each is moot if an earlier one fails, and a skill that won't fire needn't be single-purpose.

- **Trigger** — first, because a skill that doesn't fire does nothing else. Don't read the description, attack it: type the phrasings a user would actually send and check it fires; type the neighbouring requests it shouldn't own and check it stays quiet. Misfires trace to a vague verb, an unstated context, or quoted examples.
- **Single purpose** — the *and* test: a description joining two jobs, or a second `##` section that could stand alone as its own skill, is two skills wearing one name. Catch it early — splitting later is costly.
- **Intent** — read the opening cold and ask *is this the outcome, or a method standing in for one?* "To X, do Y" is the usual disguise: Y is named, X is missing. Then check it instructs rather than sells — pitch words like "at a glance" or "effortlessly" are the tell.
- **Language** — pick the load-bearing concept and trace it through the skill: the same term every time, or does a synonym slip in? The drift is invisible on a read-through — only tracing the one term catches it.
- **Self-containment** — read the skill cold, as the stranger who runs it in a vacuum. Flag anything that leans on the authoring conversation rather than standing on its own. It slips past the author, who supplies the missing context unconsciously.
- **Tier fit** — wrong-tier content is the quiet failure, so test placement rather than read it: each spine sentence against *needed every run?* and each linked doc against *only sometimes?* — a no either way means it sits in the wrong tier.
- **Fluff** — last and cheapest: every sentence must change what the agent would otherwise do. Catch it here; cut it with [SIMPLIFY.md](./SIMPLIFY.md).
