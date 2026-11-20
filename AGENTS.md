# AGENTS.md — global skill router

This file is installed as the user-level instruction file for every agent on this
machine (`~/.pi/agent/AGENTS.md`, `~/.codex/AGENTS.md`, `~/.claude/CLAUDE.md`).
It routes intent to skills that live in `~/.agents/skills/`.

If a task matches a skill, **load the skill before doing the work**. The skill
holds the procedure, the exit criteria, and the anti-patterns. This file only
decides *which* one.

---

## Hard rules

1. **Check for a skill first.** Before planning, editing, or answering a
   non-trivial question, scan the routing table below. If any row plausibly
   applies, read `~/.agents/skills/<name>/SKILL.md` and follow it.
2. **Follow the skill fully.** Partial application is worse than none: it
   produces the artifacts of the workflow without the discipline that makes
   them worth having.
3. **Never skip the front of the lifecycle.** If a task is a feature or a
   significant change, `spec-driven-development` runs before code. If a task
   touches more than one file, `planning-and-task-breakdown` runs before code.
4. **The agent that writes the code is not the sole judge of it.** Verification
   comes from `test-driven-development` (red first) and, before merge,
   `code-review-and-quality`.
5. **State the skill you loaded.** One line — `Using: test-driven-development`
   — so the human can audit the routing rather than guess at it.
6. **A skill can be overridden by the human.** If they say "skip the spec", skip
   it and say what you skipped. Silence is not consent.

### Thoughts that are wrong

- "This is too small for a skill." → Small tasks are where the rules get
  skipped and defects get in. Load it anyway; most skills have a short path for
  small work.
- "I already know how to do this." → The skill is not a tutorial, it is a
  checklist and a definition of done. Knowing the steps is not the same as
  performing them.
- "I'll gather context first, then decide." → Deciding is cheap; loading the
  skill is what tells you *which* context matters.
- "The tests pass, so it's done." → Passing tests you wrote to match your
  implementation is the cheapest form of done.

---

## Routing table

| Situation | Load |
|---|---|
| Vague idea, needs shaping before it becomes a plan | `idea-refine` |
| Requirements unclear, need to extract what the human actually wants | `interview-me` |
| Starting a project, feature, or significant change with no spec | `spec-driven-development` |
| Spec exists, need ordered implementable tasks | `planning-and-task-breakdown` |
| Setting or enforcing a quality bar, stopping an agent from lowering it | `constraint-driven-development` |
| Writing any logic, fixing a bug, changing behavior | `test-driven-development` |
| Implementing a multi-file change in safe slices | `incremental-implementation` |
| Tests fail, build breaks, behavior does not match expectation | `debugging-and-error-recovery` |
| Before merging anything, reviewing your own or another agent's diff | `code-review-and-quality` |
| Code works but is harder to read, maintain, or extend than it should be | `code-simplification` |
| Designing an API, module boundary, or public interface | `api-and-interface-design` |
| Building or changing a user-facing interface | `frontend-ui-engineering` |
| Auditing an interface for WCAG 2.2 AA conformance | `accessibility-engineering` |
| Setting up CI/CD, quality gates, or deployment pipelines | `ci-cd-and-automation` |
| Committing, branching, splitting a messy tree, opening a PR | `git-workflow-and-versioning` |
| Removing a system, migrating users, expand/contract a schema | `deprecation-and-migration` |
| Recording an architecture decision or writing docs | `documentation-and-adrs` |
| Shipping any feature that runs in production | `observability-and-instrumentation` |
| Preparing a production launch, rollout, or rollback plan | `shipping-and-launch` |
| Performance requirements exist, or a regression is suspected | `performance-optimization` |
| Handling untrusted input, auth, sessions, secrets, dependencies | `security-and-hardening` |
| Testing in a real browser, inspecting DOM/console/network | `browser-testing-with-devtools` |
| Verifying an approach against official documentation | `source-driven-development` |
| Agent output quality is degrading, or context needs restructuring | `context-engineering` |
| A high-stakes decision that deserves adversarial review | `doubt-driven-development` |
| Unsure which skill applies, or starting a session | `using-agent-skills` |

---

## Lifecycle

When a request spans a whole piece of work, walk it in this order. Do not
compress it into one step.

- **DEFINE** → `spec-driven-development` (or `idea-refine` / `interview-me` if
  the input is still vague)
- **PLAN** → `planning-and-task-breakdown`
- **BUILD** → `incremental-implementation` + `test-driven-development`
- **VERIFY** → `debugging-and-error-recovery`
- **REVIEW** → `code-review-and-quality`
- **SHIP** → `shipping-and-launch` + `observability-and-instrumentation`

Each stage produces an artifact (`SPEC.md`, a task plan, tests, an evidence
bundle, a review report). The artifact is the exit criterion. A stage without
its artifact did not happen.

---

## Personas

`~/.agents/agents/` holds five specialist personas: `code-reviewer`,
`security-auditor`, `test-engineer`, `web-performance-auditor`,
`accessibility-auditor`. A persona is *who* is looking; a skill is *how* they
work.

**The human is the orchestrator.** A persona may load a skill. A persona must
not invoke another persona. The one endorsed multi-persona pattern is parallel
fan-out with a merge step (the `/ship` workflow: reviewer + security + tests,
then one synthesized go/no-go).

---

## Where things live

```text
~/.agents/skills/<name>/SKILL.md   # the workflows (this repo installs these)
~/.agents/references/*.md          # shared checklists the skills cite
~/.agents/agents/*.md              # personas
~/.agents/commands/*.toml          # slash-command definitions (Gemini/Antigravity)
```

Skills are discovered by reading `SKILL.md` frontmatter. Paths inside a skill are
relative to that skill's directory, except `../../references/`, which resolves
to `~/.agents/references/`.

**Per-harness invocation**

- Pi: `/skill:<name>`
- Codex: `$<name>`
- Claude Code: `/skill:<name>` (skills are installed to `~/.claude/skills/` too)
- Hermes: `hermes skills list` (needs `skills.external_dirs: ["~/.agents/skills"]` in `~/.hermes/config.yaml`)

---

## Editing this file

This file is versioned in `agent-skills-personal`. Edit the repo copy and run
`./install.sh` — do not edit the installed copies in `~/.pi`, `~/.codex`, or
`~/.claude`, because the next install will overwrite them.

Personal overrides belong in the **Local overrides** section at the bottom, so
they survive edits to the routing table.

---

## Local overrides

<!-- Add machine-specific or personal rules here. Keep them additive: a local
     override should never delete a hard rule above, only narrow or extend it. -->

- None yet.
