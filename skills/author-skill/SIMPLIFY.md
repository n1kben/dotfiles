# Simplifying a skill

A skill is the delta against what the model already does — every sentence must change the agent's behaviour, or it's fluff. But the delta is measured against a nondeterministic model: you can't settle it by deleting a line and judging whether behaviour degrades, because the verdict shifts run to run. So cut deterministically first, and reason only about what's left.

**Deterministic — read off the page.** Cut every restated default, hedge, decoration on a *why* that tips no decision, and case some shorter principle already covers; relocate bulk that earns its keep but isn't always needed into a linked doc. These are the same cuts on every read, no model judgement needed.

**Judgement — the rest.** Raise altitude where you've scripted steps the agent can derive. Where you can only guess whether a line changes behaviour, keep it unless you're confident it doesn't.

Stop when removing the next word would change what the agent does — the target is behaviour per token, not fewest tokens.
