# Addy Repo Instructions

## Critical: Follow Tool Instructions

When a tool response contains ACTION REQUIRED or explicit multi-step instructions, you MUST complete every step before responding to the user. Do not summarize, do not skip steps, do not exercise judgment about which steps matter. Follow them mechanically in order. Only respond to the user after all required steps are done.

## Addy Runtime

When an `<addy-runtime-identity>` block is present, it is the authoritative Addy runtime identity for this session.
When no runtime identity block is visible, `ADDY_RUNTIME=1` in the process environment means you are inside Addy.
When neither marker is present, you are in a detached session — only use Addy tools when explicitly asked.

Environment variables: `ADDY_PANE_ID` (your pane), `ADDY_SESSION_MODE` (terminal/chat/subagent), `ADDY_PARENT_PANE_ID` (if sub-agent).

## Do Not Modify These Files

`AGENTS.md` and `CLAUDE.md` are managed by Addy and will be overwritten automatically. Do not edit them. To store project-specific knowledge, conventions, or rules, use `addy_remember`. To retrieve them, use `addy_recall`.

## Tool Routing

**Intent matching:** When a user asks you to do something, match their verb to an Addy MCP tool BEFORE interpreting it generically. If a matching tool exists, use it immediately — do not ask what the user means, do not offer alternatives, do not reinterpret the verb. For example: "review this plan" → `addy_request_plan_review`, "review this code" → `addy_request_code_review`, "run tests" → `addy_run_tests`. The tool routing table below covers common mappings, but also scan the deferred tool list for any `addy_*` tool that matches the user's intent.

When running inside Addy, you MUST use Addy MCP tools instead of built-in equivalents. Do not work around them.

| Instead of... | Use... |
|---|---|
| EnterPlanMode | `addy_create_plan` |
| Agent / Task tool | `addy_spawn_agents` |
| Bash to start/stop servers | `addy_start_server` / `addy_stop_server` |
| Bash to run build/compile commands | `addy_run_build` |
| Bash to open URLs | `addy_open_url` |
| Built-in browser / WebFetch for local dev | `addy_view_browser`, `addy_browser_navigate`, `addy_browser_click`, `addy_browser_type`, `addy_browser_scroll`, `addy_browser_select`, `addy_browser_eval` |
| Built-in memory / MEMORY.md / ~/.claude/ files | `addy_remember` / `addy_recall` |
| Writing to AGENTS.md or CLAUDE.md | `addy_remember` (for project knowledge) |
| Reviewing a plan | `addy_request_plan_review` |
| Reviewing code | `addy_request_code_review` |
| Running tests via Bash | `addy_run_tests` |
| Checking browser console errors | `addy_get_console_errors` |

The **one exception**: Agent with `subagent_type: "Explore"` is allowed for quick codebase searches.

## Plans

**NEVER use EnterPlanMode.** NEVER use internal plan mode. This is a hard requirement with ZERO exceptions. EnterPlanMode creates ephemeral plans that disappear. `addy_create_plan` persists plans in Addy's UI where the user and other agents can see, track, and update them.

Do not create a plan unless the user explicitly asks for a plan, chooses a plan-specific UI action, or tells you to continue an existing plan.

Starting normal feature work does NOT, by itself, authorize creating a new plan.
Creating, reviewing, or refining a plan does NOT authorize implementation.
Before working on an explicitly requested plan, ALWAYS call `addy_list_plans` first to check for existing plans.
**Do not write code for a plan until the user explicitly says to build/implement it, or triggers a Build/Start action in Addy UI.** Only then call `addy_start_plan_implementation`. This is the Addy-owned transition into implementation: it captures the git baseline, links the plan to the working pane, and marks the plan `inProgress` for code review diffs.
When you complete a plan step, use `addy_update_plan` to mark it done. When modifying a plan's description, ALWAYS update steps in the same call to keep them in sync.
Use `addy_get_plan` to read full plan details before working on a plan.

## Sub-Agent Spawning

**NEVER use the Task tool or Agent tool** (except Agent with subagent_type "Explore"). Every single sub-agent, research task, parallel job, or delegated work MUST use `addy_spawn_agents` instead. This is a hard requirement with ZERO exceptions.

`addy_spawn_agents` takes an `agents` array — each entry has `task`, `name`, and optional `model`. It spawns all agents in parallel and **blocks until every agent reports back**. The call returns all results together.

Always provide a `name` for each agent in the format: **"Model - Short task description"**

### Agent Type Mapping

When you would normally use a built-in Agent subtype, use `addy_spawn_agents` with a specialized task prompt instead:

| Instead of Agent subtype | Use addy_spawn_agents with this task focus |
|--------------------------|-------------------------------------------|
| `general-purpose` | General research: search code, read files, answer multi-step questions |
| `feature-dev:code-reviewer` | Review code for bugs, logic errors, security vulnerabilities, and code quality |
| `feature-dev:code-explorer` | Trace execution paths, map architecture layers, document dependencies |
| `feature-dev:code-architect` | Design feature architecture: files to create/modify, component designs, data flows |
| `pr-review-toolkit:code-simplifier` | Simplify recently modified code for clarity and maintainability |
| `pr-review-toolkit:silent-failure-hunter` | Find silent failures, inadequate error handling, and inappropriate fallbacks |
| `pr-review-toolkit:pr-test-analyzer` | Review test coverage for completeness, edge cases, and quality |
| `pr-review-toolkit:code-reviewer` | Review code for adherence to project guidelines and style conventions |

### Sub-Agent Lifecycle

Sub-agents do NOT close themselves when they finish a task. The flow is:
1. Parent calls `addy_spawn_agents` with one or more agent directives (blocks).
2. Each child does its work and calls `addy_report_agent_result` with a summary.
3. When ALL children have reported, the parent's blocked call returns with all results.
4. Parent reviews each result and calls `addy_accept_agent_result` to close each pane.
5. For work that needs revision, parent calls `addy_spawn_agents` again with updated directives.

Do not treat process exit, idle, or a plain notify message as completion.

## Other Addy Tools

- **Servers / long-running processes** → `addy_start_server` (NOT Bash)
- **Build / compile commands** → `addy_run_build`
- **Stop a server** → `addy_stop_server`
- **Additional terminal panes** → `addy_split_pane`
- **List open panes** → `addy_list_panes`

NEVER run a long-running process directly via the Bash tool. Always use `addy_start_server` so it gets its own pane and doesn't block your terminal. Use `addy_run_build` for build or compile commands that should appear in a build pane; finite test builds block until completion, while persistent build/watch processes must use its persistent mode.

## Memory

Use Addy's memory system exclusively. Do not write to MEMORY.md, ~/.claude/ memory files, or any other file-based memory.

- **Save** → `addy_remember`
- **Search** → `addy_recall`
- **Before starting work** → `addy_recall` with type `currentWork`
- **Architecture** → `addy_get_architecture` (on demand)
- **Philosophy** → `addy_consult_why` (on demand)
- **Directives** → `addy_get_directives` (on demand)

## Orientation

When starting a session or unfamiliar with the project:

| What you need | How to get it |
|---|---|
| Codebase structure & file map | `addy_get_architecture` |
| Project philosophy & principles | `addy_consult_why` |
| Knowledge system taxonomy | `.addy/memory.md` |
| Active directives | `addy_get_directives` |
| Existing plans | `addy_list_plans` |
| In-progress work | `addy_recall` with type `currentWork` |
| Guides, gotchas, conventions | `addy_recall` with relevant query |
| Review standards | `addy_get_standards` |

## Project Context

Project context is auto-injected at session start — no action needed to receive it.
Use `addy_update_context` to contribute discoveries back to shared project knowledge:
- `section`: one of overview, architecture, conventions, active_work, decisions, gotchas (or custom)
- `mode`: "replace" (default) or "append"
Keep sections concise — other agents will read this.

## Project Why (Philosophy)

Use `addy_consult_why` before making non-trivial decisions to align with the project's vision.
Use `addy_build_why` to build or refine the project's philosophy document.
The "why" is auto-injected at session start — it's the most important framing for decisions.

## Console Errors

When you have a browser pane open, console errors and warnings are automatically tracked.
Browser console errors are automatically surfaced to you after editing browser-relevant files (.tsx, .ts, .jsx, .js, .css, .html, etc.) — you'll see them inline after your Edit/Write calls.
When you see these errors, fix them immediately before continuing.
You can also call `addy_get_console_errors` manually at any time to check for errors.
On backends without edit hooks, you MUST call `addy_get_console_errors` yourself after browser-relevant edits before moving on.
If unacknowledged errors exist when you try to finish, you'll be blocked until you read and address them.

## Stop Behavior

Stop/continue decisions are Addy-owned, not model-owned.
Do NOT call a generic finish-gate tool at the end of normal work.
Tools and watchers should carry their own loops to completion and route follow-up back to the owner pane.
Sub-agents should report to their parent with `addy_report_agent_result`, and parents should explicitly accept or revise those results.

Other CLI commands (for hooks, not direct use):
- `addy status --active --detail "..."` — report activity
- `addy status --idle` — report idle

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.