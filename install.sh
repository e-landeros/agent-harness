#!/usr/bin/env bash
# Install this instruction set on the local machine.
#
# Canonical target: ~/.agents/skills/ — the cross-harness Agent Skills location
# read by Pi, Codex, Copilot, Cursor and VS Code. Claude Code does not read it,
# so --claude links the same tree into ~/.claude/skills.
#
# No dependencies beyond bash, cp, rsync, sed. Nothing is fetched from the network.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="$(cat "$REPO_DIR/VERSION" 2>/dev/null || echo unknown)"

AGENTS_HOME="${AGENTS_HOME:-$HOME/.agents}"
SKILLS_DST="$AGENTS_HOME/skills"
REFS_DST="$AGENTS_HOME/references"
PERSONAS_DST="$AGENTS_HOME/agents"
MANIFEST="$AGENTS_HOME/.installed-by-gauntlet"

PI_HOME="${PI_HOME:-$HOME/.pi/agent}"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"

DO_CLAUDE=0
DO_ROUTER=1
DO_UNINSTALL=0
DO_CHECK=0
DRY_RUN=0
FORCE=0

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

  (no options)     install skills, references, personas and the global router
  --claude         also expose the skills to Claude Code (~/.claude/skills)
  --all            same as --claude
  --no-router      install skills only; leave global instruction files alone
  --force          overwrite global instruction files without keeping a backup
  --dry-run        print every action, change nothing
  --uninstall      remove what this script installed
  --check          validate the repo (frontmatter, names, reference links)
  -h, --help       this message
EOF
}

say() { printf '%s\n' "$*"; }
run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '  [dry-run] %s\n' "$*"
  else
    "$@"
  fi
}

for arg in "$@"; do
  case "$arg" in
    --all|--claude) DO_CLAUDE=1 ;;
    --no-router) DO_ROUTER=0 ;;
    --force) FORCE=1 ;;
    --dry-run) DRY_RUN=1 ;;
    --uninstall) DO_UNINSTALL=1 ;;
    --check) DO_CHECK=1 ;;
    -h|--help) usage; exit 0 ;;
    *) say "unknown option: $arg"; usage; exit 2 ;;
  esac
done

# ---------------------------------------------------------------- validation

check_repo() {
  local fail=0 name dir desc
  say "Validating $REPO_DIR"
  for dir in "$REPO_DIR"/skills/*/; do
    name="$(basename "$dir")"
    if [ ! -f "$dir/SKILL.md" ]; then say "FAIL $name: no SKILL.md"; fail=1; continue; fi
    desc="$(awk '/^description:/{sub(/^description: */,""); print; exit}' "$dir/SKILL.md")"
    if [ -z "$desc" ]; then say "FAIL $name: missing description"; fail=1; fi
    if ! grep -q "^name: $name\$" "$dir/SKILL.md"; then
      say "FAIL $name: frontmatter name does not match directory"; fail=1
    fi
  done
  for dir in "$REPO_DIR"/skills/*/; do
    grep -o '\.\./\.\./references/[A-Za-z0-9._-]*' "$dir/SKILL.md" 2>/dev/null \
      | sort -u \
      | while read -r ref; do
          [ -f "$REPO_DIR/${ref#../../}" ] || say "WARN $(basename "$dir"): broken link $ref"
        done || true
  done
  if [ "$fail" -eq 0 ]; then
    say "OK: $(ls -d "$REPO_DIR"/skills/*/ | wc -l | tr -d ' ') skills valid"
  fi
  return "$fail"
}

# ---------------------------------------------------------------- uninstall

