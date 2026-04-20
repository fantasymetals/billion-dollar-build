import { describe, expect, test } from 'bun:test'

const requiredFiles = ['biome.json', 'tsconfig.json', '.github/workflows/agentic-validation.yml']
const requiredScripts = [
  'format',
  'format:check',
  'lint',
  'typecheck',
  'test',
  'check',
  'check:changed',
  'release-check',
]
const checkGateScripts = ['format:check', 'lint', 'typecheck', 'test']
const workflowGateScripts = [...checkGateScripts, 'release-check']

describe('bootstrap automation foundation', () => {
  test('canonical rule files exist', async () => {
    for (const file of requiredFiles) {
      expect(await Bun.file(file).exists()).toBe(true)
    }
  })

  test('package.json exposes required validation scripts', async () => {
    const pkg = await Bun.file('package.json').json()

    for (const script of requiredScripts) {
      expect(pkg.scripts?.[script]).toBeString()
    }
  })

  test('typecheck includes scripts/build-template.ts', async () => {
    const tsconfig = await Bun.file('tsconfig.json').json()

    expect(tsconfig.include).toContain('scripts/**/*.ts')
    expect(tsconfig.exclude ?? []).not.toContain('scripts/build-template.ts')
  })

  test('workflow mirrors local validation gates', async () => {
    const workflow = await Bun.file('.github/workflows/agentic-validation.yml').text()
    const workflowScripts = [...workflow.matchAll(/bun run [^\n]+/g)].map(([match]) =>
      match.replace('bun run ', '').trim(),
    )

    expect(workflowScripts).toEqual(expect.arrayContaining(workflowGateScripts))
    expect(workflowScripts).toHaveLength(workflowGateScripts.length)
  })
})
