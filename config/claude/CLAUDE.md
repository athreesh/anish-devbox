# Devbox Claude Defaults

## Workspace

- Treat `~/repos` as the main checkout root.
- Prefer existing repo conventions over new abstractions.
- Keep edits narrowly scoped to the requested task.
- Preserve user changes you did not make.
- Use `rg`/`rg --files` first for search.

## Workflow

- For long-running agent work, use tmux so sessions survive SSH disconnects.
- Before changing files, inspect the nearby code and current git status.
- After code changes, run the smallest useful syntax, lint, or test check available.
- When a command fails, keep the failure visible and suggest the next concrete command.

## Skills

- Personal reusable procedures live in `~/.claude/skills/<skill-name>/SKILL.md`.
- Full skill bodies load only when invoked or when Claude decides they are relevant.
- Use skills for multi-step workflows; keep this file for short, always-on preferences.

