---
name: pr-ready
description: >
  Automate PR finalization: generate a changelog entry, GitHub PR description,
  and Slack review message from the branch diff. Use this skill whenever the user
  says: /pr-ready, "prepare the PR", "finalize the PR", "PR is ready", "PR is
  finished", "update changelog and PR", "prep for review", "PR wrap-up", "get the
  PR ready", "changelog + PR + slack", "generate PR description", "the PR is
  done", "ready for review", or any request that combines updating a changelog,
  editing a PR description, and composing a Slack notification for code review.
  Also trigger when the user asks to "write the changelog" or "create a slack
  message for the PR" as part of finishing a pull request. When in doubt about
  whether this skill applies, trigger it — the user can always decline.
---

# PR Ready

Finalize a pull request by generating three artifacts from the branch diff:
a **CHANGELOG entry**, a **GitHub PR description**, and a **Slack review message**.
The user reviews and iterates on all three before anything is written or sent.

---

## Phase 1 — Gather Context

Collect everything needed to understand the changes. All steps here are read-only.

1. **Get the PR metadata**
   ```bash
   gh pr view --json number,title,url,headRefName,baseRefName
   ```
   If no PR exists for the current branch, tell the user and offer to create one
   with `gh pr create`. Stop here until there's a PR to work with.

2. **Identify the base branch** from the PR's `baseRefName` (usually `develop` or
   `main`). Never hardcode it.

3. **Read the diff**
   - `git log <base>..HEAD --oneline` — commit summaries
   - `git diff <base>...HEAD --stat` — file-level overview
   - Selectively read the full diff for files that matter (source code, config,
     SQL). Skip lockfiles and binary diffs — they add noise without insight.

4. **Read CHANGELOG.md** — understand the existing format: heading style, indent,
   category names, whether an `[Unreleased]` section already exists, and what
   entries it may already contain.

5. **Derive the project name** for the Slack message prefix. Extract a short,
   human-friendly name from the repo (e.g. `fury_advertising-dsp-ml-budget` →
   `Budget`). When in doubt, use the last meaningful word from the repo name.

---

## Phase 2 — Draft the Three Artifacts

Generate all three artifacts and present them to the user **inline in the
conversation**. Do not write to any file or run any command yet.

### A. CHANGELOG Entry

Follow the conventions already present in the project's CHANGELOG.md:

- Use [Keep a Changelog](https://keepachangelog.com/) categories: `Added`,
  `Changed`, `Fix` (or `Fixed` — match whatever the file already uses).
- Only include categories that have actual changes. Never add empty sections.
- 4-space indented bullets: `    - Description of the change`
- Concise, past-tense descriptions. No trailing periods.

**Example:**
```markdown
## [Unreleased]
### Added
    - Added pre-commit hook to block hardcoded BigQuery table IDs in SQL files
### Changed
    - Enabled Black string normalization
```

### B. PR Description

A concise summary for code reviewers:

```markdown
## Short title derived from the changes

- Bullet point describing change 1
- Bullet point describing change 2
```

Keep it aligned with the CHANGELOG bullets but allow slightly more technical
detail since the audience is developers reviewing code.

### C. Slack Message

Format for pasting into a Slack channel:

```
[ProjectName]

Buenas team :hi_pepe: - Dejo PR de <project> con los siguientes cambios:
<full PR URL>

* Bullet point 1
* Bullet point 2
```

- Use the actual PR URL from step 1.
- Bullets should be user-friendly summaries (slightly less technical than the PR
  description).
- Use `*` (Unicode bullet) for bullet points.

### Presenting the Draft

Show all three artifacts clearly separated with headers. Then ask the user
explicitly:

> "Does this look good? I can adjust any section. Once you approve, I'll:
> (1) update CHANGELOG.md, (2) edit the PR on GitHub, and (3) copy the Slack
> message to your clipboard."

---

## Phase 3 — Iterate

If the user requests changes to any section, adjust and re-present the full
draft. Repeat until the user explicitly approves. Small tweaks to one section
don't require re-showing the unchanged sections — use judgment.

---

## Phase 4 — Apply

Only execute after the user has explicitly approved.

1. **CHANGELOG.md** — Edit the `[Unreleased]` section:
   - If `[Unreleased]` already exists with entries, append new items under the
     correct category headers (or create new category headers as needed).
   - If `[Unreleased]` doesn't exist, insert it between the file header and the
     first version entry.
   - Preserve the exact formatting conventions of the file.

2. **PR description** — Update via:
   ```bash
   gh pr edit <NUMBER> --body "..."
   ```

3. **Slack message** — Copy to clipboard:
   ```bash
   printf '%s' '<message>' | pbcopy
   ```

4. **Confirm** — Tell the user:
   > "Done. CHANGELOG.md updated, PR #N description edited, Slack message copied
   > to your clipboard."

5. **Do not commit automatically.** The user decides when and how to commit the
   CHANGELOG change.

---

## Rules

- **Never skip the draft.** Even if the user says "just do it", show the draft
  first. The whole point of this skill is that the user reviews before anything
  is written.
- **Never add AI attribution.** No AI `Co-Authored-By` lines and no mentions of
  AI tools, vendors, models, or agents in any artifact — CHANGELOG, PR body,
  Slack message, or commits.
- **Match the file's style.** The CHANGELOG format varies across projects. Read
  the file and match what's there, don't impose a different style.
- **Handle existing [Unreleased] content.** If there are already entries in the
  unreleased section, append — don't replace.
