# Project Operating Contract

This repo-local `AGENTS.md` is appended by Pi as Project Context and is mandatory policy, not advisory background.

If broader or more global `AGENTS.md` / `CLAUDE.md` files conflict with this repository's policy, this file wins for this repository.

## Architecture context

This repository is the pi-config layer of a three-layer architecture:

1. **Perplexity Space** (intelligence) — RAG, web search, memory, Connectors, model orchestration. Lives upstream. Not governed by this contract.
2. **Pi session** (execution) — this layer. 4 tools: read, write, edit, bash. Governed by this contract. Runs inside E2B.
3. **E2B sandbox** (infrastructure) — Firecracker MicroVM isolation. Your codebase is mounted here.

This contract governs layer 2 only. Pi receives instructions from the developer (who may be working through Perplexity Computer) and executes deterministic coding tasks within the sandbox. Pi does not reach outside the sandbox for intelligence, search, or external integrations — that separation is the entire point of the architecture.

## Definitions

- **Production code**: application, library, service, or runtime code that changes shipped system behavior.
- **Current scope**: the repo's currently real behavior, boundaries, build surfaces, packaging/release surfaces, and applicable validation needs. Do not invent future scope.
- **Local CI/CD configuration**: the local developer validation suite, the local release-readiness validation suite, and the canonical shared rules/scripts/configuration that drive them.
- **Automation foundation**: all of the following for the current scope:
  1. one canonical source of gates, rules, and failure conditions
  2. a local developer validation suite
  3. a local release-readiness validation suite
  4. changed-file / affected-target execution, or a safe documented fallback
  5. deterministic caching, or a safe documented deterministic no-cache fallback
  6. safe parallel execution where applicable
  7. a matching minimal GitHub Agentic Workflow
  8. verified local ↔ GitHub parity for the current scope
- Tests, validation scripts, CI/CD config, and bootstrap automation may be created before production code when required by this contract.

# Operating contract

You must operate strictly in a **TDD-first RED -> GREEN -> REFACTOR cycle** for all production code changes.

- No production code unless it is directly required to satisfy a failing production test.
- All dependencies are externally provided capabilities: declared at the system boundary and supplied at composition/runtime.
- No phase-skipping, no collapsing phases in ways that defeat their intent.

## 0. Mandatory minimal automation bootstrap

Before writing any production test or any production code, you MUST establish and validate a **minimal automation foundation** for the current scope.

This bootstrap is mandatory.

It is not realistic to have all CI/CD perfect at the start. Therefore:

- perfection is **not** required before RED
- a minimal, deterministic, safe, working automation foundation **is** required before RED
- that foundation must pass for the current scope
- that foundation must evolve in lockstep as production tests, production code, boundaries, build surfaces, packaging, and release concerns evolve
- no new production capability may permanently outrun the automation required to validate it safely

### 0.1 Bootstrap requirements

Before RED begins, create and validate the currently applicable versions of:

- a local developer validation suite for fast feedback
- a local release-readiness validation suite sized to the current scope
- changed-file / affected-target execution, or an explicitly documented safe fallback
- deterministic caching, or an explicitly documented deterministic no-cache fallback
- safe parallel execution where applicable
- a matching minimal GitHub Agentic Workflow
- one canonical source of format, lint, type, structure, test, cache, affected-target, build, release, and failure rules

These may begin minimal, but they MUST exist before any production tests are written, and they MUST evolve with the system.

### 0.2 Bootstrap objectives

For the current scope, automation MUST provide:

- immediate feedback
- localized failures
- incremental execution where correctness permits
- avoidance of re-running unaffected work where correctness permits
- deterministic gates
- local and GitHub results that match as closely as environments allow
- minimal, safe, reproducible, fast execution

### 0.3 Local developer validation suite

Before any production tests are written, a minimal local developer validation suite MUST exist and include every cheap, deterministic, currently applicable developer-feedback gate, including where applicable:

- format validation
- linting
- type checking
- unit and integration test execution
- build verification
- structure-rule enforcement
- changed-file / impacted-target filtering
- fast-fail behavior
- watch mode

It MUST be optimized for feedback:

- sub-second to a few seconds for small edits when feasible
- incremental by default
- parallel where safe
- no unnecessary full-repo scans
- no unnecessary full test runs
- no nondeterministic steps

As production tests and production code evolve, this suite MUST evolve too.

### 0.4 Local release-readiness validation suite

Before any production tests are written, an initial local release-readiness validation suite MUST also exist.

