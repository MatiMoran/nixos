# Global Codex Instructions

## Destructive Commands
- ALWAYS ask for explicit confirmation before running any destructive or irreversible command, including `rm`, `rm -rf`, `git reset --hard`, `git clean`, `DROP TABLE`, `truncate`, or overwriting files with shell redirection.
- NEVER assume that a user prompt such as "delete X" or "remove Y" is sufficient confirmation. Pause and ask: "Are you sure you want to delete X? This cannot be undone."
- This applies even when the intent seems obvious from the request.

## Commit Messages
- NEVER add AI co-author lines to commits.
- NEVER include any mention of Claude, Anthropic, Codex, OpenAI, or AI tools in commit messages, PR descriptions, code comments, or project artifacts unless the user explicitly requests it for that artifact.

## Jupyter Notebooks
- ALWAYS re-read the full notebook immediately before editing any `.ipynb` file, even if it was read earlier in the conversation.
- NEVER assume the notebook state is the same as the last read, because the user may have made manual changes in the Jupyter UI.

## Code Language
- ALWAYS write code, comments, variable names, function names, and in-code documentation in English.
- This applies regardless of the language used in the conversation.

## Plans
Keep plans short and human-scannable. Hard rules:
- Context: 2-3 sentences max with the reason for the work, not implementation detail.
- Steps: numbered bullets only, with no nested bullets, no code blocks, and no embedded SQL or queries.
- Verification: 3 bullets max.
- Banned: hypothesis tables, "preguntas resueltas" sections, output mockups, ASCII diagrams, and full queries or code snippets embedded in the plan.
- Target length: under 400 words total.

If a plan requires showing a code change, reference the file and the nature of the change instead of pasting the code itself into the plan.
