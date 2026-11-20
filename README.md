# agent-harness

My agent instruction set: 26 skills, 5 personas and 10 command definitions,
installed into the cross-harness Agent Skills location `~/.agents/skills/`.

It is the configuration I actually run on my machine — Pi, Codex and Claude Code
all read from it. Publishing it so the setup is inspectable and reusable, not so
it is a library you have to adopt wholesale.

## Install

```bash
git clone https://github.com/e-landeros/agent-harness.git
cd agent-harness
./install.sh --dry-run     # see exactly what will change
./install.sh               # skills + references + personas + global router
```

To also expose the skills to Claude Code, which does not read `~/.agents/skills`:

```bash
./install.sh --claude
```

Other flags: `--no-router` (skills only), `--force` (overwrite global instruction
files without a backup), `--check` (validate the repo), `--uninstall`.

The installer is bash plus `cp`/`rsync`/`sed`. No network access, no package
manager, no npm.

## Drop-in only

The skills are plain markdown and work without running anything:

```bash
mkdir -p ~/.agents
cp -R skills references agents ~/.agents/
chmod +x ~/.agents/skills/*/scripts/*.sh 2>/dev/null
```

**Copy `references/` alongside `skills/`.** Twelve skills link to
`../../references/<file>.md`, which resolves to `~/.agents/references/` from an
installed skill. Skills without it have dead links.

Skipping the installer costs you three things: the global router (`AGENTS.md`),
so skills are discoverable but nothing enforces when to use them; the Claude Code
link; and the manifest that makes `--uninstall` clean.

## Verify

| Harness | Check |
|---|---|
| Pi | `/skill:using-agent-skills` |
| Codex | `$using-agent-skills` |
| Claude Code | `/skill:using-agent-skills` (needs `--claude`) |
| Copilot / Cursor / VS Code | skills appear in the agent's skill list |

## Why `~/.agents/skills/`

| Harness | Reads `~/.agents/skills/` | Note |
|---|---|---|
| Pi | yes, native | documented Agent Skills location |
| Codex | yes, recommended | `~/.codex/skills` is the legacy path |
| GitHub Copilot | yes | personal skills |
| Cursor | yes | user-level |
| VS Code | yes | documented |
| Claude Code | **no** | only `~/.claude/skills/` — hence `--claude` |

## Layout

```text
AGENTS.md            global router, installed as ~/.pi/agent/AGENTS.md,
                     ~/.codex/AGENTS.md and ~/.claude/CLAUDE.md
install.sh           installer
VERSION
skills/              26 skills (SKILL.md plus per-skill references/ and scripts/)
agents/              5 personas
commands/            10 command definitions (.toml, Gemini/Antigravity format)
references/          7 shared checklists that skills cite via ../../references/
```

The router is not stored in `~/.agents/`, because no harness reads
`~/.agents/AGENTS.md` — the only thing `~/.agents` is scanned for is `skills/`.
Each harness has its own global instruction path, so the router is written to
each of those instead.

## Portability

Every `SKILL.md` and persona carries only `name` and `description` frontmatter —
no `allowed-tools`, no `compatibility`, no harness metadata. Discovery is
filesystem-based, so the tree works anywhere the standard is implemented.

Four skills assume harness features and degrade without them:

| Skill | Assumes | Without it |
|---|---|---|
| `idea-refine` | `AskUserQuestion` tool | agent improvises the interview, or stalls |
| `test-driven-development` | subagent spawning | reproduces the bug inline instead |
| `doubt-driven-development` | fresh subagent context | adversarial pass runs in the same context |
| `browser-testing-with-devtools` | Chrome DevTools MCP | loads, then has no tools to call |

## Editing

Edit the repo, then re-run `./install.sh`. Do not edit the installed copies —
the next install overwrites them.

- **Router rules** → `AGENTS.md`. Personal rules go in *Local overrides*.
- **A skill's procedure** → `skills/<name>/SKILL.md`.
- **Add a skill** → `skills/<kebab-name>/SKILL.md` with `name` and `description`
  frontmatter matching the directory, add a routing row to `AGENTS.md`, run
  `./install.sh --check`.

## Credit

The skills, personas, references and commands began as
[addyosmani/agent-skills](https://github.com/addyosmani/agent-skills), Copyright
(c) 2025 Addy Osmani, MIT. This repo is maintained independently — no upstream
tracking, no sync script. The router, installer and documentation are mine,
MIT. See `LICENSE`.
