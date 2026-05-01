# sentic-dx

Shared developer experience tooling for the Sentic platform.

This repo is the canonical home for cross-cutting agents, prompts, and workflows that apply to
multiple Sentic services. It does not contain application code or cluster infrastructure.

See [ADR-002](https://github.com/ad-1/sentic-infra/blob/main/docs/adr/ADR-002-SENTIC-DX-SHARED-DEVELOPER-TOOLING.md) for the decision rationale.

## Contents

| Path | Purpose |
|------|---------|
| `.github/prompts/audit-readiness.prompt.md` | Platform-wide Sentic Lab standards checker (Pydantic, env vars, types, dry-run) |
| `.github/prompts/commit-and-push.prompt.md` | Auto-stage, generate prefixed commit message, commit, and push to GitHub |
| `.github/prompts/ci-push-and-sync.prompt.md` | CI push and ArgoCD sync workflow (covers signal and notifier) |
| `.github/agents/sentic-architect.agent.md` | Senior Principal Architect — cross-service design, ADRs, roadmap |
| `.github/agents/sentic-shipper.agent.md` | Git workflow operator for ticket-prefixed commits and safe pushes |
| `.github/agents/sentic-reviewer.agent.md` | Code reviewer — quality, refactoring, test coverage across all services |
| `.githooks/commit-msg` | Local git hook — delegates to `scripts/validate-commit-message.sh` |
| `scripts/validate-commit-message.sh` | Validates commit subject format (shared across all repos) |
| `scripts/test-commit-msg-hook.sh` | 16-case pass/fail test suite for the commit message validator |
| `.github/workflows/commit-message-check.yml` | CI backstop — validates all PR commits against the same format |

## Commit and Push Workflow

The `commit-and-push` prompt handles the full commit workflow — staging, message generation, and push — so you never have to write a ticket-prefixed message manually.

### In VS Code Copilot Chat

Open the chat panel (`⌘I` or `⌃⌘I`) and type:

```
@workspace /commit-and-push service=dx
```

Or pass an explicit work ID:

```
@workspace /commit-and-push service=signal work_id=SIG-99
```

### What the prompt does

1. **Validates** the repo and branch (warns before committing to `main`)
2. **Stages** all changes if nothing is already staged
3. **Generates** a concise imperative summary from the diff
4. **Constructs** the message: `<WORK_ID>: <summary>`
5. **Commits** and **pushes** (or prints the push command if skipped)

### Work ID resolution

| Situation | ID used |
|-----------|---------|
| `work_id=SIG-42` passed | `SIG-42` |
| Branch named `feature/42` | `GH-42` |
| Branch named `SIG-99-foo` | `SIG-99` |
| No ticket found | `<SVC>-YYYYMMDD-HHMM` (e.g. `DX-20260501-0955`) |

### Supported services

| Argument | Repo |
|----------|------|
| `service=infra` | `sentic-infra` |
| `service=signal` | `sentic-signal` |
| `service=notifier` | `sentic-notifier` |
| `service=dx` | `sentic-dx` |

## Setup

Clone alongside the other Sentic repos and open `sentic-infra/sentic-platform.code-workspace`:

```bash
git clone https://github.com/ad-1/sentic-dx ../sentic-dx
```

The workspace file references `sentic-dx` by relative path — all prompts and agents are
immediately available in all repos once the workspace is open.

## Commit Message Hooks

Every Sentic repo enforces a consistent commit message format at two layers:

| Layer | Mechanism | When it fires |
|-------|-----------|---------------|
| Local | `git commit-msg` hook | Every `git commit` on the developer's machine |
| CI | `.github/workflows/commit-message-check.yml` | Every PR on GitHub Actions |

### Format

```
<WORK_ID>: <imperative summary starting lowercase>
```

| Pattern | Example |
|---------|---------|
| `PREFIX-N` (ticket) | `SIG-42: simplify docker install layer order` |
| `PREFIX-YYYYMMDD-HHMM` (date-stamp) | `INF-20260501-0840: document bootstrap prerequisites` |

Rules:
- Prefix: 2–10 uppercase letters, hyphen, digits
- Colon + space separator (`: `)
- Body starts with a lowercase letter or digit
- Subject line ≤ 120 characters
- Merge commits are skipped by the CI check

### Installing the hook (per repo)

Each repo ships `.githooks/commit-msg` and `scripts/validate-commit-message.sh`. Register the
hooks directory once after cloning:

```bash
git config --local core.hooksPath .githooks
```

Verify it is active:

```bash
git config --local core.hooksPath   # should print: .githooks
```

### Testing the hooks

Run the shared test suite from this repo against any validator:

```bash
# Test the local repo's validator
./scripts/test-commit-msg-hook.sh

# Test another repo's validator
./scripts/test-commit-msg-hook.sh /path/to/repo/scripts/validate-commit-message.sh
```

The script exercises 16 cases — 6 that must pass and 10 that must be blocked — and exits
non-zero if any case behaves unexpectedly.

**Live git commit test (manual)**:

```bash
# Should be blocked
git commit --allow-empty -m "wip: bad message"

# Should succeed
git commit --allow-empty -m "DX-1: test commit hook validation"
```

### Status across repos

| Repo | `core.hooksPath` | Hook file | CI workflow |
|------|-----------------|-----------|-------------|
| sentic-infra | `.githooks` ✓ | `.githooks/commit-msg` ✓ | `commit-message-check.yml` ✓ |
| sentic-notifier | `.githooks` ✓ | `.githooks/commit-msg` ✓ | `commit-message-check.yml` ✓ |
| sentic-signal | `.githooks` ✓ | `.githooks/commit-msg` ✓ | `commit-message-check.yml` ✓ |
| sentic-dx | `.githooks` ✓ | `.githooks/commit-msg` ✓ | `commit-message-check.yml` ✓ |

> **Note for new clones**: `core.hooksPath` is a local git setting and is not committed.
> Each developer must run `git config --local core.hooksPath .githooks` once per clone.

## Adding new tooling

- **Applies to one service only** → add to that service's `.github/` directory
- **Applies to multiple services** → add here
