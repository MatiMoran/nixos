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

Interact with Jira at `mercadolibre.atlassian.net` via the `mcp__claude_ai_MELI_Atlassian__` MCP tools.

**Default project:** `MLDSP` — use it when the user doesn't specify a project.

**Default cloudId:** `a55c251b-e222-488f-8975-3ccdf0a0db6f`

---

## Session Setup (Step 0 — always do this first)

Before calling any Jira tool, check if a `session_id` from `create_meli_session` already exists in the conversation. If yes, reuse it. If not, call `mcp__claude_ai_MELI_Atlassian__create_meli_session` once. The same `session_id` covers all MCP providers (Jira, Slack, GitHub, etc.) — never create more than one per conversation.

---

## Available Tools

| Tool | Purpose |
|------|---------|
| `mcp__claude_ai_MELI_Atlassian__getJiraIssue` | Fetch issue details |
| `mcp__claude_ai_MELI_Atlassian__searchJiraIssuesUsingJql` | JQL search |
| `mcp__claude_ai_MELI_Atlassian__createJiraIssue` | Create a new issue |
| `mcp__claude_ai_MELI_Atlassian__editJiraIssue` | Edit fields (epic, assignee, description, etc.) |
| `mcp__claude_ai_MELI_Atlassian__getTransitionsForJiraIssue` | List available status transitions |
| `mcp__claude_ai_MELI_Atlassian__transitionJiraIssue` | Move issue to a new status |
| `mcp__claude_ai_MELI_Atlassian__addCommentToJiraIssue` | Post a comment |
| `mcp__claude_ai_MELI_Atlassian__createIssueLink` | Link two issues (blocks, relates to, etc.) |
| `mcp__claude_ai_MELI_Atlassian__getIssueLinkTypes` | List available link types |
| `mcp__claude_ai_MELI_Atlassian__lookupJiraAccountId` | Look up a user's accountId by email |
| `mcp__claude_ai_MELI_Atlassian__getVisibleJiraProjects` | List all accessible projects |

---

## Core Operations

### Viewing an Issue

Fetch with `getJiraIssue`. Present the result clearly:
- Key, summary, status, assignee, priority, issue type
- Description (summarize if long)
- Epic/parent if present
- Recent comments if relevant

### Searching Issues

Use `searchJiraIssuesUsingJql` with JQL. Common patterns:
- My open issues: `assignee = currentUser() AND statusCategory != Done ORDER BY updated DESC`
- Project backlog: `project = MLDSP AND sprint is EMPTY AND statusCategory != Done`
- Current sprint: `project = MLDSP AND sprint in openSprints() ORDER BY status ASC`
- By text: `project = MLDSP AND text ~ "payment" ORDER BY created DESC`

Present results as a compact list: `KEY — Summary (Status, Assignee)`.

### Creating an Issue

Use `createJiraIssue`. Required fields:
- `cloudId`: `a55c251b-e222-488f-8975-3ccdf0a0db6f`
- `projectKey`: default `MLDSP` unless specified
- `summary`: always required
- `issueTypeName`: default to `Task` unless the user explicitly specifies a different type
- `assignee_account_id`: for "assign to me" use `712020:8f764565-591e-4c99-8f53-5eb38b5d21fb`

**Epic is mandatory.** Before creating, always ask which epic to link the issue to if the user hasn't specified one. Search existing epics with JQL: `project = MLDSP AND issuetype = Epic AND statusCategory != Done ORDER BY updated DESC`. After creating the issue, set the epic immediately with `editJiraIssue`: `{"parent": {"key": "EPIC-KEY"}}`.

**Language:** Always write the summary and description in Spanish, regardless of the language the user uses to make the request.

**Slack context:** If the issue originates from a Slack thread, always include the thread URL in the description under a "Referencia" section.

After creation, report the new issue key and a link: `https://mercadolibre.atlassian.net/browse/KEY`.

### Assigning an Issue

Use `editJiraIssue`. Look up the account ID first with `lookupJiraAccountId` if needed.

- "assign to me" → accountId `712020:8f764565-591e-4c99-8f53-5eb38b5d21fb`
- "assign to [name/teammate]" → call `lookupJiraAccountId` with their email

### Transitioning an Issue

Transitions are project-specific — never guess transition IDs.

1. Call `getTransitionsForJiraIssue` to see what's available.
2. Match the user's intent to the closest transition name.
3. Call `transitionJiraIssue` with the matched transition ID.

**Known MLDSP transition path to Done** (from Backlog):
- Backlog → `Selected to Development` (id `51`) → state: To Do
- To Do → `Start progress` (id `71`) → state: In Progress
- In Progress → `Done` (id `321`) → state: Done

Always call `getTransitionsForJiraIssue` to confirm IDs before transitioning — these may vary by issue state.

Common intent mappings:
- "start", "in progress" → Start progress
- "done", "finish", "close", "complete" → Done
- "review", "PR up" → Ready to Review / IN REVIEW
- "block", "blocked" → On Hold
- "reopen", "back to backlog" → Back to Backlog

### Setting an Epic

Use `editJiraIssue` with `fields: {"parent": {"key": "EPIC-KEY"}}`.

To find available epics: `searchJiraIssuesUsingJql` with `project = MLDSP AND issuetype = Epic AND statusCategory != Done ORDER BY updated DESC`.

### Sprint Management

⚠️ **The Agile board API is not available** in the current MCP configuration. Sprint assignment cannot be done programmatically. Inform the user and ask them to drag the card to the active sprint manually from the Jira board.

Known active sprint: `223275` (MLDSP 2026Q3 — valid as of 2026-07-30; verify if stale).

### Adding a Comment

Use `addCommentToJiraIssue`. Keep it conversational — don't over-format unless the user provides structured content.

### Linking Issues

1. `getIssueLinkTypes` to see available link types.
2. Match user intent to the right type.
3. `createIssueLink` with inward/outward issue keys.

Common intents:
- "this blocks X" → "Blocks"
- "related to" → "Relates"
- "duplicate of" → "Duplicates"

---

## Output Style

- Always show the Jira URL after create/transition actions: `https://mercadolibre.atlassian.net/browse/KEY`
- Use compact formatting — developers want info density, not paragraphs
- For lists of issues, use a table or bullet list with key, summary, status
- For transitions, a one-liner confirmation is enough: "MLDSP-762 → Done ✓"
- If an operation fails (issue not found, no permission, etc.), say what went wrong and suggest a fix

---

## Examples

**"create a bug: embeddings task no falla con model mismatch"**
→ Ask for epic if not provided → Create Bug in MLDSP → Set epic → confirm

**"move MLDSP-762 to done"**
→ Get transitions → Backlog→To Do (51) → In Progress (71) → Done (321) → confirm

**"assign MLDSP-762 to me"**
→ `editJiraIssue` with assignee accountId `712020:8f764565-591e-4c99-8f53-5eb38b5d21fb`

**"what are my open tickets in MLDSP?"**
→ `searchJiraIssuesUsingJql`: `project = MLDSP AND assignee = currentUser() AND statusCategory != Done`

**"put MLDSP-800 in the current sprint"**
→ Inform that sprint assignment is not supported via API; ask user to move manually from the board
