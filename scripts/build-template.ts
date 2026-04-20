/**
 * Builds a custom E2B sandbox template with Pi coding agent + Bun pre-installed.
 *
 * Once built, sandboxes from this template start instantly from a snapshot —
 * zero install time. Pi runs on Bun natively (no Node.js).
 *
 * Prerequisites:
 *   - Bun installed: curl -fsSL https://bun.sh/install | bash
 *   - E2B SDK: bun install e2b
 *   - E2B_API_KEY environment variable set
 *
 * Usage:
 *   E2B_API_KEY=e2b_xxx bun run scripts/build-template.ts
 *
 * Or with a custom template name:
 *   TEMPLATE_NAME=my-project E2B_API_KEY=e2b_xxx bun run scripts/build-template.ts
 */

import { Template, defaultBuildLogger } from 'e2b'

const apiKey = process.env.E2B_API_KEY
if (!apiKey) {
  console.error('E2B_API_KEY environment variable is required.')
  process.exit(1)
}

const templateName = process.env.TEMPLATE_NAME ?? 'pi-bun-sandbox'

const template = Template()
  .fromBunImage('latest')
  .setUser('root')
  // System packages needed by Pi and typical dev workflows
  .runCmd(
    'apt-get update && apt-get install -y git ripgrep fd-find jq && rm -rf /var/lib/apt/lists/*',
  )
  // Install Pi coding agent globally via Bun
  .runCmd('bun install -g @mariozechner/pi-coding-agent@latest')
  // Make root's bun global dir traversable by the sandbox user
  .runCmd('chmod a+rx /root && chmod -R a+rX /root/.bun')
  // Patch Pi's shebang from node → bun (oven/bun image has no Node.js)
  .runCmd(
    'sed -i "1s|#!/usr/bin/env node|#!/usr/bin/env bun|" ' +
      '/root/.bun/install/global/node_modules/@mariozechner/pi-coding-agent/dist/cli.js',
  )
  // Verify Pi runs as root
  .runCmd('pi --version')
  .setUser('user')
  // Verify Pi runs as unprivileged user
  .runCmd('/usr/local/bin/pi --version')
  // Pre-create Pi config directory
  .runCmd('mkdir -p /home/user/.pi/agent')

console.log(`Building template: ${templateName}\n`)

const result = await Template.build(template, templateName, {
  apiKey,
  cpuCount: 2,
  memoryMB: 4096,
  onBuildLogs: defaultBuildLogger(),
})

console.log(`\nTemplate built: ${templateName} (${result.templateId})`)
await Bun.write('.e2b-template-id', result.templateId)
