# Gauntlet

**An SDLC toolkit for AI coding agents.** Spec → plan → build → verify → review →
ship, with a quality bar that does not quietly lower itself.

Most agent "skill" collections are prompt libraries: a pile of advice the model
may or may not follow. Gauntlet is structured as a lifecycle with exit criteria —
each stage produces an artifact, and a stage without its artifact did not happen.

```text
DEFINE    spec-driven-development
PLAN      planning-and-task-breakdown
BUILD     incremental-implementation + test-driven-development
VERIFY    debugging-and-error-recovery
REVIEW    code-review-and-quality  (fan-out: reviewer, security, tests)
SHIP      shipping-and-launch + observability-and-instrumentation
```

26 skills · 5 personas · 10 command definitions · 1 router · 1 installer.

---

## The problem it solves

An agent asked to "add tests" writes tests that pass. That is the rational
behavior when the success criterion is a green checkmark, and it produces a suite
that grows fast and asserts nothing.

The same failure appears at every stage: a "spec" that restates the prompt, a
"plan" that is a list of file names, a "review" that says looks good to me. The
agent is not lazy — it is optimizing the only signal it was given.

Gauntlet replaces those signals with artifacts. Red-before-green. An evidence
bundle before "done." A go/no-go decision with a rollback plan before "shipped."
The point is not more process, it is *unfakeable* process.

## Architecture

Three composable layers, deliberately separated:

| Layer | What it is | Job |
|---|---|---|
| **Skills** (`skills/<name>/SKILL.md`) | workflow + steps + exit criteria | the *how* |
| **Personas** (`agents/<role>.md`) | role, perspective, output format | the *who* |
| **Commands** (`commands/*.toml`) | user-facing entry points | the *when* |

**Composition rule: the human is the orchestrator.** A persona may load a skill.
A persona must never invoke another persona — that is the anti-pattern that turns
a clean separation into a router nobody can debug.

The one endorsed multi-agent pattern is parallel fan-out with a merge step, used
by `/ship`: three independent personas investigate, one session synthesizes their
reports into a go/no-go.

`AGENTS.md` is the router: an intent→skill table, the lifecycle, six hard rules,
and an explicit anti-rationalization section naming the thoughts that are wrong
("this is too small for a skill", "the tests pass, so it's done").

## Install

```bash
git clone https://github.com/e-landeros/gauntlet.git
cd gauntlet
./install.sh --dry-run     # print every action, change nothing
./install.sh               # skills + references + personas + router
./install.sh --claude      # also expose skills to Claude Code
```

Flags: `--no-router`, `--force`, `--dry-run`, `--check`, `--uninstall`, `--help`.
Bash plus `cp`/`rsync`/`sed`. No network, no package manager.

**Canonical target is `~/.agents/skills/`** — the cross-harness Agent Skills
location. Claude Code is the one harness that does not read it, so `--claude`
links the same tree into `~/.claude/skills`.

## What is enforced, and what is not

Being precise about this matters more than the feature list.

| Mechanism | Enforced by | Strength |
|---|---|---|
| Skill discovery | filesystem scan by the harness | real |
| Skill frontmatter validity | harness rejects missing `name`/`description` | real |
| Reference links resolve | `install.sh --check` | real |
| Install/uninstall correctness | manifest + idempotent rsync | real |
| Router rules | prompt text in the system prompt | **advisory** |
| Lifecycle ordering | model compliance | **advisory** |
| Artifacts before "done" | model compliance | **advisory** |

The router is a 7 KB instruction file injected into every session. It is not a
gate — nothing stops a model from ignoring it. Two things make non-compliance
visible instead of silent: rule 5 requires the agent to state which skill it
loaded (`Using: test-driven-development`), and rule 6 gives the human explicit
authority to override, so a skipped stage is a stated decision rather than a
quiet one.

If you want enforcement rather than advice, the pattern is gates in CI and
CODEOWNERS on the tests — skills shape the first attempt, gates catch what the
attempt missed.

## Compatibility, verified rather than assumed

| Harness | Reads `~/.agents/skills/` | Note |
|---|---|---|
| Pi | yes, native | documented Agent Skills location |
| Codex | yes, recommended | `~/.codex/skills` is the legacy path |
| GitHub Copilot | yes | personal skills |
| Cursor | yes | user-level |
| VS Code | yes | documented |
| Claude Code | **no** | only `~/.claude/skills/` — hence `--claude` |

Every skill and persona carries only `name` and `description` frontmatter — no
`allowed-tools`, no `compatibility`, no vendor metadata. That minimalism is what
makes the tree portable across six harnesses.

Four skills assume capabilities that are not universal, and degrade predictably:

| Skill | Assumes | Without it |
|---|---|---|
| `idea-refine` | `AskUserQuestion` tool | agent improvises the interview |
| `test-driven-development` | subagent spawning | reproduces the bug inline |
| `doubt-driven-development` | fresh subagent context | adversarial pass runs in-context |
| `browser-testing-with-devtools` | Chrome DevTools MCP | loads, no tools to call |

## Engineering notes

Things that were non-obvious and cost real debugging time:

**The reference-path trap.** Twelve skills link to `../../references/<file>.md`.
Installed at `~/.agents/skills/<name>/`, that resolves to `~/.agents/references/`.
Copy `skills/` without `references/` and twelve skills silently lose their
checklists — no error, the agent just improvises. The installer copies both, and
`--check` verifies every link resolves.

**Why the router is not in `~/.agents/`.** No harness reads
`~/.agents/AGENTS.md`; the only thing `~/.agents` is scanned for is `skills/`.
The router has to be written to each harness's own global instruction path
(`~/.pi/agent/AGENTS.md`, `~/.codex/AGENTS.md`, `~/.claude/CLAUDE.md`) or it is a
correct file in a directory nobody reads.

**Idempotent install with a clean exit.** Re-running does not duplicate or spam
backups (it skips the backup when the target already matches). Uninstall reads a
manifest and removes only what it wrote, restoring any instruction file it
replaced.

**No harness-specific edits.** An earlier version rewrote Hermes'
`config.yaml` to enable an external skills dir. It worked, but the running
gateway rewrote that file underneath it and the backup vanished — so the
dependency was dropped rather than patched. The installer now touches only
directories it owns.

## Limitations

- The router is advisory. It improves behavior; it does not guarantee it.
- Skill descriptions are English-language routing hints. A model that misreads
  the intent will load the wrong skill, and no mechanism catches that.
- macOS and Linux only. No Windows path handling.
- `commands/*.toml` is the Gemini/Antigravity format; other harnesses ignore it.
- The skills encode one engineer's opinions about process. Reasonable people
  disagree about several of them, which is why they are readable markdown rather
  than a framework.

## Credit

The skills, personas, references and commands began as
[addyosmani/agent-skills](https://github.com/addyosmani/agent-skills), Copyright
(c) 2025 Addy Osmani, MIT. This repo is maintained independently — no upstream
tracking, no sync script. The router, installer, documentation and the
verification work above are mine, MIT. See `LICENSE`.