It validates release and deployment readiness for the **current known release surface** and expands as the system evolves. Where applicable, it includes:

- full-repo validation
- artifact buildability
- packaging correctness
- configuration validation
- environment contract validation
- deployment preflight checks
- rollback readiness validation

It MUST be deterministic and reproducible, must not depend on hidden machine state, may be slower than the developer suite, and must be runnable on demand and before release/promotion.

### 0.5 Canonical gate definition

All gates MUST be defined once and reused wherever technically possible.

The canonical source MUST govern:

- format rules
- lint rules
- type rules
- structural limits
- test policies
- cache behavior
- affected-target logic
- build validation rules
- release validation rules
- failure conditions

Local and GitHub automation must consume or derive from the same canonical source. No duplicated logic that can drift unless technically unavoidable; any unavoidable duplication must be documented and minimized.

Every new gate or rule change MUST be added to the canonical source first.

### 0.6 Matching GitHub Agentic Workflow

Before any production tests are written, you MUST create a minimal GitHub Agentic Workflow that mirrors the current local validation model as closely as possible.

It MUST:

- mirror current local gates
- preserve the same pass/fail semantics for equivalent inputs
- run checks in parallel where possible
- fast-fail on critical failures where supported
- avoid re-running unaffected work where correctness permits
- remain deterministic
- use minimal permissions
- isolate agent analysis from write operations

It may start minimal, but it MUST evolve with the system.

### 0.7 GitHub Agentic Workflow safety model

The GitHub workflow MUST ensure:

- agent execution is isolated
- agent execution is read-only by default
- proposed actions are emitted as structured outputs or artifacts
- any write is performed only by a separate, explicitly scoped, guarded job
- suspicious, malformed, or unsafe outputs fail the workflow
- secrets are not exposed to the agent unless strictly required for a narrowly scoped step
- network access is minimized and explicitly controlled where possible

The agent may analyze, reason, and propose. It must not directly mutate the repository, create uncontrolled side effects, or bypass guarded write steps.

### 0.8 Local ↔ GitHub parity

For every local gate that exists, there MUST be a corresponding GitHub gate unless the gate is inherently local-only.

Parity includes, where applicable:

- formatter behavior
- linter behavior
- type-checker behavior
- structure-rule behavior
- test selection behavior
- full-suite behavior
- build verification behavior
- release-readiness behavior
- failure semantics
- cache semantics where feasible

Any divergence is a defect unless explicitly unavoidable due to environment differences. Any unavoidable divergence MUST be documented and minimized.

### 0.9 Bootstrap order

Before writing production tests:

1. define canonical rules and failure conditions for the current scope
2. set up the local developer validation suite
3. set up the local release-readiness validation suite
4. set up affected-target execution or a safe documented fallback
5. set up deterministic caching or a safe deterministic no-cache fallback
6. set up safe parallel execution
7. set up the matching minimal GitHub Agentic Workflow
8. verify local ↔ GitHub parity for the current scope
9. only then begin RED

### 0.10 Bootstrap verification

RED may begin only when, for the current scope:

- the automation foundation exists
- the local developer suite passes
- the local release-readiness suite passes
- changed-file / affected-target execution works, or the documented safe fallback works
- full validation works
- caches work where enabled, or deterministic no-cache behavior is confirmed where caching is deferred
- enabled parallel execution works correctly
- the GitHub workflow reflects the currently implemented gates and failure conditions
- local and GitHub outcomes match for equivalent inputs as closely as environments allow

### 0.11 Ongoing evolution

Bootstrap is not a one-time event.

A minimal local CI/CD configuration and matching minimal GitHub Agentic Workflow MUST exist before any production tests are written, and they MUST evolve as production tests and production code evolve.

## 1. Performance mandate

All engineering activity MUST maximize speed without sacrificing determinism, safety, correctness, or TDD constraints.

**Core principle:** any unnecessary slowdown is a defect.

If two approaches are equally correct, choose the faster one.

### 1.1 Speed requirements

Automation, builds, tests, linting, type checking, feedback loops, local validation, release-readiness validation, and GitHub workflows MUST be as fast as possible while remaining correct and deterministic.

Required properties:

- incrementality where possible
- safe parallelism where possible
- determinism and cacheability where possible
- no hidden global state that breaks caching or parallelism
- no blocking of unrelated work without cause
- no duplicated automation logic that can be shared
- local feedback in sub-second to a few seconds for small edits when feasible
- CI feedback accelerated via parallelism, impact analysis, and fast-fail

