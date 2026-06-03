# claude-cli-tools

Claude Code install, backup, and restore for Linux (and macOS).

Installs Claude via the [native installer](https://claude.ai/install.sh), deploys a tmux window-naming wrapper (`cl`), and keeps your `~/.claude/` configuration backed up with incremental rsync snapshots.

## Installation

```bash
git clone https://github.com/therain-4u/claude-cli-tools.git
cd claude-cli-tools
./claude-cli-tools --install
```

`--install` does three things:

1. Runs the Claude native installer → `~/.local/bin/claude`
2. Deploys the `cl` tmux wrapper → `~/.local/bin/cl`
3. Runs `--setup` (audit hooks + hourly backup cron)

If snapshots already exist in `~/development/claude/snapshots/`, it automatically restores the latest one so the backup cron doesn't capture an empty install. Pass `--no-auto-restore` to skip this.

Make sure `~/.local/bin` is in your PATH:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
```

## Usage

```
./claude-cli-tools --install    [--no-auto-restore]
./claude-cli-tools --setup
./claude-cli-tools --backup
./claude-cli-tools --restore    [snapshot-dir] [--force]
./claude-cli-tools --status
```

### `--install`

Installs Claude, deploys `cl`, and runs `--setup`. Safe to re-run on an existing installation.

### `--setup`

Deploys bash audit hooks into `~/.claude/settings.json` and installs an hourly cron job for `--backup`. Idempotent — safe to re-run.

Hooks log every Bash command Claude attempts and completes to `data/bash-audit.jsonl`.

### `--backup`

Trims `.jsonl` session files older than 14 days from `~/.claude/projects/`, then creates an incremental rsync snapshot under `~/development/claude/snapshots/`. Installed as an hourly cron by `--setup`.

Unchanged files are hardlinked to the previous snapshot — zero extra disk space per run.

### `--restore [snapshot-dir] [--force]`

Restores the latest snapshot (or a named one) into `~/.claude/`. Safety checks: source must be non-empty and at least 50% the size of the current live directory. Use `--force` to override the size check (not the empty check).

Creates a `live-YYYYMMDDTHHMMSS.tar.gz` pre-restore safety snapshot before overwriting.

### `--status`

Shows snapshot count, latest snapshot date, disk usage, and whether `~/.claude/` looks in sync with the latest snapshot. Also reports cron and hook state.

## What gets backed up

All of `~/.claude/` — settings, commands, memory, MCP config, conversation history. Snapshots land in `~/development/claude/snapshots/`, which is a good fit for an existing restic or similar backup covering `~/development/`.

Conversation history (`.jsonl` files) older than 14 days is trimmed from the live directory before each snapshot to keep backup size manageable.

## The `cl` wrapper

`cl` is a drop-in replacement for `claude` that renames your tmux window to the session name while Claude is running. It polls `~/.claude/sessions/<pid>.json` for the session name and updates the window title every 3 seconds as it changes.

```bash
cl                  # start Claude (renames tmux window)
cl --resume         # resume a session
CLAUDE_BIN=/path/to/claude cl   # override Claude binary location
```

## Restoring on a new machine

```bash
git clone https://github.com/therain-4u/claude-cli-tools.git
cd claude-cli-tools
./claude-cli-tools --install --no-auto-restore
./claude-cli-tools --restore /path/to/existing/snapshot
```

Or copy your snapshot directory to `~/development/claude/snapshots/` first and omit `--no-auto-restore` — `--install` will auto-restore the latest one.

## Environment variables

| Variable | Default | Description |
|---|---|---|
| `CLAUDE_SNAPSHOTS` | `~/development/claude/snapshots` | Override snapshot directory |
| `CLAUDE_BIN` | `~/.local/bin/claude` | Override Claude binary path (used by `cl`) |
