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