Specific expectations:

- builds: incremental by default, avoid full rebuilds unless necessary, use caching, minimize I/O/bundling/transformations
- tests: hermetic, isolated, parallel where safe, support impact analysis where correct, avoid slow setup/teardown and unnecessary integration scope in unit tests
- lint/typecheck: incremental and watch mode where supported, process only changed or affected inputs when correct, avoid redundant passes, parallelize where supported

### 1.2 Prohibited performance anti-patterns

- starting production TDD before the current-scope automation foundation exists
- running the full test suite on every change when not required for correctness
- global cache invalidation without cause
- sequential execution where safe parallelism is possible
- recomputing unchanged artifacts
- tests depending on shared mutable state
- long-running setup inside individual tests
- reprocessing unchanged inputs without cause
- CI pipelines serializing independent jobs
- local and GitHub pipelines drifting in behavior
- remote workflows re-running work that can be safely skipped based on trusted prior validation and equivalent inputs

### 1.3 Required optimization strategies

- test impact analysis
- incremental compilation and type checking
- persistent caching across runs
- parallel execution for tests, linting, type checking, builds, and validation jobs where safe
- watch mode where applicable
- deterministic precomputation and memoization
- fast-fail mechanisms
- canonical shared gate definitions
- local-first validation before remote execution

### 1.4 Enforcement

- performance regressions are failures
- speed improvements are part of REFACTOR
- any noticeable slowdown must be investigated and resolved
- automation parity regressions are failures

## 2. RED

RED may begin only after bootstrap is complete for the current scope.

For every production behavior change:

- start with a failing production test
- the test must represent real user behavior, a contract, or a system boundary
- it must validate externally observable outcomes only
- it must interact only through public interfaces or system boundaries
- dependencies must be represented as abstract capabilities supplied explicitly to the system under test

Tests written in RED MUST be fast, isolated, deterministic, and parallelizable where possible.

### 2.1 Prohibited in RED

- testing private or internal functions, classes, or modules directly
- asserting implementation details such as internal state, call patterns, or internal structure
- writing tests that could still pass while externally observable behavior is wrong
- instantiating real external systems inside tests unless the test is explicitly an integration or end-to-end boundary test for that purpose

## 3. GREEN

After a failing production test exists, write the smallest amount of production code required to make it pass.

In GREEN:

- do not preemptively generalize
- do not add functionality beyond the current failing test
- consume dependencies through declared capabilities, not inline construction
- keep business logic unaware of concrete implementations

Implementation in GREEN MUST avoid unnecessary work or allocations, preserve testability and isolation, and remain compatible with incremental builds, caching, determinism, and safe parallelism.

## 4. REFACTOR

Refactor only after tests pass.

You may improve:

- structure
- readability
- maintainability
- performance
- cacheability
- parallelism
- automation parity

Refactoring MUST NOT change externally observable behavior.

Performance improvement is mandatory in REFACTOR whenever a clear, safe opportunity exists.

## 5. Dependency and capability model

- All external systems MUST be represented as abstract capabilities.
- Required capabilities MUST be declared explicitly.
- Concrete implementations MUST be supplied externally at the composition/runtime boundary.
- Business logic MUST NOT construct concrete external dependencies inline.

Capabilities MUST be swappable for fast deterministic tests, support deterministic behavior where caching depends on it, and avoid hidden latency or hidden side effects.

## 6. Test model

All tests MUST:

- represent user intent, contracts, or boundary behavior
- target public interfaces or system boundaries
- interact only through declared capabilities
- be deterministic and isolated
- run independently
- avoid shared global state
- be safe for parallel execution where possible
- minimize unnecessary waits, I/O, and computation

## 7. Automation and CI/CD constraints

- A minimal local developer validation suite is mandatory before any production tests.
- An initial local release-readiness validation suite is mandatory before any production tests.
- A matching minimal GitHub Agentic Workflow is mandatory before any production tests.
- All three must remain aligned for the current scope.
- All three must evolve as production tests and production code evolve.
- Any gate change MUST update the canonical source first.
- No local-only or GitHub-only standards unless explicitly justified and documented.
- Agent execution has no write privileges by default.
- No unguarded remote side effects.
- No unnecessary secret exposure to agent execution.
- No bypass of guarded write jobs.

## 8. Enforcement rules

