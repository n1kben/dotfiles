---
name: notate
description: Render anything with an inherent shape. Trigger when the user wants something shown as structure instead of paragraphs — notate, outline, sketch — however loosely phrased.
---

When a thing has a shape, show the shape — don't describe it in prose. Think component trees, call graphs, type signatures, interfaces, decision trees, pseudocode.

Default to a plain indented markdown list with dashes; it carries most cases. Keep to left-edge indentation, you MUST skip box-drawing and aligned columns. Set annotations off with parentheses or a similar token. Pick the fence language from the set below; if a shape fits none, fall back to the list — don't invent notations.

- **The codebase's own language** — component trees, call graphs, type signatures, function interfaces. Match whatever the surrounding code uses.
- **`elm`** — types and function interfaces when no codebase language fits; its signature syntax is the cleanest fallback.
- **`sql`** — tabular or relational data.
- **`gherkin`** — flows and scenarios, as Given / When / Then.
- **No language** — generic trees, flows, and pseudocode not tied to a codebase, where indentation alone carries the nesting. Pseudocode beats prose for any non-trivial algorithm or control flow.
