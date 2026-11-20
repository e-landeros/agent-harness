# agent-skills-personal

A personal instruction set for AI coding agents — 26 skills, 5 personas, and 10
command definitions — installed into the cross-harness Agent Skills location
`~/.agents/skills/`.

This started from [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills)
and is now maintained independently: no upstream tracking, no submodules, no
sync script. What is here is the set.

## Install

```bash
git clone <this-repo> ~/Documents/Personal/agent-skills-personal
cd ~/Documents/Personal/agent-skills-personal
./install.sh --dry-run     # see exactly what will change
./install.sh               # skills + references + personas + global router
```

Optional targets:

```bash
./install.sh --claude      # link skills into ~/.claude/skills
./install.sh --hermes      # enable skills.external_dirs in ~/.hermes/config.yaml
./install.sh --all         # everything
```

Other flags: `--no-router` (skills only), `--force` (overwrite global
instruction files without a backup), `--check` (validate the repo), `--uninstall`.

The installer is bash + `cp`/`rsync`/`sed`. No network access, no package
manager, no npm.

## Drop-in only (no installer)

The skills are plain markdown and work without running anything. If you just
want them available:

```bash
mkdir -p ~/.agents
cp -R skills references agents ~/.agents/
chmod +x ~/.agents/skills/*/scripts/*.sh 2>/dev/null
```

**You must copy `references/` alongside `skills/`.** Eight skills link to
`../../references/<file>.md`, which resolves to `~/.agents/references/` from an
installed skill. Skills without it have dead links.

What you give up by skipping the installer:

- the global router (`AGENTS.md`) — skills are discoverable, but nothing
  enforces the mandatory hops or the lifecycle
- the Claude Code link (`~/.claude/skills`) — Claude Code does not read
  `~/.agents/skills`
- the Hermes `external_dirs` entry — Hermes only reads `~/.agents/skills` when
  configured to

## Verify

| Harness | Check |
|---|---|
| Pi | `/skill:using-agent-skills` |
| Codex | `$using-agent-skills` |
| Claude Code | `/skill:using-agent-skills` (needs `--claude`) |
| Hermes | `hermes skills list` (needs `--hermes`) |
| Copilot / Cursor / VS Code | skills appear in the agent's skill list |

## Why `~/.agents/skills/`

| Harness | Reads `~/.agents/skills/` | Note |
|---|---|---|
| Pi | yes, native | documented Agent Skills location |
| Codex | yes, recommended | `~/.codex/skills` is the legacy path |
| Hermes | yes, via config | `skills.external_dirs` |
| GitHub Copilot | yes | personal skills |
| Cursor | yes | user-level |
| VS Code | yes | documented |
| Claude Code | **no** | only `~/.claude/skills/` — hence `--claude` |

## Layout

```text
AGENTS.md            global router installed as ~/.pi/agent/AGENTS.md,
                     ~/.codex/AGENTS.md, ~/.claude/CLAUDE.md
install.sh           installer
VERSION              repo version
skills/              26 skills (SKILL.md + per-skill references/ and scripts/)
agents/              5 personas
commands/            10 command definitions (.toml, Gemini/Antigravity format)
references/          7 shared checklists that skills cite via ../../references/
```

## Portability

Every `SKILL.md` and persona carries only `name` and `description` frontmatter —
no `allowed-tools`, no `compatibility`, no harness metadata. Discovery is
filesystem-based, so the tree works anywhere the standard is implemented.

Four skills degrade without harness features they assume:

| Skill | Assumes | Without it |
|---|---|---|
| `idea-refine` | `AskUserQuestion` tool | agent improvises the interview, or stalls |
| `test-driven-development` | subagent spawning | reproduces the bug inline instead |
| `doubt-driven-development` | fresh subagent context | adversarial pass happens in the same context |
| `browser-testing-with-devtools` | Chrome DevTools MCP | loads, then has no tools to call |

`test-driven-development` also collides with Hermes' bundled skill of the same
name. Hermes gives local skills precedence, so the bundled one wins there. Rename
this copy or remove the Hermes one if you want the version in this repo.

## Editing

Edit the repo, then re-run `./install.sh`. Do not edit the installed copies —
the next install overwrites them.

- **Router rules** → `AGENTS.md`. Personal rules go in *Local overrides*.
- **A skill's procedure** → `skills/<name>/SKILL.md`.
- **Add a skill** → `skills/<kebab-name>/SKILL.md` with `name` and `description`
  frontmatter matching the directory, add a routing row to `AGENTS.md`, run
  `./install.sh --check`.

## License

Skills, personas, references and commands began as Copyright (c) 2025 Addy
Osmani under the MIT license; see `LICENSE`. The router, installer, and README
are Copyright (c) 2026 Fabian Landeros, also MIT.
