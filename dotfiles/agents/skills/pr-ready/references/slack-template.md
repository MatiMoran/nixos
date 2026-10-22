# Slack PR announcement template

Use this reference when drafting the Slack artifact for `#dsp-ml-prs`
(`C0C53VDHES0`). Instructions are in English; the announcement is in natural
Spanish, retaining the team's technical terms.

## Basis and scope

The channel's [pinned format announcement](https://meli.enterprise.slack.com/archives/C0C53VDHES0/p1790607394532379)
and its [recommended practices](https://meli.enterprise.slack.com/archives/C0C53VDHES0/p1790607470375589)
establish the core fields: PR, context, review focus, suggested reviewers, and
priority/date only when a concrete need exists. One parent message per PR;
questions, feedback, and updates belong in its thread.

The available channel history reviewed on 2026-10-22 spans 2026-09-28 through
2026-10-22. Subsequent posts commonly add `[Initiative]` titles and `Validación`;
some add `Impacto`, `Cambio`, or `Resultado`. These are useful extensions, not
mandatory fields imposed by the pinned announcement. For examples, see
[Pricing: context, impact, validation, and review focus](https://meli.enterprise.slack.com/archives/C0C53VDHES0/p1792681603118719)
and [Spend Plan: validation and targeted review](https://meli.enterprise.slack.com/archives/C0C53VDHES0/p1791897218541809).

## Field schema

| Field | Inclusion | Content and source |
| --- | --- | --- |
| Title | Default | `[Initiative] Short change title`. Use the affected project or component, not the full repository slug. Add `hotfix`, `release`, or `draft` only when accurate. |
| PR | Required | Actual full PR URL and repository identity. A bare URL is suitable for clipboard output; add the repository name when the URL does not make it clear. |
| Contexto | Required | What changes and why, usually in 1–3 short sentences. Explain the trigger/problem and resulting behavior; include affected sites, goals, or scope when relevant. |
| Impacto | Conditional | A material operational effect, rollout constraint, dependency, or compatibility concern supported by the diff or supplied context. Omit if it merely repeats Contexto. |
| Validación | Conditional | Checks actually run and their observed results. Include environment, site, comparison, or evidence link when useful. Distinguish completed tests, pending checks, failures, and unperformed validation. |
| Review solicitado | Required | The specific logic, data, contract, architecture, or operational risk needing attention. Name at most a few relevant files or decisions; avoid generic requests to review everything. |
| Reviewers | Required in a complete draft | People or the relevant team established by the user or PR review requests. Use verified Slack mentions, or plain names if identity mapping is unavailable. An explicit open call is also valid. |
| Prioridad o fecha | Conditional | An established priority or actual deadline with its reason, such as a production incident, blocked rollout, or dependency sunset. Omit when no concrete need is known. |

## Template

Use this order. Remove conditional lines that do not apply; do not leave empty
labels or literal placeholders in the final message.

```text
*[Initiative] Short change title*
• *PR:* https://github.com/organization/repository/pull/NUMBER
• *Contexto:* What changes, why, and the relevant scope.
• *Impacto:* Material operational effect or rollout constraint, if applicable.
• *Validación:* Observed checks and results, with evidence when available.
• *Review solicitado:* Specific logic, files, or decisions needing attention.
• *Reviewers:* Verified mentions, known names, or an explicitly open review call.
• *Prioridad o fecha:* Established priority/deadline and its concrete reason.
```

The title, `PR`, `Contexto`, `Review solicitado`, and `Reviewers` form the default
message. The remaining lines are conditional. Aim for one screen of text;
link to detailed evidence instead of copying logs or the entire PR description.
Use the real Unicode bullet `•`, Slack `*bold*` labels, and backticks for code
identifiers. For clipboard output, retain the full raw PR URL.

## Missing information and tone

- Derive context and review focus from the current PR and diff, not from old
  channel examples. Historical tests, metrics, reviewer assignments, deadlines,
  and deployment states are not facts about the current PR.
- If validation evidence is unavailable, omit `Validación`. If validation is
  explicitly pending or failing and affects readiness, state that accurately in
  the draft and surface it during review. Passing CI alone does not prove an
  integration test or deployment succeeded.
- If no reviewer choice is known, use `Reviewers: Por definir` only in the
  reviewable draft and ask for the choice alongside the existing artifact review
  question. Replace it before copying the final message. Use
  `Abierto a quien tenga contexto del cambio` when the user chooses an open call.
- Never guess Slack IDs or group memberships. Use a reliable known mapping or
  resolve identities with available Slack tools; otherwise retain plain names.
  Do not add `@channel`, `@here`, or broad mentions by default.
- Do not default every PR to medium or high priority. When a concrete priority
  is known, observed local conventions include `:alta:`, `:media:`, and `:baja:`;
  always keep the reason or real date clear. Do not invent deadlines or an SLA.
- Keep the tone direct, friendly, and technical. A greeting and closing thanks
  are optional; the old fixed greeting is not part of this channel's template.
- Put implementation detail in the GitHub PR body and follow-up conversation in
  the PR's Slack thread. Do not treat channel examples as authorization to post,
  react, assign reviewers, merge, or deploy; this skill prepares clipboard text.

## Example

Illustrative wording only; supply the real URL and current evidence at runtime.
This example assumes the user explicitly chose an open review call and provided
no validation evidence or deadline, so neither conditional field is included.

```text
*[Budget] Validar el contrato del archivo de salida*
• *PR:* https://github.com/organization/repository/pull/NUMBER
• *Contexto:* El archivo podía publicarse con registros incompletos. Se valida el contrato antes de subirlo a S3.
• *Review solicitado:* El orden de validación y publicación, y el manejo de registros incompletos.
• *Reviewers:* Abierto a quien tenga contexto del cambio
```
