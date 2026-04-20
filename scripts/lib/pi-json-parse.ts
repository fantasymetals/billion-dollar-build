/**
 * pi-json-parse.ts — Parse Pi JSON mode (JSONL) output into structured envelope.
 *
 * Source-verified against badlogic/pi-mono:
 *   - print-mode.ts lines 112-114: JSON mode subscriber writes JSON.stringify(event) + "\n"
 *   - print-mode.ts lines 120-123: session header emitted first
 *   - agent-session.ts: event types are agent_start, agent_end, turn_start, turn_end,
 *     message_start, message_update, message_end, tool_execution_start,
 *     tool_execution_update, tool_execution_end
 *
 * Usage:
 *   echo "$JSONL_OUTPUT" | bun scripts/lib/pi-json-parse.ts <exit_code>
 *
 * Output: JSON envelope on stdout
 */

export {}

interface PiEvent {
  type: string
  [key: string]: unknown
}

interface ToolUsage {
  tool: string
  error: boolean
}

interface PiEnvelope {
  success: boolean
  exitCode: number
  response: string
  toolsUsed: ToolUsage[]
  totalTurns: number
  errors: Array<{ tool: string; result: unknown }>
  phase: string | null
}

const stdin = await Bun.stdin.text()
const exitCode = parseInt(process.argv[2] ?? '0', 10)
const lines = stdin.trim().split('\n')

const events: PiEvent[] = []
for (const line of lines) {
  const trimmed = line.trim()
  if (!trimmed) continue
  try {
    events.push(JSON.parse(trimmed))
  } catch {
    // Skip malformed JSONL lines — don't crash
    // Source: print-mode.ts writes each event as JSON + \n
    // Malformed lines can appear from CLI noise or partial writes
  }
}

// Find the agent_end event for the final response
const agentEnd = events.find((e) => e.type === 'agent_end')

// Collect tool execution events
const toolEvents = events.filter((e) => e.type === 'tool_execution_end')

// Count turns
const totalTurns = events.filter((e) => e.type === 'turn_end').length

// Extract final response text from agent_end messages
let response = ''
if (agentEnd?.messages && Array.isArray(agentEnd.messages)) {
  const lastMsg = agentEnd.messages[agentEnd.messages.length - 1]
  if (lastMsg?.content && Array.isArray(lastMsg.content)) {
    response = lastMsg.content
      .filter((c: { type: string }) => c.type === 'text')
      .map((c: { text: string }) => c.text)
      .join('\n')
  }
}

// Extract phase from status block in response (if present)
let phase: string | null = null
const statusMatch = response.match(/```json:status\n([\s\S]*?)\n```/)
if (statusMatch) {
  try {
    const statusBlock = JSON.parse(statusMatch[1])
    phase = statusBlock.phase ?? null
  } catch {
    // Malformed status block — skip
  }
}

const envelope: PiEnvelope = {
  success: exitCode === 0,
  exitCode,
  response,
  toolsUsed: toolEvents.map((e) => ({
    tool: (e.toolName as string) ?? 'unknown',
    error: (e.isError as boolean) ?? false,
  })),
  totalTurns,
  errors: toolEvents
    .filter((e) => e.isError === true)
    .map((e) => ({
      tool: (e.toolName as string) ?? 'unknown',
      result: e.result,
    })),
  phase,
}

console.log(JSON.stringify(envelope, null, 2))
