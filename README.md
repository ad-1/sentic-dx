# sentic-dx

Shared developer experience tooling for the Sentic platform.

This repo is the canonical home for cross-cutting agents, prompts, and workflows that apply to
multiple Sentic services. It does not contain application code or cluster infrastructure.

See [ADR-002](https://github.com/ad-1/sentic-infra/blob/main/docs/adr/ADR-002-SENTIC-DX-SHARED-DEVELOPER-TOOLING.md) for the decision rationale.

## Contents

| Path | Purpose |
|------|---------|
| `.github/prompts/audit-readiness.prompt.md` | Platform-wide Sentic Lab standards checker (Pydantic, env vars, types, dry-run) |
| `.github/prompts/ci-push-and-sync.prompt.md` | CI push and ArgoCD sync workflow (covers signal and notifier) |
| `.github/agents/sentic-architect.agent.md` | Senior Principal Architect — cross-service design, ADRs, roadmap |
| `.github/agents/sentic-reviewer.agent.md` | Code reviewer — quality, refactoring, test coverage across all services |

## Setup

Clone alongside the other Sentic repos and open `sentic-infra/sentic-platform.code-workspace`:

```bash
git clone https://github.com/ad-1/sentic-dx ../sentic-dx
```

The workspace file references `sentic-dx` by relative path — all prompts and agents are
immediately available in all repos once the workspace is open.

## Adding new tooling

- **Applies to one service only** → add to that service's `.github/` directory
- **Applies to multiple services** → add here