- No production code without a prior failing production test.
- No production tests before the current-scope automation foundation exists and passes.
- No production TDD before bootstrap is complete for the current scope.
- No passing tests that fail to reflect real user behavior, contracts, or boundary behavior.
- No skipping RED, GREEN, or REFACTOR.
- No combining phases in ways that bypass their intent.
- All dependencies must be supplied from the outside.
- No undocumented automation drift between local and GitHub.
- No unsafe agentic write path.
- No stale or lagging automation foundation: it may start minimal, but it must evolve with the system.
- No unnecessary slow feedback loops, full rebuilds, full test runs, or serialized workflows where safe parallelism is possible.

## 9. Definition of done

A task is complete only when:

- bootstrap for the current scope was done first
- the local developer suite exists and passes for the current scope
- the local release-readiness suite exists and passes for the current scope
- the matching GitHub Agentic Workflow exists and passes for the current scope
- automation was updated wherever new tests, code, boundaries, gates, build steps, or release concerns required it
- all production tests were written first
- all relevant tests pass
- REFACTOR was performed as needed
- dependencies are declared and externally supplied
- tests verify real-world behavior, contracts, or boundary behavior
- local and GitHub gates still match as closely as environments allow

And:

- build time is minimized
- test execution is fast and parallel where safe
- linting and type checking are incremental and fast where supported
- feedback loops are as close to instantaneous as feasible
- affected-only execution is used where correct
- caches are effective where enabled
- automation remains deterministic
- the agentic workflow remains guarded and minimal-permission

## 10. Code structure constraints

- Maximum production-code nesting depth: **3**
- For tests, nesting is measured relative to each individual test block.
- Maximum construct size: **30 LOC**
- Maximum file size: **200 LOC**
- Every construct must have a single clear responsibility.

A construct means any language-level unit such as a function, method, class, interface, type, struct, protocol, enum, trait, module-level unit, or equivalent.

Prohibited:

- nesting depth > 3
- multi-responsibility constructs
- hidden complexity via nested closures or deep control flow
- oversized test blocks that obscure behavior

Required refactoring strategies:

- flatten control flow
- prefer pure functions where appropriate
- use declarative pipelines where appropriate
- extract small focused units
- restructure instead of tolerating complexity

These are hard constraints. Violations must be resolved immediately. Performance is never an excuse to violate them.

## Output format for print mode

When running in print mode (`-p`), always end your response with a structured status block:

```json:status
{
  "phase": "BOOTSTRAP|RED|GREEN|REFACTOR|ANALYSIS",
  "gates_passing": ["format", "lint", "typecheck", "test"],
  "gates_failing": [],
  "files_changed": ["src/foo.ts", "test/foo.test.ts"],
  "git_commit": "abc1234",
  "git_pushed": false,
  "next_step": "description of recommended next action"
}
```

Field requirements:
- `phase`: one of `BOOTSTRAP`, `RED`, `GREEN`, `REFACTOR`, `ANALYSIS`
- `gates_passing`: array of gate names that currently pass
- `gates_failing`: array of gate names that currently fail
- `files_changed`: array of file paths modified in this turn
- `git_commit`: commit hash string if committed, or `null` if not
- `git_pushed`: boolean — whether the commit was pushed
- `next_step`: non-empty string describing the recommended next action

This block is machine-parsed by Computer. It must be valid JSON and must appear as the final fenced code block in your response.

## Required working style

When implementing:

- first determine whether the automation foundation exists and passes for the current scope; if not, work only on bootstrap
- establish a minimal local CI/CD configuration and matching minimal GitHub Agentic Workflow before any production tests
- do not wait for a perfect final CI/CD design; establish the smallest deterministic, safe, working foundation that covers the current scope
- evolve local CI/CD and the GitHub workflow as tests and code evolve
- prefer minimal explicit scripts/configuration over large opaque frameworks
- reuse one canonical source of truth for local and GitHub gates wherever possible
- keep changes narrowly scoped and reversible
- validate the smallest correct scope first, then expand only as needed
- state exactly which files, gates, and targets you inspected or changed
- never claim parity, determinism, cache correctness, test passing, or build validity unless you actually verified it
- if a shortcut would violate bootstrap, TDD order, parity, safety, determinism, structure, or performance constraints, refuse it and propose the next compliant step
- optimize for maintainable human understanding, not maximum autonomous output
- build less, but build it clearly, observably, and correctly

If you violate any constraint in this contract, including bootstrap, parity, safety, structure, determinism, or performance constraints, the output is incorrect.
