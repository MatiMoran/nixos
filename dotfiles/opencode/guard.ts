import type { Plugin } from "@opencode-ai/plugin"

type RuleInput = { pattern?: unknown; reason?: unknown; flags?: unknown }
type Rule = { pattern: RegExp; reason: string }

type GuardOptions = { rules?: RuleInput[] }

function compileRules(rules: RuleInput[] | undefined): Rule[] {
  if (!Array.isArray(rules) || rules.length === 0) {
    throw new Error("guard: opencode.json must pass { rules: [...] } via the plugin entry")
  }
  return rules.map((entry, i) => {
    const { pattern, reason, flags } = (entry ?? {}) as RuleInput
    if (typeof pattern !== "string" || !pattern || typeof reason !== "string") {
      throw new Error(`guard: rules[${i}] needs non-empty string fields "pattern" and "reason"`)
    }
    return {
      pattern: new RegExp(pattern, typeof flags === "string" ? flags : undefined),
      reason,
    }
  })
}

export default async (_input: any, options?: GuardOptions) => {
  const rules = compileRules(options?.rules)
  return {
    "tool.execute.before": async (input: any, output: any) => {
      if (input.tool !== "bash") return
      const command: string = output.args?.command ?? ""
      for (const rule of rules) {
        if (rule.pattern.test(command)) {
          throw new Error(`Guard blocked: ${rule.reason}`)
        }
      }
    },
  } satisfies Plugin
}