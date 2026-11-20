# agent-skills-personal

A personal, versioned copy of [Addy Osmani's agent-skills](https://github.com/addyosmani/agent-skills)
— 26 skills, 5 personas, and 10 command definitions — plus a global router and a
one-command installer for macOS.

**Canonical install target: `~/.agents/skills/`** — the cross-harness Agent
Skills location. Installed once, read by every agent on the machine that
supports the standard.

This repo exists so the instruction set is **one editable source of truth**
instead of three drifting copies (an npm package, an upstream clone, and
whatever the agents had cached).

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

## Verify it loaded

| Harness | Check |
|---|---|
| Pi | `/skill:using-agent-skills` |
| Codex | `$using-agent-skills` |
| Claude Code | `/skill:using-agent-skills` |
| Hermes | `hermes skills list` (after `--hermes`) |
| Copilot / Cursor / VS Code | skills appear in the agent's skill list |

If a skill does not appear, check that `~/.agents/skills/<name>/SKILL.md` exists
and that its frontmatter has a `description`.

## Why `~/.agents/skills/`

Verified against current documentation at build time:

| Harness | Reads `~/.agents/skills/` | Source |
|---|---|---|
| Pi | yes, native | Pi `docs/skills.md`: "Pi also supports the Agent Skills locations `~/.agents/skills/` and `.agents/skills/`" |
| Codex | yes, recommended | OpenAI Codex `docs/skills.md`; `~/.codex/skills` is the legacy path |
| Hermes | yes, via config | Hermes `docs/user-guide/features/skills.md`: external dirs, `~/.agents/skills` |
| GitHub Copilot | yes | Copilot docs: personal skills in `~/.copilot/skills` or `~/.agents/skills` |
| Cursor | yes | Cursor docs: `~/.agents/skills/` is user-level |
| VS Code | yes | `agentskills.io` quickstart: VS Code reads `.agents/skills/` |
| Claude Code | **no** | Claude Code reads only `~/.claude/skills/` — hence `--claude` |

`~/.agents/skills/` is where the ecosystem is converging; per-harness directories
are the legacy path. Claude Code is the one holdout that needs a link.

## Layout

```text
AGENTS.md            global router installed as ~/.pi/agent/AGENTS.md,
                     ~/.codex/AGENTS.md, ~/.claude/CLAUDE.md
install.sh           installer
VERSION              this repo's version
upstream.lock.json   exact upstream commit and what was vendored
skills/              26 skills (SKILL.md + per-skill references/ and scripts/)
agents/              5 personas
commands/            10 command definitions (.toml, Gemini/Antigravity format)
references/          7 shared checklists that skills cite via ../../references/
```

**Path note:** several skills link to `../../references/<file>.md`. Installed at
`~/.agents/skills/<name>/`, that resolves to `~/.agents/references/`, which is
why the installer copies `references/` there as well. Moving skills without
`references/` silently breaks those links.

## Editing

Edit the repo, then re-run `./install.sh`. Do not edit the installed copies —
the next install overwrites them.

- **Router rules** → `AGENTS.md`. Personal rules go in the *Local overrides*
  section so they survive upstream syncs.
- **A skill's procedure** → `skills/<name>/SKILL.md`. If you diverge from
  upstream, record it in `upstream.lock.json` under `localChanges`.
- **Add your own skill** → create `skills/<kebab-name>/SKILL.md` with `name` and
  `description` frontmatter, add a routing row to `AGENTS.md`, run `./install.sh
  --check`.

## Updating from upstream

```bash
git clone https://github.com/addyosmani/agent-skills /tmp/agent-skills-upstream
cd /tmp/agent-skills-upstream && git checkout <commit>
rsync -a --delete /tmp/agent-skills-upstream/skills/ ~/Documents/Personal/agent-skills-personal/skills/
rsync -a --delete /tmp/agent-skills-upstream/references/ ~/Documents/Personal/agent-skills-personal/references/
rsync -a --delete /tmp/agent-skills-upstream/agents/ ~/Documents/Personal/agent-skills-personal/agents/
rsync -a --delete /tmp/agent-skills-upstream/commands/ ~/Documents/Personal/agent-skills-personal/commands/
```

Then update `upstream.lock.json`, run `./install.sh --check`, commit. Review the
diff before installing: an upstream skill can change behavior in ways that
affect every agent on the machine.

## Not included

- `hooks/` — the Claude hook scripts (`simplify-ignore.sh`, `session-start.sh`,
  `sdd-cache-*.sh`). Harness-specific and require a Pi extension to run; not
  needed for the instructions to work.
- `evals/`, `docs/`, `scripts/` — upstream's own test and documentation
  machinery, irrelevant to consumption.
- `.claude/`, `.gemini/`, `.agents/`, `.opencode/` plugin manifests — the
  installer replaces the need for them.

## License

Skills, personas, references and commands are Copyright (c) 2025 Addy Osmani,
MIT licensed. The original license is preserved at `LICENSE`. The router,
installer, and README are original to this repo, also MIT. See `NOTICE`.
