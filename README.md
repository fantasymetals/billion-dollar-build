# Billion Dollar Build

A starter kit for running a real company where Perplexity Computer does the work, not just the errands. Five moving parts, five clear jobs, and the walls between them enforced by infrastructure instead of hope.

Built for anyone entering the [Perplexity Billion Dollar Build](https://www.perplexity.ai/computer/a/the-billion-dollar-build-ZWzIFW.FTaKdLtufMa0yhw) competition, and useful well past it. If you want to scale solo instead of 50, this is the shape that makes it work. Computer runs your core product and your business ops. Pi writes the code. The separation is what keeps the whole thing from turning into AI slop. Fork it, copy it, strip it down, extend it. It exists so you do not have to rebuild the entity-separation problem from scratch.

## In plain English

You talk to Computer in a normal chat window. Computer is the brain: it reads your messages, browses the web, opens apps, and runs the work. When there is code to write, Computer hands the job to Pi. Pi is a small coding agent living inside a locked-down sandbox called E2B. Pi is the only thing that ever touches your actual code. You never open a terminal. You never install anything on your laptop. You never run a command yourself.

The only thing on your machine is a browser: Comet. Everything else (the sandboxes, the tooling, the model routing) runs in the cloud on Perplexity's and E2B's infrastructure. The split matters. The brain has wide powers: search the internet, run ops, talk to every service. The hands are deliberately narrow, because narrow hands write reliable code.

```
 You (human, in Comet browser)
        │
        │  natural language
        ▼
 Space (persistent context: instructions, files, links, connectors)
        │  shapes behavior (inert: does not execute)
        ▼
 Computer (execution agent: cloud sandbox + cloud browser + local browser)
   ├── Cloud sandbox: e2b CLI, bun, git, bash, file generation
   ├── Cloud browser: autonomous web research (isolated, per-task)
   ├── Local browser (Comet): user's logged-in sessions (with permission)
   ├── Connectors: Gmail, Slack, GitHub, Salesforce, HubSpot, etc.
   ├── Subagents: parallel research, document production
   ├── Scheduling: cron jobs for recurring business tasks
        │
        │  e2b sandbox create / exec
        ▼
 E2B Sandbox (Firecracker microVM, GitHub-only network)
   Pi Session (deterministic code execution)
   4 tools: read, write, edit, bash
   └── SOLE OPERATOR of /home/user/project/
```

Read it top to bottom: you describe what you want, Computer figures out how, Pi does the code inside the sandbox and reports back. Everything shows up in your chat thread.

---

## Table of contents

**Getting started (for everyone)**

- [Why this exists](#why-this-exists)
- [Prerequisites](#prerequisites)
- [Setup guide](#setup-guide)
  - [Step 1: Create your Perplexity account](#step-1-create-your-perplexity-account)
  - [Step 2: Create your Perplexity Space](#step-2-create-your-perplexity-space)
  - [Step 3: Let Computer set up everything else](#step-3-let-computer-set-up-everything-else)
  - [Step 4: Verify the separation](#step-4-verify-the-separation)
- [Key principles](#key-principles)
- [Beyond the contest](#beyond-the-contest)

**Technical reference (for engineers)**

- [The execution protocol](#the-execution-protocol)
- [Architecture: Five entities, strict separation](#architecture-five-entities-strict-separation)
  - [Space vs Computer: The critical distinction](#space-vs-computer-the-critical-distinction)
  - [Layer 1: Space (persistent context)](#layer-1-space-persistent-context)
  - [Layer 2: Computer (execution agent)](#layer-2-computer-execution-agent)
  - [Layer 3: Pi (sole codebase operator)](#layer-3-pi-sole-codebase-operator)
  - [Layer 4: E2B (transparent pipe)](#layer-4-e2b-transparent-pipe)
  - [Why two sandboxes](#why-two-sandboxes)
- [Computer Use: Cloud browser and local browser](#computer-use-cloud-browser-and-local-browser)
- [Business operations via Computer](#business-operations-via-computer)
- [The output return chain](#the-output-return-chain)
- [GitHub enforcement: Making the boundaries unbreakable](#github-enforcement-making-the-boundaries-unbreakable)
- [Pi GitHub-only network access](#pi-github-only-network-access)
- [What this scaffold contains](#what-this-scaffold-contains)
- [Custom E2B sandbox template](#custom-e2b-sandbox-template)
- [Communicating with Pi via E2B CLI](#communicating-with-pi-via-e2b-cli)
- [Scripts](#scripts)
- [Operational knowledge (from end-to-end validation)](#operational-knowledge-from-end-to-end-validation)
- [Citations](#citations)

---

## Why this exists

The BDB competition asks one question: is Perplexity Computer actually running your business, or is it an occasional assistant? Judges want to see the engine, not the helper.

Most entrants are going to fall into the same trap. They will use Computer for research, then jump to Cursor or Claude Code to write the software. That is peripheral usage. Judges will notice.

This scaffold is the shortcut. Wiring Computer in as the real control plane is the hard part, and it is already done here. So you spend your time on product, not plumbing. Every code task flows through a conversation in your Space, which tells Pi what to build inside a secure E2B sandbox. Every business task (finding customers, handling support, researching the market, managing finances) flows through Computer's browser and connectors.

None of this is specific to the contest. The same separation of responsibilities is what lets a small team run a company without hiring fifty people. BDB is the reason to start. The scaffold is the thing that keeps paying off afterward.

| Criterion | Layer | How |
|---|---|---|
| Massive market | Computer (research + analysis) | Web search validates TAM. RAG over market reports. Memory tracks evolving thesis. |
| Computer is the engine | Whole architecture | Computer IS the control plane. Every task routes through Computer. Not peripheral. |
| Real traction | Computer + Pi | Computer runs business ops (acquisition, support). Pi ships features fast. Rapid iteration drives users. |
| Wild economics | Pi + E2B | 4-tool agent builds real code in isolated sandbox. TDD-first. No slop. Solo, not 50. |
| Founder-market fit | Space (persistent memory) | Memory persists your thesis. Research deepens conviction. Iteration log proves the build. |

---

## Prerequisites

Good news: nothing to install on your laptop. No Bun, no E2B CLI, no Git. Computer has all of that in its own cloud sandbox. What you actually need is a small stack of accounts and credentials. Computer does the tooling.

| What you need | Details |
|---|---|
| **Perplexity Pro or Max subscription** | Required to enter BDB and use Computer. [Subscribe here](https://www.perplexity.ai/settings/subscription). Pro is $20/mo, Max is $200/mo. |
| **E2B account + API key** | Free $100 in credits. [Sign up here](https://e2b.dev). You create the account, paste the API key into the Space thread, and Computer takes it from there. |
| **Model provider credentials** | Any provider Pi supports. A ChatGPT Plus/Pro subscription via Codex OAuth is the recommended path. Other options: Anthropic Claude Pro/Max, GitHub Copilot, Google Gemini CLI, Google Antigravity, or an API key from OpenAI, Anthropic, Google, Groq, xAI, OpenRouter, and others. See [Pi providers](https://github.com/badlogic/pi-mono/tree/main/packages/coding-agent#providers--models). |
| **GitHub credentials** | A Pi Codebase Operator GitHub App (short-lived tokens for Pi's commits) and a read-only `PAT_COMPUTER` token (lets Computer read the repo). Both scoped to repos in your org. |
| **Comet browser** | Chromium-based browser built to work with AI. [Get started](https://www.perplexity.ai/help-center/en/articles/11172798-getting-started-with-comet). |

### Model provider details

Pi is provider-agnostic. Pick whichever subscription or API key you already have. The scaffold defaults to Codex OAuth because most builders already pay for ChatGPT, but any supported provider works with two flags.

**Codex OAuth (recommended if you have ChatGPT Plus/Pro)**

Codex OAuth rides on your existing ChatGPT subscription. No separate API key. It unlocks `gpt-5.4` (272K context window, 128K output tokens) and the rest of the OpenAI models.

- Auth: run `pi auth` and follow the OAuth flow. Credentials land at `~/.pi/agent/auth.json`.
- Provider flag: `--provider openai-codex`
- Model flag: `--model gpt-5.4`

**Any other Pi-supported provider**

Pi ships with built-in support for subscriptions (Anthropic Claude Pro/Max, GitHub Copilot, Google Gemini CLI, Google Antigravity) and API keys (OpenAI, Anthropic, Azure OpenAI, Google Gemini, Google Vertex, Amazon Bedrock, Mistral, Groq, Cerebras, xAI, OpenRouter, Vercel AI Gateway, ZAI, OpenCode Zen, OpenCode Go, Hugging Face, Kimi For Coding, MiniMax). Full list and setup: [Pi providers & models](https://github.com/badlogic/pi-mono/tree/main/packages/coding-agent#providers--models).

The pattern is the same for all of them:

- Subscription: run `pi` then `/login` and pick the provider.
- API key: export the provider's env var (e.g. `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `GEMINI_API_KEY`, `GROQ_API_KEY`, `XAI_API_KEY`, `OPENROUTER_API_KEY`) or paste it when Pi prompts.
- Provider flag: `--provider <name>` (e.g. `anthropic`, `openai`, `google`, `groq`, `xai`, `openrouter`).
- Model flag: `--model <id>` (any tool-capable model that provider exposes). See [Pi models doc](https://github.com/badlogic/pi-mono/blob/main/packages/coding-agent/docs/models.md) for the current list, or run `/model` inside Pi to pick one.

---

## Setup guide

This assumes you are starting from zero. You only have to do two things by hand: create your Perplexity account and create your Space. After that, you paste one prompt into Computer and it handles the rest.

### Step 1: Create your Perplexity account

1. Go to [perplexity.ai](https://www.perplexity.ai) and sign up.
2. Subscribe to **Perplexity Pro** ($20/mo) or **Perplexity Max** ($200/mo) at [Settings → Subscription](https://www.perplexity.ai/settings/subscription).
   - Pro gives you access to Computer and Spaces. You will need to buy extra credits separately.
   - Max gets you higher usage limits and 10,000 monthly credits. Recommended if you are building full-time ([How Credits Work](https://www.perplexity.ai/help-center/en/articles/13838041-how-credits-work-on-perplexity)).
3. Register for the Billion Dollar Build at [The Billion Dollar Build](https://www.perplexity.ai/computer/a/the-billion-dollar-build-ZWzIFW.FTaKdLtufMa0yhw).

### Step 2: Create your Perplexity Space

A Space is a saved workspace. It holds the instructions, files, links, and app connections you want Computer to have on hand. Every conversation thread you start inside that Space inherits all of it automatically ([Perplexity Help Center: What are Spaces?](https://www.perplexity.ai/help-center/en/articles/10352961-what-are-spaces)).

1. On [perplexity.ai](https://www.perplexity.ai), click **Spaces** in the left sidebar.
2. Click **New Space** (the `+` button).
3. Name it after your project (e.g., `my-startup-build`).
4. Add **Custom Instructions**. Two pieces here. The Space's custom instructions field has a practical limit of about 1,500 characters: enough for roles and hard rules, not enough for every detail. So you paste the short **Core Instructions** into the field and upload the longer **Extended Operating Manual** as a file.

**Part 1: Core Instructions.** Paste into the Space Custom Instructions field. Replace `[YOUR COMPANY NAME]`, `[YOUR_ORG]`, and `[YOUR_REPO]` with your actual values:

```
This Space is the operating system for [YOUR COMPANY NAME].
Codebase: github.com/[YOUR_ORG]/[YOUR_REPO]
Full entity boundaries: see "BDB Space Operating Manual" (uploaded file).

SPACE is inert: holds instructions, files, links, connectors. Does not execute.

COMPUTER (you) owns two domains:

PRODUCT DEVELOPMENT: orchestrate Pi via E2B CLI:
- Never write code directly; formulate Pi prompts instead
- Pi is sole codebase operator: read/write/edit/bash + all git ops
- E2B streams Pi's stdout/stderr verbatim: ONLY code feedback channel
- Read Pi's stdout; never inspect files inside the E2B sandbox

BUSINESS OPERATIONS: own end-to-end:
- Customer acquisition, support, market research, competitive intelligence
- Financial modeling, investor relations, content/marketing, analytics, sales, legal
Use cloud browser (public sites), local browser/Comet (authenticated, with permission),
connectors (Gmail, Slack, Salesforce: preferred), Skills (Research, Finance,
Legal, Sales, Marketing, CX, Accounting, PM, Slides), subagents, scheduling.

Use my computer and open tabs in my local browser for all authentication.
You have my permission: do not ask again.

HARD LIMITS: Computer never:
- Writes code directly (→ Pi via E2B)
- Pushes to GitHub (PAT_COMPUTER is read-only; 403 enforced)
- Runs tests inside E2B sandbox (Pi's domain)
- Accesses local filesystem/shell (Comet is browser-only)
Pi never reaches general internet (GitHub-only via E2B network filtering).

Follow all instructions without drifting from the task.
```

**Part 2: Extended Operating Manual.** Upload the `BDB Space Operating Manual` file to the Space's Files section. This document (available in this repo) gives Computer the complete IS / IS NOT definitions for all five entities via RAG:
- **Space**: inert context container. Cannot execute. Cannot inject into Pi's context.
- **Computer**: execution agent. Responsible for E2B orchestration, cloud browser, local browser, 400+ connectors, 19+ models, all business operations. NOT responsible for writing code, pushing to GitHub, running tests in E2B, accessing local filesystem.
- **E2B**: transparent pipe. Streams Pi's stdout/stderr verbatim, no interpretation. NOT an initiator. NOT a network router for Pi.
- **Pi**: sole codebase operator. 4 tools (read/write/edit/bash) plus all git ops. Reads `.pi/SYSTEM.md` and `AGENTS.md`. Reports via stdout. NOT able to reach general internet, use web search, or call external APIs.

The manual also contains: complete output return chain diagram with source references, connector priority rule, and anti-drift boundary table for long sessions.

**Why the Hard Limits block matters:**
Three of the five limits in the core instructions are already enforced by infrastructure. The read-only `PAT_COMPUTER` token blocks GitHub pushes. E2B's network filtering blocks Pi's general internet access. The org-level `pi-sole-writer` ruleset (bypass only for the Pi Codebase Operator App) blocks every push that does not come from Pi, including from admin accounts. Stating the limits in the instructions adds a second line of defense at the prompt layer. The fourth limit (Comet is browser-only) clears up a common misconception that "use my computer" grants access to your files. The fifth (Pi's network restriction) stops Computer from giving Pi instructions that assume it can reach the internet.

5. Set **Links**. Add domains relevant to your tech stack AND your business:
   - `e2b.dev/docs` for E2B sandbox documentation
   - `pi.dev` for Pi agent documentation
   - `bun.sh/docs` for Bun runtime documentation
   - `docs.your-framework.dev`: replace with your primary framework
   - `your-company.com`: your own domain for product research
   - Competitor domains for competitive intelligence prioritization
   - Your industry's primary publication domain

6. Upload **Files**. Drag and drop relevant docs. Do NOT upload `.pi/SYSTEM.md` or `AGENTS.md` (those are Pi-layer config, not Space config). Upload:
   - `BDB Space Operating Manual`: entity boundary reference for Computer (required)
   - Architecture diagrams or ADRs
   - API contracts / OpenAPI specs
   - Business plan / pitch deck
   - Financial model / projections
   - Customer persona documents
   - Brand guidelines / voice guide
   - Legal templates (NDA, ToS, privacy policy)

7. **Connect Connectors.** Go to [Settings → Connectors](https://www.perplexity.ai/settings/connectors) and enable:

   *Development:*
   - **GitHub**: Computer reads issues, PRs, and repo metadata (read-only)
   - **Linear**: if you use Linear for task tracking
   - **Notion**: if you use Notion for docs and specs
   - **Google Drive**: if you use Drive for shared files

   *Business operations (pick the ones that apply):*
   - **Gmail**: customer communication, investor outreach, sales sequences
   - **Slack**: team communication, support channels
   - **Salesforce / HubSpot**: CRM and sales pipeline
   - **Stripe**: payment monitoring and revenue tracking

8. **Configure Space Tasks.** In the Space settings, create scheduled tasks for autonomous operations ([Perplexity Tasks docs](https://www.perplexity.ai/help-center/en/articles/11521526-perplexity-tasks)). Tasks run in the Space context, inheriting your instructions, files, and connectors. Computer executes them; Space is still inert configuration. Recommended cadence:
   - **Daily**: competitor monitoring (web sources), customer support triage (connector), market news briefing
   - **Weekly (Monday)**: metrics dashboard, sales pipeline review
   - **Weekly (Friday)**: investor update draft, financial metrics summary

9. **Activate Skills.** Computer has built-in Skills for domain-specific workflows ([Perplexity Skills docs](https://www.perplexity.ai/help-center/en/articles/13914413-how-to-use-computer-skills)). The custom instructions template already tells Computer to use them proactively. You can also create custom Skills by uploading `.md` files with YAML frontmatter to the Space:
   - `[company]-brand-voice.md`: your specific tone, vocabulary, and voice
   - `[company]-customer-personas.md`: customer segments and decision criteria
   - `[company]-coding-patterns.md`: stack patterns and Pi prompt templates

### Step 3: Let Computer set up everything else

Open a new thread inside your Space and paste this prompt. Computer does everything in its cloud sandbox. You only step in when something asks you to sign in or confirm an action.

```
Set up the full BDB development environment for me:

1. CONNECTORS: Use my computer to open Settings → Connectors so I can
   enable GitHub and any others I need.

2. E2B: Use my computer to open e2b.dev so I can create an account.
   Walk me through the API key. I'll paste it here.

3. BUN: Install Bun in your sandbox with `curl -fsSL https://bun.sh/install | bash`.

4. MODEL PROVIDER: pick any Pi-supported provider. Codex OAuth
   is recommended if you have ChatGPT Plus/Pro (run `pi auth` and
   follow the OAuth flow). Otherwise use any other provider Pi
   supports (Anthropic, OpenAI, Google, Groq, xAI, OpenRouter, and
   more). Use my computer to open the provider's console so I can
   grab a subscription login or API key. Full list:
   https://github.com/badlogic/pi-mono/tree/main/packages/coding-agent#providers--models

5. GITHUB CREDENTIALS:
   a. Pi Codebase Operator GitHub App: install on your org so Pi
      can get short-lived installation tokens for git push operations.
   b. PAT_COMPUTER (contents: read): for Computer to
      read the repo. Scoped to all repositories in your org. I'll paste it here.

6. GITHUB RULESET: Set up the org-level pi-sole-writer ruleset on your
   org targeting all repositories and all branches, with bypass
   only for the Pi Codebase Operator App.

7. TEMPLATE: Clone this scaffold. Run `bun install` then
   `bun run scripts/build-template.ts` to build the E2B template.

8. BOOTSTRAP: Run `bash scripts/bootstrap.sh <template-name> <repo-url>`.
   This creates a sandbox, clones the repo, installs dependencies, and
   injects auth. Pi needs `bun install` before it will operate;
   bootstrap.sh handles this automatically.

9. VERIFY: Run `bash scripts/verify.sh` to confirm 9/9 checks pass
   (infra + Pi diagnostic). If all pass, Pi is ready to receive prompts.
```

The handoff is just a normal conversation turn. Computer does as much as it can on its own in its cloud sandbox. When it hits something that requires you (signing into a service, approving an OAuth screen, pasting an API key) it pauses, opens the relevant page in your local Comet browser, tells you exactly what to do, and waits for your reply.

### Step 4: Verify the separation

Once setup is done, spend two minutes sanity-checking that the layers are actually staying in their lanes.

**In your Perplexity Space:**
- Ask Computer to research a technical decision. It should use web search, RAG, and memory.
- Ask Computer to implement a feature. It should formulate instructions for Pi, not write code itself.

**In your Pi session (E2B sandbox):**
- Pi should follow the execution protocol in `.pi/SYSTEM.md`.
- Pi should enforce TDD-first from `AGENTS.md`.
- Pi should have no access to web search, external APIs, or Perplexity features. Only GitHub.
- Pi should only use its 4 tools: read, write, edit, bash.

If Pi is doing research, or Computer is writing code directly, the layers are bleeding into each other. Fix the separation before you keep building.

---

## Key principles

A handful of ideas shape every decision in this scaffold. They are short on purpose.

### Intelligence ≠ Execution
Perplexity is brilliant at research, search, memory, and orchestration. Pi is brilliant at deterministic code execution. Combining them through separation (not merging) is what makes the thing work.

### Space ≠ Computer
Space is configuration. Computer is execution. Space is to Computer what `.pi/SYSTEM.md` is to Pi. Never conflate the two.

### Deterministic gates kill slop
The agent cannot claim tests pass without running them. Format, lint, type-check, test, build: all must pass. Every gate is deterministic. In the AI slop era, this is how you ship code that actually works.

### Computer as the engine, not the assistant
You do not need to fake it. When every task routes through Computer (code orchestration via E2B/Pi, business ops via browser/connectors, research via web search, scheduling via cron) Computer IS genuinely running your operations. The architecture proves it.

### Enforcement over instruction
Custom instructions say "never write code directly." Infrastructure says "403 Forbidden." Both matter. Infrastructure matters more.

---

## Beyond the contest

The Billion Dollar Build ends on June 2, 2026. This scaffold, and the architecture it encodes, does not. It is here for anyone participating in BDB, and for anyone who never enters at all.

### Why enforced separation endures

The separation of responsibilities in this scaffold is not a contest requirement. It is an engineering discipline that prevents the "AI slop" failure mode at scale.

The failure mode: as AI-generated code scales, quality degrades unless execution is constrained. An agent with unlimited access (internet, filesystem, arbitrary APIs, direct repo writes) produces code that works in demos but breaks in production. The surface area is too large. The feedback loops are too long. The accountability is too diffuse.

The fix: give each entity one job. Pi only touches code. Computer only orchestrates and runs business operations. Space only holds configuration. E2B only transports. GitHub enforcement makes the boundaries physical, not verbal.

### The enforcement layers are real infrastructure

This is not a prompt engineering exercise. The three GitHub enforcement layers (a read-only fine-grained PAT for Computer, installation tokens for Pi generated by a GitHub App, an org-level ruleset (`pi-sole-writer`) that only the App can bypass, and E2B network filtering that restricts Pi to GitHub-only traffic) are real infrastructure controls operating at the API and network level.

Delete your Space custom instructions entirely and the enforcement still holds. Computer still cannot push (GitHub returns a 403). Pi still cannot reach the internet (blocked by E2B network filtering). The boundaries are structural, not behavioral.

### Space primitives compound over time

The Space is not a one-time configuration artifact. Its primitives (Space Tasks, Skills, and search sources) compound in value as the company grows.

Space Tasks run on their own schedule, pulling in threads of competitive intelligence, metrics, investor updates, and support triage that would otherwise eat daily human attention. Week by week, Computer adds to the body of institutional knowledge in the Space: not just executing tasks, but building a searchable history of company operations that every new thread can pull from.

Skills make Computer steadily more effective as you customize them. Your brand voice Skill makes every piece of content sound like your company. Your coding patterns Skill makes every Pi prompt more precise. Your customer persona Skill makes every outreach sequence more relevant. These are not one-off configurations. They are durable operational assets that improve every interaction.

Search source configuration means Computer's research is always grounded in the right data tier: premium market data for TAM questions, SEC filings for investor research, academic papers for technical depth, social channels for customer sentiment. The Space routes every business function to its highest-signal source automatically.

The enforcement layers (PATs, rulesets, E2B network filtering) make the code boundaries unbreakable. The Space primitives (Tasks, Skills, configured sources) make business operations progressively more autonomous. Together, they are the operating system for a company that runs solo + Computer.

### What solo + Computer actually means

The BDB judging criteria include "wild economics": if competitors need 50 people and you need 1 + Computer. The architecture makes that concrete:

- **Engineering**: Pi writes code in TDD cycles. Computer formulates the prompts, reads the output, orchestrates the build. You review.
- **Customer acquisition**: Computer researches leads (cloud browser), drafts outreach (connectors), posts on social media (local browser), manages ads (local browser), deploys landing pages (cloud sandbox).
- **Customer support**: Computer triages tickets (connectors), drafts responses, monitors live chat (local browser), builds knowledge base articles (cloud sandbox).
- **Market research**: Computer browses competitor sites, extracts pricing, monitors news (cloud browser). Scheduled daily/weekly via cron.
- **Finance and legal**: Computer generates financial models, reviews contracts, flags risks (cloud sandbox skills).
- **Investor relations**: Computer builds pitch decks, financial reports, sends updates (cloud sandbox + connectors).

The architecture is not "use AI to help." It is "AI runs the company, human provides judgment at decision boundaries."

### Using this scaffold for your own company

Nothing project-specific is baked in. Anyone participating in BDB (or building outside of it) can fork or copy the scaffold as the starting point for their own entry. You are not inheriting someone else's company. You are inheriting the entity-separation architecture.

> **Create an empty repo and copy the scaffold contents.** The `pi-sole-writer` org-level ruleset blocks all pushes except from the Pi Codebase Operator App. Copying into an empty repo lets you push with the App token in step 3.

1. Create a new **empty** private repo in your org:
   ```bash
   gh repo create your-org/your-repo --private --clone
   cd your-repo
   ```
2. Copy the scaffold contents in:
   ```bash
   # From a local clone of this repo (or download the zip)
   cp -r /path/to/billion-dollar-build/* /path/to/billion-dollar-build/.* your-repo/ 2>/dev/null
   cd your-repo
   git add -A && git commit -m "Initial commit: BDB scaffold"
   ```
3. Push using the Pi Codebase Operator App token (your org ruleset blocks direct pushes):
   ```bash
   # Generate an App installation token first
   APP_TOKEN=$(python3 scripts/generate-app-token.py /path/to/private-key.pem APP_ID INSTALLATION_ID 2>&1 | grep '^ghs_')
   git remote set-url origin "https://x-access-token:${APP_TOKEN}@github.com/your-org/your-repo.git"
   git push origin main
   ```
4. Replace `.pi/SYSTEM.md` and `AGENTS.md` with your own project contracts.
5. Create a Pi Codebase Operator GitHub App on your org (for Pi's write access) and create `PAT_COMPUTER` (read-only, for Computer) scoped to all repositories in your org.
6. Set up the `pi-sole-writer` org-level ruleset with bypass only for the Pi Codebase Operator App.
7. Create your Perplexity Space with the custom instructions template.
8. Let Computer build the E2B template (`bun run scripts/build-template.ts`) and bootstrap the sandbox (`bash scripts/bootstrap.sh`).
9. Run `bash scripts/verify.sh` to confirm 9/9 checks pass.
10. Start building.

The contest is optional. The architecture works for any company that wants deterministic code execution, enforced separation, and AI-driven business operations at scale. This scaffold is just the shortest path to both.

---

# Technical reference

Everything below is for engineers who want to understand or extend the architecture. If you are shipping a product, the sections above are enough to get started. Come back here when you need to change how the system works.

---

## The execution protocol

This scaffold enforces a deterministic coding process through `.pi/SYSTEM.md` and `AGENTS.md`. Here is what Pi does when it receives instructions from Computer:

### Phase 0: Bootstrap
Before any production code, Pi establishes the automation foundation:
- Local developer validation suite (format, lint, type-check, test)
- Local release-readiness validation suite
- Deterministic gates that must all pass
- Matching GitHub Actions workflow

### Phase 1: RED
Write a failing test that represents the behavior you need.

### Phase 2: GREEN
Write the smallest amount of code to make the test pass.

### Phase 3: REFACTOR
Improve structure, readability, and performance without changing behavior.

Every cycle is verified. Pi cannot claim tests pass without running them. Pi cannot skip phases. Pi cannot hallucinate its way past a failing gate.

This is what "no slop" means in practice.

---

## Architecture: Five entities, strict separation

Every decision in this architecture derives from a strict separation across five distinct entities. Not three. Not two. Five. Each with a clearly defined role and hard boundaries.

| Entity | What It Is | Does | Does NOT |
|---|---|---|---|
| **You** (human, in Comet browser) | The human operating the Comet browser on a local machine | Describe what needs building. Review results. Make decisions. Approve high-stakes actions (OAuth, payment, sending emails). Act at authentication boundaries. | Touch code. Run tests. Push to GitHub. Run E2B CLI commands. |
| **Space** (persistent context container) | A named workspace holding custom instructions, files, links, and connector configurations ([Perplexity Help Center: What are Spaces?](https://www.perplexity.ai/help-center/en/articles/10352961-what-are-spaces)). Persists across threads. Shapes Computer's behavior. | Hold build process rules, focused search domains, uploaded reference docs, connector configs, persistent memory across sessions. **Space is to Computer what `.pi/SYSTEM.md` is to Pi**: configuration that defines behavior, not an agent that performs it. | Execute anything. Space is inert. It does not run commands, call APIs, browse the web, or take actions. |
| **Computer** (execution agent) | Perplexity's autonomous digital worker running in an isolated cloud sandbox ([Perplexity Help Center: What is Computer?](https://www.perplexity.ai/help-center/en/articles/13837784-what-is-computer)) | **Codebase orchestration**: run E2B CLI, formulate Pi prompts, read Pi stdout/stderr. **Cloud sandbox**: bash, git clone (read-only mirror), file generation (PDF/PPTX/XLSX), website deployment. **Cloud browser**: autonomous web browsing (isolated, per-task). **Local browser (Comet)**: user's logged-in sessions with permission: OAuth, social media, CRM, support portals, ad platforms, analytics dashboards. **Business ops**: customer acquisition, support, market research, finance, legal, sales, content, investor relations. **Connectors**: Gmail, Slack, GitHub (read-only), Salesforce, HubSpot, Snowflake, etc. | Write to Pi's managed GitHub repo. Run tests inside E2B sandbox. Access user's local filesystem or shell: only the local Comet browser, with permission. |
| **E2B** (transparent pipe) | E2B cloud sandbox ([Firecracker microVM](https://e2b.dev/blog/firecracker-vs-qemu)) | Transport commands into the sandbox. Stream stdout/stderr back to Computer in real-time ([E2B source, exec.ts lines 112-127](https://github.com/e2b-dev/E2B)). Forward exit codes ([exec.ts lines 141-143](https://github.com/e2b-dev/E2B)). | Interpret or transform output. Add business logic. Initiate requests. |
| **Pi** (sole codebase operator) | The coding agent inside the E2B sandbox ([pi.dev](https://pi.dev)) with GitHub-only network | All codebase operations: read, write, edit, bash, git push/pull/commit. Network restricted to GitHub only via E2B domain filtering. Uses App installation tokens generated by the Pi Codebase Operator GitHub App (App ID: 3402043): the only credential that can push. | Access the general internet. Reach Perplexity. Call non-GitHub APIs. Download arbitrary packages. |

### Space vs Computer: The critical distinction

**Space and Computer are not the same thing.** This is the single most important architectural distinction.

**Space** is a persistent context container: a named workspace that holds custom instructions, files, links, and connector configurations ([Perplexity Help Center: What are Spaces?](https://www.perplexity.ai/help-center/en/articles/10352961-what-are-spaces)). It is not a runtime. It does not execute commands. It does not call APIs. When you create a Space and add custom instructions, you are configuring the context that Computer reads when it starts a task. Every thread you open inside that Space inherits its instructions, files, links, and connected services.

**Computer** is the execution agent: Perplexity's autonomous digital worker running in an isolated cloud sandbox ([Perplexity Help Center: What is Computer?](https://www.perplexity.ai/help-center/en/articles/13837784-what-is-computer)). It has a real filesystem, a real shell, a cloud browser instance, access to 19+ orchestrated AI models, and the ability to control your local Comet browser with permission.

**Space is to Computer what `.pi/SYSTEM.md` is to Pi**: a configuration layer that defines behavior, not an agent that performs it.

```
Space (context)                 Computer (execution)
┌────────────────────────┐      ┌─────────────────────────────────┐
│ Custom instructions      │      │ Cloud sandbox (filesystem,     │
│ Uploaded files (RAG)     │      │   shell, tools, E2B CLI)       │
│ Focused search domains   │ ───▶ │ Cloud browser (isolated,       │
│ Connector configurations │      │   per-task sandboxed instance)  │
│ Persistent memory        │      │ Local browser control (Comet,  │
│                          │      │   user's logged-in sessions)    │
│ Inert. Does nothing.     │      │ 19+ AI models                  │
│ Shapes Computer's        │      │ 400+ connectors                │
│ behavior.                │      │ Subagents, scheduling, memory  │
└────────────────────────┘      └─────────────────────────────────┘
```

Why this matters:

1. **Space configuration is one-time setup.** Configure it once (custom instructions, links, files, connectors) and it persists.
2. **Computer execution is per-task.** Each task gets a fresh cloud sandbox with its own filesystem and browser instance ([Computer for Enterprise](https://www.perplexity.ai/help-center/en/articles/13901210-computer-for-enterprise)). Computer reads the Space context at the start of each task.
3. **Space cannot enforce runtime behavior.** Custom instructions are suggestions, not guardrails. The GitHub enforcement layers (PATs, rulesets, E2B network filtering) are the actual enforcement. They operate at the infrastructure level, not the prompt level.
4. **Computer can operate outside any Space.** Computer's capabilities exist regardless of Space configuration. The Space provides context, but Computer does not depend on it.

### Layer 1: Space (persistent context)

Your Perplexity Space is the persistent context layer. It holds the instructions, files, links, and connectors that shape how Computer behaves in every thread ([Perplexity Help Center: What are Spaces?](https://www.perplexity.ai/help-center/en/articles/10352961-what-are-spaces)).

**What Space holds:**
- Custom instructions that define your build process, business operations mandate, and entity role separation rules (two-part system: core ~1,530 chars + Extended Operating Manual file)
- Uploaded files for RAG (architecture docs, API specs, business plan, financial model, customer personas, brand guide, legal templates, BDB Space Operating Manual)
- Focused search domains: technical stack (e2b.dev/docs, pi.dev, bun.sh/docs) plus business domains (company, competitor, industry publication)
- Connector configurations: development (GitHub, Linear, Notion, Google Drive) plus business operations (Gmail, Slack, Salesforce/HubSpot, Stripe)
- Space Tasks: scheduled autonomous operations that Computer executes within the Space context. Daily competitor monitoring, weekly metrics dashboards, support triage, investor update drafts ([Perplexity Tasks docs](https://www.perplexity.ai/help-center/en/articles/11521526-perplexity-tasks))
- Skills: reusable domain-specific workflows Computer activates. Research, Finance, Legal, Sales, Marketing, CX, Accounting, PM, Slides, plus custom company Skills ([Perplexity Skills docs](https://www.perplexity.ai/help-center/en/articles/13914413-how-to-use-computer-skills))
- Search Sources configured per business function: Web + Premium Sources for market research, SEC/Finance for investor research, Academic for technical research, Social for customer sentiment
- Collaboration: Contributor Access for founders and team members, View Access for advisors and investors
- Persistent memory across sessions

**What Space does NOT do:**
- Execute commands
- Call APIs
- Browse the web
- Run E2B CLI
- Take any action

### Layer 2: Computer (execution agent)

Computer is the execution agent, the entity that actually does things ([Perplexity Help Center: What is Computer?](https://www.perplexity.ai/help-center/en/articles/13837784-what-is-computer)). It has its own isolated cloud sandbox where it runs all the tooling commands that drive this architecture.

**What Computer does:**
- Runs E2B CLI commands (`e2b sandbox create`, `e2b sandbox exec`, `e2b sandbox kill`)
- Formulates Pi prompts based on your intent and codebase understanding
- Reads Pi's stdout/stderr (the ONLY feedback channel)
- Clones and reads the repo in its own sandbox (read-only mirror for architecture understanding)
- Runs bash commands, installs tools, processes data, generates documents
- Browses the web autonomously (cloud browser) and via your sessions (local browser/Comet)
- Runs business operations: customer acquisition, support, market research, finance, legal, sales
- 19+ models orchestrated by Perplexity's infrastructure ([Everything is Computer](https://www.perplexity.ai/hub/blog/everything-is-computer))
- 400+ connector integrations ([Computer for Enterprise](https://www.perplexity.ai/help-center/en/articles/13901210-computer-for-enterprise))

**What Computer does NOT do:**
- Touch your production codebase directly
- Run your project's test suite
- Deploy your application
- Push to GitHub (Pi does all git operations on the codebase)

Computer has its own isolated cloud sandbox where it runs all the tooling commands that drive this architecture. When Computer needs to interact with E2B, it runs `e2b sandbox create`, `e2b sandbox exec`, and other CLI commands from this sandbox. This is NOT your local machine and NOT the E2B sandbox where Pi runs. It is Perplexity's own infrastructure.

### Layer 3: Pi (sole codebase operator)

[Pi](https://pi.dev) is the coding agent that actually touches your code. It operates with exactly 4 tools:

- `read`: inspect file contents
- `write`: create new files or full rewrites
- `edit`: precise, minimal edits
- `bash`: run shell commands (including all git operations)

No MCP. No sub-agents. No plan mode. No permission gates. No web search tool.

If Pi needs to do something it cannot do yet, it writes the code to extend itself. That is the philosophy: code writing code.

Pi reads `.pi/SYSTEM.md` (included in this scaffold) for its behavioral contract and `AGENTS.md` for the repo-level operating contract.

**Pi is the sole entity that writes to the GitHub repo.** All git operations (clone, commit, push, branch, tag) happen through Pi's `bash` tool inside the E2B sandbox. Computer reads the results from Pi's stdout.

### Layer 4: E2B (transparent pipe)

[E2B](https://e2b.dev) provides the isolated execution environment where Pi runs your code.

- Firecracker MicroVM isolation ([125ms cold start](https://e2b.dev/blog/firecracker-vs-qemu))
- Full Debian Linux environment
- Your codebase cloned via git
- CLI and SDK-controlled remote execution
- **GitHub-only network**: `denyOut: [ALL_TRAFFIC]`, `allowOut: ['github.com', '*.github.com', '*.githubusercontent.com']` ([E2B docs: Internet access](https://e2b.dev/docs/sandbox/internet-access))

E2B is a transparent pipe. It transports commands into the sandbox, streams stdout/stderr back to Computer in real-time ([E2B source, exec.ts lines 112-127](https://github.com/e2b-dev/E2B)), and forwards exit codes ([exec.ts lines 141-143](https://github.com/e2b-dev/E2B)). It does not interpret, transform, or buffer.

### Why two sandboxes

There are three environments in this architecture, with crystal clear separation:

1. **Your local machine**: runs only the Comet browser. No code executes here. Comet bridges you to Computer and renders the UI where you review work. You only act locally when authentication is needed (OAuth, API keys, account creation).

2. **Computer's sandbox (Perplexity infrastructure)**: where the E2B CLI runs. Computer executes `e2b sandbox create`, `e2b sandbox exec`, `bun install`, `git clone`, and all other tooling commands here. This sandbox has full internet access, multi-model routing, and broad tool access because Computer needs these to be a good orchestrator.

3. **E2B sandbox (Firecracker microVM)**: where Pi runs. Your project code lives here. Tests, builds, linting, the actual product: all execute here. This sandbox has **GitHub-only network access** because Pi needs a locked-down environment to be a good code executor.

| | Computer's Sandbox | E2B Sandbox |
|---|---|---|
| **Purpose** | Intelligence, orchestration, E2B CLI execution, business operations | Deterministic code execution |
| **Who runs here** | Computer (19+ frontier models) | Pi (4 tools, one model) |
| **What runs here** | Web search, RAG, file processing, e2b CLI commands, bun install, git clone (read-only mirror), data transforms, document generation, web browsing | Your project code: tests, builds, linting, the actual product, git push |
| **Controlled by** | Perplexity's infrastructure | Your E2B API key |
| **Persistence** | Ephemeral per task, memory persists in Space | Ephemeral per session, code persists in git |
| **Internet access** | Full (web search, connectors, APIs) | GitHub only (domain filtering) |

The separation is the point. Computer needs internet access, multi-model routing, and broad tool access to be a good orchestrator and run business operations. Pi needs restricted network access, zero external dependencies, and a locked-down environment to be a good code executor. Merging them into one sandbox would mean either giving your code executor internet access it should not have, or stripping the orchestrator of its ability to search, connect, and run a business. Both are worse.

---

## Computer Use: Cloud browser and local browser

Computer has **two distinct browser capabilities** that serve different purposes in this architecture.

### Cloud browser (isolated, autonomous)

Every Computer task runs in a fully sandboxed environment with a dedicated browser instance ([Computer for Enterprise](https://www.perplexity.ai/help-center/en/articles/13901210-computer-for-enterprise): "Each task session runs in its own isolated compute container with a dedicated filesystem and browser instance"). This cloud browser:

- Operates autonomously, no user interaction required
- Is isolated per task: no cross-session data leakage
- Can browse the web for research, data extraction, form filling
- Cannot access your logged-in sessions or local cookies

**Use for**: web research, public data extraction, competitor monitoring, price tracking, content gathering, any browsing that does not require your identity.

### Local browser (Comet) via Computer Use

Computer can control your local Comet browser with explicit permission. This line in your Space custom instructions grants it:

> "Use my computer and open up tabs in my local browser for all links and authentication needed to complete the task being asked."

That grants Computer permission to use your local Comet browser: open tabs, navigate pages, click buttons, fill forms. It does NOT give Computer access to your local filesystem, local shell, or stored credentials. Computer's own code execution happens in Perplexity's cloud sandbox, not on your machine.

Comet is a Chromium-based browser built to work with AI ([Perplexity Help Center: Getting Started with Comet](https://www.perplexity.ai/help-center/en/articles/11172798-getting-started-with-comet)). Computer operates under the same [three principles](https://www.perplexity.ai/hub/blog/comet-assistant-puts-you-in-control) Perplexity applies to all agentic features: transparency (you see every action), user control (you can stop it at any time), and sound judgment (it pauses before high-stakes actions).

**Use for**: anything requiring your identity. OAuth flows, account dashboards, social media posting, CRM interactions, customer support portals, payment platforms, analytics dashboards, ad platforms, email clients (when connector is insufficient).

### When Computer still pauses

Even with "Use my computer" enabled, Computer pauses at actions it judges to be high-stakes or irreversible:

| Action type | What happens |
|---|---|
| **Account creation** | Computer opens the signup page, tells you what to do, waits for your confirmation |
| **OAuth / authorization** | Computer navigates to the auth page but cannot click "Authorize" on your behalf. You do that. |
| **Payment or purchase** | Computer will never complete a transaction without explicit approval |
| **API key handling** | Computer may open the dashboard where keys live, but you copy and paste the key into the chat |
| **Sending emails, messages, or posts** | Computer shows you the draft and waits for approval before sending |
| **Deleting data** | Computer will not delete files, repos, or resources without asking first |

### Choosing the right mechanism

| Mechanism | Use When | Examples |
|---|---|---|
| **Connector** (preferred) | A connector exists for the service | Gmail, Slack, GitHub, Salesforce, HubSpot, Snowflake, Linear, Notion, Google Drive |
| **Cloud browser** | Public/anonymous web browsing | Competitor research, pricing pages, news monitoring, public data extraction |
| **Local browser (Comet)** | User's authenticated identity required AND no connector covers the action | Social media posting, ad platform management, CRM actions beyond connector scope, support portal navigation, analytics dashboards, CMS publishing |

**Key principle**: connectors are preferred over browser automation (more reliable). Cloud browser handles anything public. Local browser (Comet) is the fallback for authenticated actions without connectors.

---

## Business operations via Computer

Computer's browser capabilities and connectors unlock the full spectrum of business operations. This is what makes the architecture endure past the contest. Computer is not just a code orchestrator. It runs your business.

| Business Function | Browser Mode | How Computer Does It |
|---|---|---|
| **Customer acquisition: lead research** | Cloud browser | Browse LinkedIn, Crunchbase, company websites, industry directories. Extract contact info, company data, funding history. No login required. |
| **Customer acquisition: outreach** | Connectors + local browser | Draft emails via Gmail connector. Post on social media via local browser (user's logged-in X/LinkedIn/Reddit). Engage in community forums via local browser. |
| **Customer acquisition: ad management** | Local browser | Navigate Google Ads, Meta Ads Manager, LinkedIn Campaign Manager using user's logged-in sessions. Create campaigns, adjust bids, review analytics. |
| **Customer acquisition: landing pages** | Cloud sandbox | Build and deploy landing pages directly from Computer's sandbox (website deployment capability). No browser needed for the build; cloud browser for testing. |
| **Customer support: ticket triage** | Connectors + local browser | Read tickets via Zendesk/Intercom/Linear connector. For platforms without connectors, navigate the support portal via local browser. Categorize, prioritize, draft responses. |
| **Customer support: live response** | Local browser | Navigate live chat dashboards (Intercom, Crisp, Zendesk Chat) using user's logged-in session. Draft and send responses with user approval. |
| **Customer support: knowledge base** | Cloud sandbox + connectors | Generate help articles, FAQs, documentation in Computer's sandbox. Publish via connector or local browser to the KB platform. |
| **Market research** | Cloud browser | Browse competitor sites, read pricing pages, extract product features, monitor news. All public, no login needed. |
| **Financial modeling** | Cloud sandbox | Generate spreadsheets, charts, financial projections in Computer's sandbox using built-in finance/accounting skills. |
| **Investor relations** | Cloud sandbox + connectors | Build pitch decks (PPTX), financial reports (XLSX/PDF), send updates via Gmail connector. |
| **Content creation** | Cloud sandbox + local browser | Write blog posts, social content, marketing copy in sandbox. Publish via local browser to CMS (WordPress, Webflow, Ghost) using user's logged-in session. |
| **Analytics monitoring** | Local browser + scheduling | Open analytics dashboards (Google Analytics, Mixpanel, Amplitude) via local browser. Schedule recurring checks via cron jobs for daily/weekly briefings. |
| **Sales pipeline** | Connectors + local browser | Read/update Salesforce/HubSpot via connector. For actions beyond connector scope, navigate CRM via local browser. |
| **Legal/contracts** | Cloud sandbox | Review contracts, flag risks, generate redlines using built-in legal skills. All in sandbox, no browser needed. |

---

## The output return chain

**Everything Pi does returns to Computer through E2B.** This is the only feedback channel. Computer does NOT read files from inside the E2B sandbox. Computer reads Pi's stdout. Period.

```
Pi (inside E2B sandbox)
  │ stdout: writeRawStdout(text)         ← print-mode.ts lines 147-151
  │ stderr: console.error(errorMessage)  ← print-mode.ts lines 143-145
  │ exit:   returns exitCode 0 or 1      ← print-mode.ts line 156
  ▼
E2B exec (transparent pipe)
  │ onStdout → process.stdout.write(data)   ← exec.ts lines 112-118
  │ onStderr → process.stderr.write(data)   ← exec.ts lines 120-126
  │ exitCode → process.exit(result.exitCode) ← exec.ts lines 90-92, 141-143
  ▼
Computer (Perplexity cloud sandbox)
  │ reads stdout → Pi's text response (or JSONL events)
  │ reads stderr → Pi's error messages
  │ reads exit code → 0 = success, 1 = Pi error, >1 = infra error
  ▼
Computer decides next prompt based on Pi's output
```

**Source evidence**: Pi's text mode outputs only `text` content blocks from the final assistant message to stdout via `writeRawStdout` ([pi-mono, print-mode.ts lines 147-151](https://github.com/badlogic/pi-mono)). E2B CLI exec registers real-time callbacks that write directly to `process.stdout` and `process.stderr` ([E2B, exec.ts lines 112-127](https://github.com/e2b-dev/E2B)). This is NOT buffered-then-forwarded. Each chunk of Pi's output arrives at Computer as it is produced. The exit code is forwarded directly ([exec.ts lines 141-143](https://github.com/e2b-dev/E2B)).

Nothing is lost. Nothing is transformed. Pi's full output reaches Computer.

---

## GitHub enforcement: Making the boundaries unbreakable

The boundaries (Pi writes, Computer reads) are architectural policy. Policy can be violated by accident. GitHub provides mechanisms that make violations **technically impossible**. Three independent layers, any one of which is sufficient:

### Layer 1: GitHub App installation token (Pi) + fine-grained PAT (Computer)

GitHub fine-grained PATs scope permissions to specific repositories with granular read/write control ([GitHub Docs: Managing your personal access tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)).

| Credential | Used By | Permissions | Purpose |
|---|---|---|---|
| Pi Codebase Operator App installation token | Pi inside E2B sandbox | 14 permissions including `contents: write` | Clone, pull, commit, push. Short-lived (~1hr), auto-expires. Pi is the sole writer. |
| `PAT_COMPUTER` (read-only) | Computer in its own sandbox + GitHub connector | `contents: read`, `metadata: read`, `issues: read`, `pull_requests: read`, `actions: read` | Clone, pull, read files, read issues/PRs, read CI status. Computer never writes. |

`PAT_COMPUTER` is scoped to all repositories under your GitHub organization. It can `git clone` and `git pull` but **cannot** `git push`. GitHub's API returns `403 Forbidden`. Set a custom expiration (max 366 days recommended).

Create `PAT_COMPUTER` at [github.com/settings/personal-access-tokens/new](https://github.com/settings/personal-access-tokens/new) with read-only permissions scoped to all repositories in your org. Pi authenticates via App installation tokens generated by your Pi Codebase Operator GitHub App. No PAT required for Pi.

### Layer 2: Org-level ruleset via GitHub App

An org-level ruleset named `pi-sole-writer` on your GitHub organization targets all repositories and all branches. Rules: Restrict creations, Restrict updates, Restrict deletions, Block force pushes. Bypass: **only** the Pi Codebase Operator App. Admin account excluded ([GitHub Docs: About rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets)). Even if Computer somehow obtains a write token, the ruleset blocks the push from a non-bypass actor. Admin pushes are rejected with `GH013: Cannot update this protected ref`.

Setup: your org → **Settings** → **Rules** → **Rulesets** → **New branch ruleset** ([GitHub Docs: Creating rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/creating-rulesets-for-a-repository)). Name: `pi-sole-writer`. Enforcement: Active. Bypass: Pi Codebase Operator App only. Target: all repositories, all branches (`**`). Rules: Restrict creations + Restrict updates + Restrict deletions + Block force pushes.

### Layer 3: E2B network filtering

Pi's E2B sandbox allows only GitHub traffic, blocking everything else at the network level ([E2B docs: Internet access](https://e2b.dev/docs/sandbox/internet-access)):

```typescript
network: {
  denyOut: [ALL_TRAFFIC],       // Block everything first
  allowOut: [
    'github.com',               // Git HTTPS operations
    '*.github.com',             // Subdomains
    '*.githubusercontent.com',  // Git LFS, raw content
  ]
}
```

Pi cannot reach the general internet, cannot call arbitrary APIs, cannot download arbitrary packages, cannot reach Perplexity's services. The attack surface is limited to authenticated git operations against a known repository.

### Enforcement summary

```
Layer 1: App installation token (Pi, write) + PAT_COMPUTER/BDB-Computer-ReadOnly-FM (Computer, read-only) → GitHub API rejects Computer push (403)
Layer 2: Ruleset "Restrict updates" → GitHub rejects push from non-bypass actors
Layer 3: E2B network filtering → Pi can only reach GitHub; cannot leak code
```

All three layers are independent. Any one is sufficient to prevent Computer from writing to the repo. Together, they make the boundary defense-in-depth.

---

## Pi GitHub-only network access

**Pi's E2B sandbox has network access restricted to GitHub only.** Not the full internet. Not arbitrary APIs. GitHub, and nothing else.

The original BDB architecture states Pi should have "zero internet access by default." We refine this to GitHub-only because:

1. **Pi needs to push.** Pi is the sole entity that writes to the repo. If Pi cannot reach GitHub, Computer would have to extract files from the sandbox and push them, violating the sole operator rule.
2. **Pi needs to pull.** If the repo advances (e.g., a hotfix merged via GitHub UI), Pi needs `git pull` to stay current.
3. **Pi needs to clone.** Pi can clone the repo itself during bootstrap, keeping the initial setup cleaner.
4. **The security posture is equivalent.** GitHub-only means Pi still cannot reach the general internet, cannot call arbitrary APIs, cannot download arbitrary packages. The attack surface is limited to authenticated git operations against a known repository.

E2B domain-based filtering denies all traffic by default, then allowlists specific domains ([E2B docs: Internet access](https://e2b.dev/docs/sandbox/internet-access)). Domain filtering works via Host header (port 80) and SNI inspection (port 443). DNS nameserver `8.8.8.8` is auto-allowed. The SDK's `create` CLI command does NOT expose network flags. Sandbox creation with network filtering requires the SDK or REST API ([E2B source, create.ts](https://github.com/e2b-dev/E2B)).

---

## What this scaffold contains

```
your-project/
├── .github/
│   └── workflows/
│       └── agentic-validation.yml  # CI: runs same gates as local
├── .pi/
│   └── SYSTEM.md                   # Pi agent behavior contract
├── docs/
│   └── automation-foundation.md    # Gate definitions and parity docs
├── scripts/
│   ├── lib/                        # Shared libraries for bridge scripts
│   │   ├── e2b-parse.sh            # Sandbox ID parsing, ANSI stripping
│   │   ├── e2b-exec.sh             # Exec wrapper with stdout/stderr capture
│   │   ├── e2b-lifecycle.sh        # Sandbox alive/kill/list helpers
│   │   ├── pi-invoke.sh            # Pi command construction (build_pi_command)
│   │   ├── pi-parse.sh             # Status block extraction + validation
│   │   └── pi-json-parse.ts        # Bun JSONL stream parser for json mode
│   ├── build-template.ts           # Build custom E2B template (Pi + Bun baked in)
│   ├── bootstrap.sh                # Create sandbox, clone repo, install deps, inject auth
│   ├── verify.sh                   # 9-check verification (infra + Pi diagnostic)
│   ├── run-pi.sh                   # Send prompts to Pi (text/json/--continue/--status-only)
│   ├── check-changed.sh            # Lint/format changed files only, full typecheck+test
│   └── generate-app-token.py       # JWT → GitHub App installation token
├── test/
│   ├── 01-e2b-parsing/             # E2B output parsing tests (3 files)
│   ├── 02-pi-integration/          # Pi invoke/parse tests (3 files)
│   ├── 03-scripts/                 # Script integration tests (3 files)
│   ├── 04-io-convention/           # Status block + dual mode tests (2 files)
│   ├── 05-e2e/                     # End-to-end smoke + error recovery (2 files)
│   └── bootstrap.test.ts           # Bun-native bootstrap test
├── AGENTS.md                       # Repo-level operating contract (Pi reads this)
├── biome.json                      # Formatter + linter config
├── package.json                    # Scripts, dependencies, gate definitions
├── tsconfig.json                   # TypeScript strict config
├── README.md
└── LICENSE
```

**184 tests** across 14 test files (180 bash + 4 Bun), organized in 5 phases matching the TDD implementation plan.

**Critical isolation principle:** `.pi/SYSTEM.md` and `AGENTS.md` are ONLY for Pi. They define how the coding agent behaves inside the E2B sandbox. They have nothing to do with Perplexity Space configuration. Mixing the two defeats the entire architecture. Intelligence and execution must stay separated.

---

## Custom E2B sandbox template

The scaffold includes `scripts/build-template.ts`, which bakes Pi and Bun into an E2B snapshot. Computer runs this build script in its sandbox. You just provide the E2B API key. Once built, every subsequent sandbox starts instantly from the pre-baked image. Zero install time per run.

**What the template does:**
- Starts from `oven/bun` base image (`fromBunImage('latest')`)
- Installs ripgrep, fd-find, jq, and git as root
- Installs Pi globally with `bun install -g`
- Makes root's bun global directory accessible to all users
- Patches Pi's shebang from `node` to `bun` so it runs natively without Node.js
- Verifies the install by running `pi --version`
- Drops back to the `user` account and creates the Pi working directory

```typescript
import { Template, defaultBuildLogger } from 'e2b'

const template = Template()
  .fromBunImage('latest')
  .setUser('root')
  .runCmd('apt-get update && apt-get install -y git ripgrep fd-find jq && rm -rf /var/lib/apt/lists/*')
  .runCmd('bun install -g @mariozechner/pi-coding-agent@latest')
  .runCmd('chmod a+rx /root && chmod -R a+rX /root/.bun')
  .runCmd('sed -i "1s|#!/usr/bin/env node|#!/usr/bin/env bun|" /root/.bun/install/global/node_modules/@mariozechner/pi-coding-agent/dist/cli.js')
  .runCmd('pi --version')
  .setUser('user')
  .runCmd('mkdir -p /home/user/.pi/agent')

await Template.build(template, 'your-template-name', {
  apiKey: process.env.E2B_API_KEY!,
  cpuCount: 2,
  memoryMB: 4096,
  onBuildLogs: defaultBuildLogger(),
})
```

Computer builds the template by running `bun run scripts/build-template.ts`. Replace `your-template-name` with a name that identifies your project's sandbox image.

For more on the E2B Build System 2.0, see [e2b.dev/blog/introducing-build-system-2-0](https://e2b.dev/blog/introducing-build-system-2-0) and the [template quickstart](https://e2b.dev/docs/template/quickstart).

---

## Communicating with Pi via E2B CLI

Computer communicates with Pi by running E2B CLI commands in its own sandbox. The recommended pattern is print mode: one prompt per invocation, no persistent processes, no stdin management. Same pattern Codex, Claude Code, and OpenCode all use in E2B.

**Example conversation:**

```
You: "Set up the project with a REST API using Hono and Effect"

Computer runs in its sandbox:
$ e2b sandbox create pi-bun-sandbox --detach
→ Returns sandbox ID abc123

$ e2b sandbox exec abc123 \
  "git clone https://x-access-token:<PAT>@github.com/your-org/your-repo.git /home/user/project"

$ e2b sandbox exec -c /home/user/project abc123 \
  "pi -p --provider openai-codex --model gpt-5.4 \
  'Bootstrap a REST API using Hono as the HTTP framework and Effect for typed errors. Follow the execution protocol in AGENTS.md.'"

Pi executes: reads AGENTS.md, enters Phase 0, sets up project structure,
installs dependencies, creates validation suite, runs tests

Computer reports back:
"Pi bootstrapped the project. Here is what it set up:
 - Hono HTTP server with Effect error handling
 - TypeScript strict mode with Biome for formatting/linting
 - Test suite using Bun's test runner
 - All Phase 0 gates passing (format, lint, type-check, test)"
```

**The full CLI workflow:**

```bash
# bootstrap.sh does all of this in one step:
# 1. Create sandbox from template (instant from snapshot)
# 2. Inject Pi auth.json (Codex OAuth credentials)
# 3. Configure git credentials (App installation token)
# 4. Configure git identity (Pi's commit attribution)
# 5. Clone your repo into /home/user/project
# 6. Install project dependencies (bun install)
bash scripts/bootstrap.sh your-template-name https://github.com/your-org/your-repo

# Verify 9/9 checks pass (infra + Pi diagnostic)
bash scripts/verify.sh

# Run Pi in print mode: one prompt per invocation
bash scripts/run-pi.sh "State your active phase. List all architecture layers."

# Session continuity with --continue
bash scripts/run-pi.sh --continue "Now bootstrap the automation foundation."

# Extract just the status block from Pi's response
bash scripts/run-pi.sh --status-only --continue "Report your current status."
```

All of these commands run in Computer's sandbox, not on your local machine. You see the results in your Space thread.

**Manual workflow (if not using the convenience scripts):**

```bash
# Create sandbox
e2b sandbox create your-template-name --detach
# → Returns sandbox ID

# Clone your repo
e2b sandbox exec <sandbox-id> "git clone https://x-access-token:<TOKEN>@github.com/your-org/your-repo.git /home/user/project"

# CRITICAL: Install dev dependencies before sending Pi any prompts.
# Pi's AGENTS.md contract requires all automation gates to pass.
# Without biome/typescript, Pi will refuse to create or modify files.
e2b sandbox exec -c /home/user/project <sandbox-id> "bun install"

# Copy auth credentials
e2b sandbox exec <sandbox-id> "mkdir -p /home/user/.pi/agent && cat > /home/user/.pi/agent/auth.json << 'EOF'
<your-auth-json>
EOF"

# Run Pi in print mode
e2b sandbox exec -c /home/user/project <sandbox-id> \
  "pi -p --provider openai-codex --model gpt-5.4 'State your active phase.'"
```

**Why print mode:** single-shot print mode (`pi -p`) is simple and composable. No persistent process to manage, no event loop, no stdin pipe to keep open. Computer sends one prompt, gets one execution, and the process exits cleanly. Use `--continue` to resume the most recent session. Use `--resume <session-id>` for a specific earlier session.

See [e2b.dev/docs/cli/exec-command](https://e2b.dev/docs/cli/exec-command) for full CLI documentation and [e2b.dev/docs/agents/codex](https://e2b.dev/docs/agents/codex) for the Codex agent pattern this workflow follows.

---

## Scripts

All scripts live in `scripts/` and exist so Computer can run them. Computer clones this scaffold into its sandbox, then executes these scripts as part of the setup and development workflow. You do not need to know the CLI flags. Computer handles that.

Scripts read secrets from environment variables. No credentials are stored in the repository.

**Required environment variables (Computer sets these in its sandbox):**

| Variable | Description |
|---|---|
| `E2B_API_KEY` | Your E2B API key (starts with `e2b_`) |
| `APP_INSTALLATION_TOKEN` | GitHub App installation token: short-lived (~1hr), generated by your Pi Codebase Operator GitHub App via `scripts/generate-app-token.py` |
| `PI_AUTH_JSON` | Contents of `~/.pi/agent/auth.json` (Codex OAuth credentials) |

**Optional environment variables:**

| Variable | Default | Description |
|---|---|---|
| `PI_PROVIDER` | `openai-codex` | Model provider for Pi |
| `PI_MODEL` | `gpt-5.4` | Model name for Pi |
| `PI_GIT_NAME` | `pi-codebase-operator[bot]` | Git author name for Pi's commits |
| `PI_GIT_EMAIL` | `noreply@users.noreply.github.com` | Git author email for Pi's commits |
| `PROJECT_DIR` | `/home/user/project` | Pi's working directory inside the sandbox |

### `scripts/build-template.ts`

Builds the custom E2B sandbox template with Pi and Bun pre-installed. Computer runs this once during setup. Subsequent sandboxes start instantly from the snapshot.

### `scripts/bootstrap.sh`

Full sandbox lifecycle in one script: creates sandbox from template, injects Pi auth credentials, configures git identity, clones the repo, and installs project dependencies (`bun install`). The dependency install step is critical: Pi's AGENTS.md contract requires all automation gates (format, lint, typecheck, test) to pass before any code changes, and without installed dev dependencies (biome, typescript), Pi will refuse to operate. Saves sandbox ID to `.sandbox-id`.

Usage: `bash scripts/bootstrap.sh <template-name-or-id> <github-repo-url>`

### `scripts/verify.sh`

9-check verification in two parts. First, infrastructure checks: sandbox alive, bun installed, Pi installed, project directory exists, SYSTEM.md exists, AGENTS.md exists, git credentials configured, Pi auth configured. Second, Pi diagnostic: sends Pi a prompt to confirm it loaded `.pi/SYSTEM.md` and `AGENTS.md`. Computer does NOT inspect the config files. It asks Pi to confirm via stdout. Set `SKIP_PI_DIAGNOSTIC=1` to skip the Pi prompt (useful for fast infra-only checks).

### `scripts/run-pi.sh`

Prompt delivery script for Pi in print mode. Flags:

| Flag | Description |
|---|---|
| `--continue` / `-c` | Resume the most recent Pi session |
| `--json` / `-j` | Run Pi in JSON mode (`--mode json`) |
| `--status-only` / `-s` | Capture Pi's output, extract and validate the `json:status` block, print only the status JSON |

Sets Pi's cwd to the project root (critical for config file discovery, [Pi source, resource-loader.ts line 843](https://github.com/badlogic/pi-mono)).

**Important**: `--continue` maintains session state across invocations. Pi remembers what files it created and what gates it ran. Use it for multi-turn workflows where Pi needs context from the previous turn.

### `scripts/generate-app-token.py`

Converts a GitHub App private key + App ID + Installation ID into a short-lived (~1hr) installation token. Computer runs this before each bootstrap to get a fresh `APP_INSTALLATION_TOKEN` for Pi's git operations.

Usage: `python3 scripts/generate-app-token.py <private-key.pem> <app-id> <installation-id>`

### `scripts/check-changed.sh`

Runs format and lint checks only on changed files (git diff), then runs full typecheck and full test suite. Used by Pi during development to avoid reformatting the entire repo on each change.

### Shared libraries (`scripts/lib/`)

All bridge scripts are built on shared libraries that isolate E2B and Pi concerns:

| Library | Key functions | Purpose |
|---|---|---|
| `e2b-parse.sh` | `parse_sandbox_id`, `strip_ansi` | Parse sandbox IDs from CLI output, strip ANSI escape codes |
| `e2b-exec.sh` | `exec_and_capture`, `exec_with_timeout` | Execute commands in sandbox with proper stdout/stderr routing |
| `e2b-lifecycle.sh` | `is_sandbox_alive`, `kill_sandbox`, `list_sandboxes` | Sandbox lifecycle management |
| `pi-invoke.sh` | `build_pi_command` | Build Pi CLI invocation strings with proper quoting |
| `pi-parse.sh` | `extract_status_block`, `validate_status_block` | Extract and validate `json:status` blocks from Pi output |
| `pi-json-parse.ts` | Bun script | Parse JSONL stream from Pi's JSON mode into structured envelope |

---

## Operational knowledge (from end-to-end validation)

Behaviors discovered during live end-to-end testing that any Computer needs to know when operating this scaffold.

### Pi respects its contract before anything else

Pi reads `AGENTS.md` on every invocation and enforces its automation foundation requirement. If the project's dev dependencies are not installed (biome, typescript), Pi will refuse to create or modify files because the gates (format, lint, typecheck) cannot pass. This is correct behavior, not a bug. The fix: `bootstrap.sh` runs `bun install` after cloning. If you are bootstrapping manually, always run `bun install` in the project directory before sending Pi any coding prompts.

### Print mode executes tools

Pi in print mode (`pi -p`) is not just a text responder. It has full access to its 4 tools (read, write, edit, bash) and will execute them. When Pi receives a coding prompt in print mode, it reads the codebase, creates files, runs tests, and reports results, all within a single invocation. The text output you see is Pi's summary of what it did, not the only thing it did.

### Session continuity with --continue

`--continue` resumes the most recent Pi session inside the sandbox. Pi remembers:
- Files it created or modified in previous turns
- Gates it ran and their results
- The current TDD phase it was in

Use `--continue` for multi-turn workflows. Without it, each `pi -p` invocation starts a fresh session with no memory of prior turns.

### Status block pipeline

Pi emits a `json:status` block at the end of its response when instructed (see AGENTS.md). Pipeline for parsing it:

1. `run-pi.sh --status-only` sends Pi a prompt and captures the full output
2. `extract_status_block` (from `pi-parse.sh`) finds the last `` ```json:status `` fenced block
3. `validate_status_block` confirms all 7 required fields are present and correctly typed
4. Only the validated JSON is printed to stdout

The status block contains: `phase`, `gates_passing`, `gates_failing`, `files_changed`, `git_commit`, `git_pushed`, `next_step`.

### Prompt delivery: the canonical pattern

The most reliable way to send Pi a prompt through E2B:

```bash
source scripts/lib/pi-invoke.sh
source scripts/lib/e2b-exec.sh

PI_CMD=$(build_pi_command "Your prompt here")
exec_and_capture "$SANDBOX_ID" "$PI_CMD" "/home/user/project"
```

`build_pi_command` handles single-quote escaping, provider/model flags, and mode flags. `exec_and_capture` routes stdout and stderr to the correct streams. This two-function pattern is what all the bridge scripts use internally.

`run-pi.sh` is a convenience wrapper around this pattern. For simple prompts it works well. For prompts containing special characters, dollar signs, or nested quotes, use the library functions directly.

### Sandbox lifecycle

Sandboxes are ephemeral. E2B's default timeout is 300 seconds (5 minutes), but `--detach` mode keeps the sandbox alive until explicitly killed or until the E2B-imposed maximum (typically 1 hour for Hobby tier). Always call `kill_sandbox` when done. Idle sandboxes consume credits.

Typical lifecycle:
1. `bootstrap.sh`: creates sandbox, clones repo, installs deps, saves ID to `.sandbox-id`
2. `verify.sh`: confirms 9/9 checks pass
3. `run-pi.sh`: one or more prompts (use `--continue` for multi-turn)
4. `kill_sandbox`: cleanup

---

## Citations

Every factual claim in this README is sourced from first-party documentation. No third-party blogs, press, or commentary.

### Perplexity

| Claim | Source |
|---|---|
| 19+ models orchestrated by Computer | [The AI is the Computer](https://www.perplexity.ai/hub/blog/the-ai-is-the-computer): "Nineteen models are available in the backend" |
| 20 frontier models (orchestration harness) | [Everything is Computer](https://www.perplexity.ai/hub/blog/everything-is-computer): "an orchestration harness of 20 frontier models" |
| Computer runs in a secure cloud sandbox with file system, shell, browser | [The AI is the Computer](https://www.perplexity.ai/hub/blog/the-ai-is-the-computer): "access to a file system, a shell to execute code securely, and a browser" |
| Each Computer task gets isolated compute container with dedicated filesystem and browser instance | [Computer for Enterprise](https://www.perplexity.ai/help-center/en/articles/13901210-computer-for-enterprise): "Each task session runs in its own isolated compute container" |
| Cloud browser activity fully sandboxed, no cross-session data leakage | [Computer for Enterprise](https://www.perplexity.ai/help-center/en/articles/13901210-computer-for-enterprise): "no risk of that activity accessing, modifying, or exposing resources outside of the sandbox" |
| Spaces are persistent context containers with custom instructions, files, links, connectors | [Perplexity Help Center: What are Spaces?](https://www.perplexity.ai/help-center/en/articles/10352961-what-are-spaces) |
| Computer: independent digital worker with tool execution, authenticated integrations, secure sandbox | [Perplexity Help Center: What is Computer?](https://www.perplexity.ai/help-center/en/articles/13837784-what-is-computer) |
| Comet is Chromium-based browser with AI capabilities | [Perplexity Help Center: Getting Started with Comet](https://www.perplexity.ai/help-center/en/articles/11172798-getting-started-with-comet) |
| Comet three principles: transparency, user control, sound judgment | [Comet Assistant puts you in control](https://www.perplexity.ai/hub/blog/comet-assistant-puts-you-in-control) |
| Comet pauses at high-stakes actions (login, purchase) | [Comet Assistant puts you in control](https://www.perplexity.ai/hub/blog/comet-assistant-puts-you-in-control): "it will pause and ask for permission before proceeding" |
| Comet Enterprise: admin controls, MDM deployment, domain permissions | [Everything is Computer](https://www.perplexity.ai/hub/blog/everything-is-computer): "Admins can decide where and how the assistant operates" |
| Perplexity Pro: $20/mo | [perplexity.ai/pro](https://www.perplexity.ai/pro) |
| Perplexity Max: $200/mo, 10,000 monthly credits | [How Credits Work](https://www.perplexity.ai/help-center/en/articles/13838041-how-credits-work-on-perplexity) |
| Connector integrations (GitHub, Linear, Notion, Google Drive) | [GitHub Connector](https://www.perplexity.ai/help-center/en/articles/12275669-github-connector-for-enterprise), [Linear Connector](https://www.perplexity.ai/help-center/en/articles/12167711-linear-connector-for-enterprise), [Notion Connector](https://www.perplexity.ai/help-center/en/articles/12167654-connecting-perplexity-with-notion) |
| Space Tasks: scheduled operations running in Space context, configurable schedule (once/daily/weekly/weekday/monthly/yearly), notifications via email/push | [Perplexity Help Center: Tasks](https://www.perplexity.ai/help-center/en/articles/11521526-perplexity-tasks) |
| Computer Skills: reusable instruction sets (.md or .zip with SKILL.md + YAML frontmatter); built-in: Research, Research Report, Slides, Chart, Finance, Legal, Sales, Marketing, CX, Accounting, PM | [Perplexity Help Center: How to use Computer Skills](https://www.perplexity.ai/help-center/en/articles/13914413-how-to-use-computer-skills) |
| Bring Your Own Connector via MCP (remote URL, OAuth/API key/open auth) | [Perplexity Changelog: March 13, 2026](https://www.perplexity.ai/changelog/what-we-shipped---march-13-2026) |
| Premium Sources: CB Insights, PitchBook, Statista | [Perplexity Help Center: What is Computer?](https://www.perplexity.ai/help-center/en/articles/13837784-what-is-computer) |
| Finance tools: 40+ tools including SEC/FactSet/S&P Global/Coinbase/Quartr, Plaid brokerage, Polymarket | [Perplexity Help Center: What is Computer?](https://www.perplexity.ai/help-center/en/articles/13837784-what-is-computer) |

### Billion Dollar Build

| Claim | Source |
|---|---|
| Competition page and registration | [The Billion Dollar Build](https://www.perplexity.ai/computer/a/the-billion-dollar-build-ZWzIFW.FTaKdLtufMa0yhw) |
| Terms and conditions | [BDB Terms & Conditions](https://www.perplexity.ai/computer/a/bdb-terms-conditions-DvGwJTrKQumizUjQ1xoxZA) |
| Registration opens April 14, 2026 | BDB competition page, timeline section |
| Submission deadline June 2, 2026 | BDB competition page, timeline section |
| Up to $1M seed investment from Perplexity Fund, split among up to 3 winners | BDB competition page, prizes section |
| Up to $1M in Perplexity Computer credits | BDB competition page, prizes section |
| Investment not guaranteed, at Fund's sole discretion | BDB competition page FAQ |
| 5 judging criteria: massive market, computer is the engine, real traction, wild economics, founder-market fit | BDB competition page, "What We're Looking For" section |

### Pi

| Claim | Source |
|---|---|
| 4 tools: read, write, edit, bash | [What I learned building an opinionated and minimal coding agent](https://mariozechner.at/posts/2025-11-30-pi-coding-agent/): "four tools: read, write, edit, bash" |
| No MCP, no sub-agents, no plan mode | [What I learned building an opinionated and minimal coding agent](https://mariozechner.at/posts/2025-11-30-pi-coding-agent/) |
| Shortest system prompt of any coding agent | [Pi: The Minimal Agent](https://lucumr.pocoo.org/2026/1/31/pi/) by Armin Ronacher |
| Tree sessions, self-extending through code | [What I learned building an opinionated and minimal coding agent](https://mariozechner.at/posts/2025-11-30-pi-coding-agent/) |
| Pi install: `bun install -g @mariozechner/pi-coding-agent` | [npm: @mariozechner/pi-coding-agent](https://www.npmjs.com/package/@mariozechner/pi-coding-agent) |
| Pi reads .pi/SYSTEM.md and AGENTS.md | [Pi coding agent site](https://pi.dev) |
| Pi core is MIT licensed | [I've sold out](https://mariozechner.at/posts/2026-04-08-ive-sold-out/) by Mario Zechner |
| Pi print mode (`pi -p`): single-shot execution | [Pi RPC docs](https://github.com/badlogic/pi-mono/blob/main/packages/coding-agent/docs/rpc.md) |
| Default tools: `["read", "bash", "edit", "write"]` | [Pi source, sdk.ts line 245](https://github.com/badlogic/pi-mono) |
| Custom SYSTEM.md replaces entire default prompt | [Pi source, system-prompt.ts lines 49-76](https://github.com/badlogic/pi-mono) |
| AGENTS.md discovered via ancestor directory walk | [Pi source, resource-loader.ts lines 76-99](https://github.com/badlogic/pi-mono) |
| Print mode text output: only text content blocks from final assistant message | [Pi source, print-mode.ts lines 147-151](https://github.com/badlogic/pi-mono) |

### E2B

| Claim | Source |
|---|---|
| Firecracker MicroVM isolation, 125ms cold start | [Firecracker vs QEMU](https://e2b.dev/blog/firecracker-vs-qemu) |
| $100 free credits on Hobby tier | [E2B Pricing](https://e2b.dev/pricing) |
| Build System 2.0: snapshot-based templates, instant starts | [Introducing Build System 2.0](https://e2b.dev/blog/introducing-build-system-2-0) |
| `e2b sandbox exec` CLI command | [E2B CLI exec command](https://e2b.dev/docs/cli/exec-command) |
| Codex agent pattern in E2B (print mode, single-shot) | [E2B Codex Agent](https://e2b.dev/docs/agents/codex) |
| Domain-based network filtering: `denyOut`, `allowOut`, wildcard support | [E2B docs: Internet access](https://e2b.dev/docs/sandbox/internet-access) |
| Allow rules take precedence over deny rules | [E2B docs: Internet access](https://e2b.dev/docs/sandbox/internet-access) |
| DNS 8.8.8.8 auto-allowed with domain filtering | [E2B docs: Internet access](https://e2b.dev/docs/sandbox/internet-access) |
| CLI `create` does not expose network flags | [E2B source, create.ts](https://github.com/e2b-dev/E2B) |
| stdout/stderr streamed real-time via callbacks | [E2B source, exec.ts lines 112-127](https://github.com/e2b-dev/E2B) |
| Exit code forwarded from handle.wait().exitCode | [E2B source, exec.ts lines 141-143](https://github.com/e2b-dev/E2B) |
| Single command string passed through without re-quoting | [E2B source, exec_helpers.ts lines 16-18](https://github.com/e2b-dev/E2B) |
| Default sandbox timeout: 300s | [E2B source, connectionConfig.ts line 5](https://github.com/e2b-dev/E2B) |
| SDK defaults allowInternetAccess to true | [E2B source, sandboxApi.ts line 787](https://github.com/e2b-dev/E2B) |

### GitHub

| Claim | Source |
|---|---|
| Fine-grained PATs scope permissions to specific repositories | [GitHub Docs: Managing your personal access tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) |
| `contents: read` allows clone/pull but NOT push | [GitHub Docs: Fine-grained PATs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) |
| Repository rulesets: "Restrict updates", only bypass actors can push | [GitHub Docs: Available rules for rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets) |
| Rulesets: bypass actors can be roles, teams, or GitHub Apps | [GitHub Docs: Creating rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/creating-rulesets-for-a-repository) |
| Deploy keys are read-only by default | [GitHub Blog: Read-only deploy keys](https://github.blog/news-insights/product-news/read-only-deploy-keys/) |

### Bun

| Claim | Source |
|---|---|
| Bun install: `curl -fsSL https://bun.sh/install \| bash` | [bun.sh](https://bun.sh) |
| `fromBunImage('latest')` uses oven/bun base image | [E2B Template Quickstart](https://e2b.dev/docs/template/quickstart) |

### This scaffold

| Claim | Source |
|---|---|
| Pi project template this scaffold extends | [pi-config](https://github.com/srinitude/pi-config) |
| Pi mono repo (upstream) | [pi-mono](https://github.com/badlogic/pi-mono) by [@badlogicgames](https://github.com/badlogic) |
| This scaffold (template) | [billion-dollar-build](https://github.com/fantasymetals/billion-dollar-build) |

---

## License

Apache 2.0
