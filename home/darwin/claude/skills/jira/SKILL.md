---
name: jira
description: >
  Use this skill for ANY Jira operation at Mercado Libre. Always use it when
  the user mentions a Jira issue key (like MLDSP-123, PROJ-456), asks to
  create a ticket, move a card, transition an issue, assign something, add a
  comment, search Jira, or manage sprints. Triggers on: /jira, "create ticket",
  "create issue", "create a bug", "create a story", "open a ticket",
  "show me PROJ-N", "what's the status of", "move to sprint", "move to current
  sprint", "transition to", "move to In Progress", "move to Done", "close this
  ticket", "assign to me", "assign to", "add a comment", "comment on",
  "search jira", "my open issues", "what's in the sprint", "list sprints",
  "link this issue", "add a blocker", "what tickets are blocked". Use this skill
  even for casual requests like "put that ticket in progress" or "can you close
  MLDSP-762". When in doubt, use this skill.
---

# Jira Skill

Interact with Jira at `mercadolibre.atlassian.net` via the `mcp-atlassian` MCP
server. All tools are prefixed `mcp__mcp-atlassian__jira_*`.

**Default project:** `MLDSP` — use it when the user doesn't specify a project.

---

## Available Tools

| Tool | Purpose |
|------|---------|
| `jira_get_issue` | Fetch issue details |
| `jira_search` | JQL search |
| `jira_create_issue` | Create a new issue |
| `jira_update_issue` | Edit fields (summary, description, priority, etc.) |
| `jira_get_transitions` | List available status transitions for an issue |
| `jira_transition_issue` | Move issue to a new status |
| `jira_add_comment` | Post a comment |
| `jira_get_agile_boards` | List boards for a project |
| `jira_get_sprints_from_board` | List sprints (active/future/closed) |
| `jira_add_issues_to_sprint` | Move issue(s) to a sprint |
| `jira_get_sprint_issues` | List issues in a sprint |
| `jira_create_issue_link` | Link two issues (blocks, relates to, etc.) |
| `jira_get_link_types` | List available link types |
| `jira_get_user_profile` | Look up a user's accountId by email |
| `jira_get_all_projects` | List all accessible projects |

---

## Core Operations

### Viewing an Issue

Fetch with `jira_get_issue`. Present the result clearly:
- Key, summary, status, assignee, priority, issue type
- Description (summarize if long)
- Sprint (from `customfield_10020` if present)
- Recent comments if relevant

### Searching Issues

Use `jira_search` with JQL. Common patterns:
- My open issues: `assignee = currentUser() AND statusCategory != Done ORDER BY updated DESC`
- Project backlog: `project = MLDSP AND sprint is EMPTY AND statusCategory != Done`
- Current sprint: `project = MLDSP AND sprint in openSprints() ORDER BY status ASC`
- By text: `project = MLDSP AND text ~ "payment" ORDER BY created DESC`

Present results as a compact list: `KEY — Summary (Status, Assignee)`.

### Creating an Issue

Use `jira_create_issue`. Required fields:
- `project_key`: default `MLDSP` unless specified
- `summary`: always required
- `issue_type`: default to `Task` unless the user explicitly specifies a different type (e.g., "create a bug", "create a story", "create an epic")
- `priority`: default to `Medium` unless the user signals urgency (then `High`) or trivial work (then `Low`)

For description, use plain text — the MCP handles formatting.

**Language:** Always write the summary and description in Spanish, regardless of the language the user uses to make the request.

**Slack context:** If the issue originates from a Slack thread, always include the thread URL in the description (e.g. under a "Contexto" or "Referencia" section) so there's a direct link back to the conversation.

After creation, report the new issue key and a link: `https://mercadolibre.atlassian.net/browse/KEY`.

**Assigning during creation:** If the user says "assign to me" or similar, pass `assignee` as `matiasnicolas.moran@mercadolibre.com` directly in the create call.

### Assigning an Issue

Use `jira_update_issue` with `assignee` set to the user's email — the MCP accepts email directly, no profile lookup needed.

- "assign to me" → use `matiasnicolas.moran@mercadolibre.com`
- "assign to [name/teammate]" → ask for their email if you don't have it

### Transitioning an Issue

Transitions are project-specific — never guess transition IDs.

1. Call `jira_get_transitions` to see what's available for this issue.
2. Match the user's intent to the closest transition name (e.g., "done" → "Done", "start" → "In Progress", "block" → whatever blocking transition exists).
3. Call `jira_transition_issue` with the matched transition ID.
4. Confirm the new status.

Common intent mappings to watch for:
- "start", "begin", "working on it", "in progress" → In Progress (or equivalent)
- "done", "finish", "close", "complete", "ship it" → Done (or equivalent)
- "review", "PR up" → In Review / Code Review (if it exists)
- "block", "blocked" → Blocked (if it exists)
- "reopen", "back to backlog" → To Do / Open (or equivalent)

### Adding a Comment

Use `jira_add_comment`. Keep it conversational — don't over-format unless the user provides structured content.

### Sprint Management

**Moving an issue to the current sprint:**
1. `jira_get_agile_boards` with the project key to find the board ID.
2. `jira_get_sprints_from_board` with `state = "active"` to get the active sprint ID.
3. `jira_add_issues_to_sprint` with the sprint ID and issue key.
4. Confirm with sprint name and end date.

If there's no active sprint, look for the next `future` sprint and ask the user to confirm before moving.

**Viewing the active sprint:**
Use `jira_get_sprint_issues` after finding the active sprint. Group by status when presenting.

**Listing sprints:**
Use `jira_get_sprints_from_board` with `state = "active,future"` and show name + dates.

### Linking Issues

1. `jira_get_link_types` to see available link types (blocks, is blocked by, relates to, duplicates, etc.).
2. Match user intent to the right type.
3. `jira_create_issue_link` with inward/outward issue keys.

Common intents:
- "this blocks X" / "X is blocked by this" → "Blocks" link
- "related to" / "similar to" → "Relates"
- "duplicate of" → "Duplicates"

---

## Output Style

- Always show the Jira URL after create/transition/sprint actions: `https://mercadolibre.atlassian.net/browse/KEY`
- Use compact formatting — developers want info density, not paragraphs
- For lists of issues, use a table or bullet list with key, summary, status
- For transitions/moves, a one-liner confirmation is enough: "MLDSP-762 → Done ✓"
- If an operation fails (issue not found, no permission, etc.), say what went wrong and suggest a fix

---

## Examples

**"create a bug: checkout crashes when cart is empty"**
→ Create Bug in MLDSP, summary "checkout crashes when cart is empty", priority Medium

**"move MLDSP-762 to done"**
→ Get transitions → match "Done" → transition → confirm

**"put MLDSP-800 in the current sprint"**
→ Get board for MLDSP → get active sprint → add issue → confirm

**"assign MLDSP-762 to me"**
→ Get user profile for matiasnicolas.moran@mercadolibre.com → update assignee

**"what are my open tickets in MLDSP?"**
→ Search with JQL: `project = MLDSP AND assignee = currentUser() AND statusCategory != Done`
