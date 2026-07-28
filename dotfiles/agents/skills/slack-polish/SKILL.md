---
name: slack-polish
description: >
  Improve, correct and polish Slack messages before sending them. Fixes grammar,
  spelling, tone and structure. Returns the improved message ready to send, plus
  a brief bullet-point explanation of each change and why it was made.

  Use this skill whenever the user wants to review or improve a Slack message,
  either by pasting the text directly or sharing a Slack thread URL/message ID.
  Also use it when the user asks "does this sound ok?", "how do I say this?",
  "is this too rude?", or pastes a message and seems unsure about it.

  Trigger on: /slack-polish, "revisame este mensaje", "mejorá este slack",
  "corregime esto para mandar", "está bien este mensaje", "pulí este mensaje",
  "revisá esto antes de mandarlo", "cómo puedo decir esto mejor",
  "suena raro esto que escribí", "es muy brusco esto?", "cómo lo diría mejor",
  "ayudame a redactar esto", "quedó bien así?", "suena bien?"
version: "1.0.0"
---

# Slack Polish

Review and improve Slack messages so they are brief, clear, polite, and give the
reader enough context — without being long-winded or sounding stiff.

---

## Principles

Keep these in mind throughout. They're the "why" behind every change:

- **Brief**: Every word should earn its place. Cut filler, repetition, and
  hedges that don't add meaning.
- **Argentine voice**: The user is Argentine. Write messages that sound like
  they came from a real Argentine person — not a corporate template, not neutral
  Spanish. Use voseo naturally throughout ("podés", "hacés", "sabés"). Use
  simple, natural local expressions ("echarle un ojo", "dale una mirada",
  "mil gracias"). Avoid neutral Spanish: "te lo agradezco" → "mil gracias";
  "podrías revisar" → "¿le podés echar un ojo?". Do NOT invent unusual idioms
  to sound more Argentine — phrases like "un par de ojos de más no caen mal"
  feel AI-generated and unnatural. Keep expressions simple and common.
- **No preemptive thanks**: Don't end a request with "gracias" or "mil gracias"
  if the message is phrased as a statement that already assumes compliance (e.g.,
  "sería bueno que lo revises. Gracias." — this presumes they'll say yes).
  "Mil gracias" is fine only after a direct, open question ("¿Le podés echar un
  ojo? Mil gracias.") — there the thanks is warm, not presumptuous.
- **Greeting for one-on-one messages**: When the message is directed at a
  specific person (DM or a message addressing someone by name), start with a
  warm casual opener like "¿Cómo estás [nombre], todo bien?" — unless the
  original already has a greeting or the context makes it awkward (e.g., an
  urgent incident alert).
- **Context-complete**: The reader should never need to ask "which one?",
  "from when?", or "what does that mean?" Include just enough background.
- **Adapted to the audience**: Don't over-explain to someone technical; don't
  use acronyms with someone who may not know them.
- **Preserve English technical terms**: Keep terms like IMHO, CPC, throttler,
  DSP, ETA, LGTM, etc. exactly as-is. These are shared vocabulary, not errors.

---

## Phase 1 — Get the message

**Two input modes:**

**Mode A — Direct text**: The user pastes the message. Move to Phase 2.

**Mode B — Slack thread URL or message ID**: The user shares a link like
`https://mercadolibre.slack.com/archives/C.../p...` or a raw message ID.

1. Call `mcp__claude_ai_Slack__slack_read_thread` with the channel and
   thread timestamp extracted from the URL.
   - From a permalink URL: channel is the segment after `/archives/` (e.g. `C012AB3CD`),
     thread_ts is the numeric part after `/p` with a `.` inserted after the 10th digit
     (e.g. `p1234567890123456` → `1234567890.123456`).
2. Identify the message to improve — usually the most recent message in the thread,
   or the one the user highlighted.
3. Note: participants, channel name, and thread history. This context shapes the
   improvement (avoid repeating info already said, adjust tone to the conversation).
4. Call `mcp__claude_ai_Slack__slack_list_channel_members` only if you need to
   gauge the audience size of a channel (skip for DMs and small known groups).

---

## Phase 2 — Audience context

1. Read `references/audience.md` to check if the recipient (person or channel)
   is already known.
2. **If known**: use the saved name and technical level — do not ask again.
3. **If unknown or not mentioned**: ask one simple question:
   > "¿A quién va dirigido? ¿Su nombre/handle y si es técnico/a, semi-técnico/a o no técnico/a?"
   - **Técnico/a**: engineer, data scientist, infra — can handle full jargon
   - **Semi-técnico/a**: PM, designer, analyst — understands concepts, not code
   - **No técnico/a**: stakeholder, business lead, external — needs plain language

   Getting the person's name matters: it lets you personalize the greeting.

---

## Phase 3 — Improve the message

Apply these rules to the original message:

| Rule | What to do |
|------|-----------|
| **Brevedad** | Remove filler words, redundant phrases, unnecessary preambles |
| **Tono** | Soften if brusque; add a casual Argentine greeting with name at the start if this is a one-on-one message without one |
| **Voz argentina** | Replace neutral-Spanish expressions with simple Argentine ones. Avoid inventing elaborate idioms. Examples: "te lo agradezco" → "mil gracias"; "podrías revisar" → "¿le podés echar un ojo?" |
| **Agradecimiento** | Only add "Mil gracias" if the request ends in a direct open question. Never add thanks after indirect phrasings that already assume compliance. |
| **Contexto** | Add minimal background if the message assumes knowledge ("el ticket", "la reunión de ayer") without identifying which one |
| **Ortografía/gramática** | Fix Spanish errors; preserve English terms as-is |
| **Estructura** | Break a wall of text into short paragraphs or bullet points if there are multiple distinct points |
| **Nivel técnico** | Simplify acronyms or jargon for non-technical audiences; leave them as-is for technical ones |
| **Hilo** (Mode B only) | Avoid repeating what was already said; acknowledge the thread context if it helps |

---

## Phase 4 — Output

Always show the result in this exact format:

---
**Mensaje mejorado**
```
[el mensaje corregido, listo para copiar]
```

**Cambios realizados**
- **[Categoría]**: [qué se cambió en una frase] → *Por qué: [razón breve]*

---

**Categories to use** (pick the one that fits best):
`Brevedad`, `Tono`, `Voz argentina`, `Contexto`, `Ortografía`, `Gramática`,
`Estructura`, `Nivel técnico`, `Claridad`

Show between 2 and 6 bullets. If the message only had minor fixes, say so
("Estaba bien estructurado, solo se ajustaron detalles menores").

If the input was via Slack thread (Mode B), add a one-line header before
the improved message:

```
📍 Canal: #nombre · Visibilidad: público/privado/DM · Participantes: @a, @b
```

---

## Phase 5 — Update audience memory

If the recipient was new (not in `references/audience.md`), ask:

> "¿Querés que recuerde a [nombre/canal] como [nivel técnico] para la próxima vez?"

If yes: append to `references/audience.md` using the format documented there,
including the person's first name so future greetings can be personalized.

---

## Edge cases

- **Message is already good**: say so clearly and briefly. One or two minor
  suggestions at most — don't invent problems.
- **Mixed language message** (Spanish + English): that's normal. Improve the
  Spanish parts; leave English terms alone.
- **Message is very long** (>200 words): also suggest if it could be split into
  multiple shorter messages.
- **Sensitive or confidential content**: treat it normally; do not comment on it.
- **Slack URL authentication fails**: fall back to asking the user to paste the
  message text directly.
