# Automation foundation

## Canonical sources

- `package.json` defines the shared validation entrypoints.
- `biome.json` defines formatting and linting behavior.
- `tsconfig.json` defines TypeScript typechecking behavior for the validated scope.

## Local developer suite

- `bun run format:check`
- `bun run lint`
- `bun run typecheck`
- `bun run test`
- `bun run check`
- `bun run check:changed`

`check:changed` formats and lints changed files only, then runs full typecheck and the full current test suite as the safe fallback for correctness.

## Local release-readiness suite

Current known release surface is this repo's automation/configuration layer, so the initial release gate is:

- `bun run release-check`

At the current scope, `release-check` intentionally aliases the full validation gate via shared package scripts to preserve parity and avoid drift.

## Deterministic cache policy

No task cache is enabled yet.

Current deterministic fallback: rerun gates directly from canonical scripts against the working tree and lockfile. This is slower than cached execution but deterministic and explicit.

## Safe parallelism

Local default developer execution fast-fails sequentially.

GitHub validation runs equivalent local gates in separate jobs where safe. This provides minimal parallelism without duplicating rule definitions.

## Local ↔ GitHub parity

GitHub workflow `.github/workflows/agentic-validation.yml` invokes the same `package.json` scripts used locally.

Current parity mapping:
- `bun run format:check`
- `bun run lint`
- `bun run typecheck`
- `bun run test`
- `bun run release-check`

`scripts/build-template.ts` is included in `tsconfig.json`, so the local and GitHub typecheck gates both validate the current E2B SDK integration surface.
