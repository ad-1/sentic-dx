---
description: "Use when: creating a git commit and pushing to GitHub with a standard ticket-style prefix across sentic-infra, sentic-signal, sentic-notifier, or sentic-dx. Auto-generates the commit message so the user does not need to write one."
agent: "agent"
tools: [run_in_terminal, get_terminal_output]
argument-hint: "service=<infra|signal|notifier|dx> work_id=<optional, e.g. GH-42 or SIG-128> push=<yes|no>"
---

You are running a standardized Sentic commit workflow.

If the user provides free-form arguments, parse them leniently.
If no arguments are provided, ask for the target service first.

## Target repo map

- infra -> /Users/andrewdavies/Code/sentic/sentic-infra
- signal -> /Users/andrewdavies/Code/sentic/sentic-signal
- notifier -> /Users/andrewdavies/Code/sentic/sentic-notifier
- dx -> /Users/andrewdavies/Code/sentic/sentic-dx

## Ticket-style prefix rules

Generate `WORK_ID` in this order:
1. If user passed `work_id`, use it.
2. Else, try to parse one from branch name using:
   - `[A-Z]{2,10}-[0-9]+` (e.g. `SIG-42`)
   - `issue/<n>` or `feature/<n>` -> `GH-<n>`
3. Else, generate fallback ID from service code + timestamp:
   - infra -> `INF-$(date +%Y%m%d-%H%M)`
   - signal -> `SIG-$(date +%Y%m%d-%H%M)`
   - notifier -> `NOT-$(date +%Y%m%d-%H%M)`
   - dx -> `DX-$(date +%Y%m%d-%H%M)`

Commit message format is always:

`<WORK_ID>: <imperative-summary>`

Examples:
- `SIG-42: simplify docker install layer order`
- `GH-317: add smoke check for rabbitmq publisher`
- `INF-20260501-0840: document bootstrap prerequisites`

## Workflow

1. Validate repo and branch
- Run `git -C <repo> rev-parse --abbrev-ref HEAD`.
- If branch is `main`, ask for explicit confirmation before committing.

2. Stage changes
- If there are staged changes, keep staged set as-is.
- If none are staged, run `git -C <repo> add -A`.

3. Build summary for commit line
- Inspect staged diff via:
  - `git -C <repo> diff --cached --name-status`
  - `git -C <repo> diff --cached --stat`
- Generate a concise imperative summary in lower case, usually <= 72 chars.
- Avoid vague summaries like "update files" or "fix stuff".

4. Commit
- Construct message: `<WORK_ID>: <summary>`
- Run `git -C <repo> commit -m "<message>"`
- If there is nothing to commit, report and stop.

5. Push (default: yes)
- Unless `push=no`, push current branch.
- If upstream exists: `git -C <repo> push`
- If no upstream: `git -C <repo> push --set-upstream origin <branch>`
- Never force push.

6. Output
- Show final commit message, commit hash, branch, and push result.
- If push is skipped, say exactly how to push manually.

## Guardrails

- Do not amend or rewrite history unless user explicitly asks.
- Do not include unrelated changes from other repositories.
- Keep commits atomic; if the staged diff is clearly multi-purpose, suggest splitting.
