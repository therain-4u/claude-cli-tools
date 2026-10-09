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
3. Runs `--setup` (hourly backup job; removes the retired audit hooks)

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

Installs an hourly job for `--backup` (cron on Linux, launchd on macOS). Idempotent — safe to re-run.

It also removes any hook in `~/.claude/settings.json` whose command points into this repo's `hooks/` directory, leaving every other hook and key alone. The bash audit hooks (`pre-bash.sh`, `post-bash.sh`) were retired on 2026-08-28; their settings entries outlived the scripts and made every Bash tool call print a "not found" hook error once the deletion reached each checkout. `--setup` no longer installs any hook.

### `--backup`

Trims `.jsonl` session files older than 90 days (`CONVERSATION_HISTORY_DAYS`) from `~/.claude/projects/`, then creates an incremental rsync snapshot under `~/development/claude/snapshots/`. Installed as an hourly cron by `--setup`.

Unchanged files are hardlinked to the previous snapshot — zero extra disk space per run.

### `--restore [snapshot-dir] [--force]`

Restores the latest snapshot (or a named one) into `~/.claude/`. Safety checks: source must be non-empty and at least 50% the size of the current live directory. Use `--force` to override the size check (not the empty check).

Creates a `live-YYYYMMDDTHHMMSS.tar.gz` pre-restore safety snapshot before overwriting.

### `--status`

Shows snapshot count, latest snapshot date, disk usage, and whether `~/.claude/` looks in sync with the latest snapshot. Also reports the backup job state, and warns if a retired audit hook is still registered.

## What gets backed up

All of `~/.claude/` — settings, commands, memory, MCP config, conversation history. Snapshots land in `~/development/claude/snapshots/`, which is a good fit for an existing restic or similar backup covering `~/development/`.

Conversation history (`.jsonl` files) not changed in 90 days is trimmed from the live directory before each snapshot to keep backup size manageable. This matches Claude Code's own `cleanupPeriodDays`, which ansible sets to 90 on every control node; whichever is shorter is the effective retention, so change both together. (Was 14 days until 2026-10-08.)

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