uninstall() {
  say "Uninstalling from $AGENTS_HOME"
  if [ -f "$MANIFEST" ]; then
    run rm -rf "$SKILLS_DST" "$REFS_DST" "$PERSONAS_DST"
    run rm -f "$MANIFEST"
  else
    say "  no manifest at $MANIFEST — leaving $AGENTS_HOME alone"
  fi
  if [ -L "$CLAUDE_HOME/skills" ] && [ "$(readlink "$CLAUDE_HOME/skills")" = "$SKILLS_DST" ]; then
    run rm -f "$CLAUDE_HOME/skills"
    say "  removed $CLAUDE_HOME/skills symlink"
  fi
  for f in "$PI_HOME/AGENTS.md" "$CODEX_HOME/AGENTS.md" "$CLAUDE_HOME/CLAUDE.md"; do
    backup="$(ls -1t "$f".bak.* 2>/dev/null | head -1 || true)"
    if [ -n "$backup" ]; then
      run mv "$backup" "$f"
      say "  restored $f"
    elif [ -f "$f" ] && grep -q "global skill router" "$f" 2>/dev/null; then
      run rm -f "$f"
      say "  removed $f (was ours, no backup existed)"
    fi
  done
}

# ---------------------------------------------------------------- install

install_skills() {
  say "Installing skills -> $SKILLS_DST"
  run mkdir -p "$SKILLS_DST" "$REFS_DST" "$PERSONAS_DST"
  for dir in "$REPO_DIR"/skills/*/; do
    run rsync -a --delete "$dir" "$SKILLS_DST/$(basename "$dir")/"
  done
  run rsync -a --delete "$REPO_DIR/references/" "$REFS_DST/"
  run rsync -a --delete "$REPO_DIR/agents/" "$PERSONAS_DST/"
  if [ "$DRY_RUN" -eq 0 ]; then
    printf 'version=%s\ninstalled=%s\n' "$VERSION" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$MANIFEST"
  fi
  say "  $(ls -d "$REPO_DIR"/skills/*/ | wc -l | tr -d ' ') skills, $(ls "$REPO_DIR"/references/*.md | wc -l | tr -d ' ') reference files, $(ls "$REPO_DIR"/agents/*.md | wc -l | tr -d ' ') personas"
}

install_router() {
  say "Installing global router"
  for f in "$PI_HOME/AGENTS.md" "$CODEX_HOME/AGENTS.md" "$CLAUDE_HOME/CLAUDE.md"; do
    run mkdir -p "$(dirname "$f")"
    if [ -f "$f" ] && [ "$FORCE" -eq 0 ] && ! cmp -s "$f" "$REPO_DIR/AGENTS.md"; then
      stamp="$(date -u +%Y%m%dT%H%M%SZ)"
      run cp "$f" "$f.bak.$stamp"
      say "  backed up $f -> $f.bak.$stamp"
    fi
    run cp "$REPO_DIR/AGENTS.md" "$f"
    say "  wrote $f"
  done
}

install_claude() {
  say "Exposing skills to Claude Code"
  run mkdir -p "$CLAUDE_HOME"
  if [ -e "$CLAUDE_HOME/skills" ] && [ ! -L "$CLAUDE_HOME/skills" ]; then
    say "  $CLAUDE_HOME/skills already exists as a directory — copying instead of linking"
    run mkdir -p "$CLAUDE_HOME/skills"
    for dir in "$REPO_DIR"/skills/*/; do
      run rsync -a --delete "$dir" "$CLAUDE_HOME/skills/$(basename "$dir")/"
    done
  else
    run ln -sfn "$SKILLS_DST" "$CLAUDE_HOME/skills"
    say "  linked $CLAUDE_HOME/skills -> $SKILLS_DST"
  fi
}

say "gauntlet $VERSION"

if [ "$DO_CHECK" -eq 1 ]; then check_repo; exit $?; fi
if [ "$DO_UNINSTALL" -eq 1 ]; then uninstall; exit 0; fi

install_skills
if [ "$DO_ROUTER" -eq 1 ]; then install_router; fi
if [ "$DO_CLAUDE" -eq 1 ]; then install_claude; fi

say ""
say "Done. Verify with:"
say "  Pi:     /skill:using-agent-skills"
say "  Codex:  \$using-agent-skills"
say "  Claude: /skill:using-agent-skills"
