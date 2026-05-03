# sentic-dx

Shared developer experience tooling for the Sentic platform.

This repo is the canonical home for cross-cutting agents, prompts, and workflows that apply to
multiple Sentic services. It does not contain application code or cluster infrastructure.

See [ADR-002](https://github.com/ad-1/sentic-infra/blob/main/docs/adr/ADR-002-SENTIC-DX-SHARED-DEVELOPER-TOOLING.md) for the decision rationale.

## Contents

| Path | Purpose |
|------|---------|
| `.github/prompts/audit-readiness.prompt.md` | Platform-wide Sentic Lab standards checker (Pydantic, env vars, types, dry-run) |
| `.github/prompts/commit-and-push.prompt.md` | Auto-stage, generate SEN-prefixed commit message, commit, and push to GitHub |
| `.github/prompts/ci-push-and-sync.prompt.md` | CI push and ArgoCD sync workflow (covers signal and notifier) |
| `.github/agents/sentic-architect.agent.md` | Senior Principal Architect - cross-service design, ADRs, roadmap |
| `.github/agents/sentic-shipper.agent.md` | Git workflow operator for SEN-prefixed commits and safe pushes |
| `.github/agents/sentic-reviewer.agent.md` | Code reviewer - quality, refactoring, test coverage across all services |
| `.github/workflows/commit-message-check.yml` | Minimal SEN commit-prefix CI check (same file shape in each repo) |

## Commit and Push Workflow

The `commit-and-push` prompt handles the full commit workflow - staging, message generation, and push.

### In VS Code Copilot Chat

Open the chat panel (`⌘I` or `⌃⌘I`) and type:

```bash
@workspace /commit-and-push service=dx
```

Or pass an explicit work ID:

```bash
@workspace /commit-and-push service=signal work_id=SEN-99
```

### What the prompt does

1. Validates the repo and branch (warns before committing to `main`)
2. Stages all changes if nothing is already staged
3. Generates a concise imperative summary from the diff
4. Constructs the message: `<WORK_ID>: <summary>`
5. Commits and pushes (or prints the push command if skipped)

### Work ID resolution

| Situation | ID used |
|-----------|---------|
| `work_id=SEN-42` passed | `SEN-42` |
| Branch named `feature/42` | `SEN-42` |
| Branch name has no numeric suffix | `SEN` |

### Supported services

| Argument | Repo |
|----------|------|
| `service=infra` | `sentic-infra` |
| `service=signal` | `sentic-signal` |
| `service=notifier` | `sentic-notifier` |
| `service=extractor` | `sentic-extractor` |
| `service=aggregator` | `sentic-aggregator` |
| `service=analyst` | `sentic-analyst` |
| `service=dx` | `sentic-dx` |

## Setup

Clone alongside the other Sentic repos and open `sentic-infra/sentic-platform.code-workspace`:

```bash
git clone https://github.com/ad-1/sentic-dx ../sentic-dx
```

The workspace file references `sentic-dx` by relative path - all prompts and agents are
immediately available in all repos once the workspace is open.

## Commit Prefix Policy

Every Sentic repo uses one lightweight CI-only commit format rule:

- Commit subject starts with `SEN`
- Allowed forms: `SEN: <summary>` or `SEN-<number>: <summary>`
- Validation runs on every pull request via `.github/workflows/commit-message-check.yml`

### Format

```text
SEN(-<number>)?: <imperative summary>
```

Examples:

- `SEN: simplify docker install layer order`
- `SEN-42: add smoke check for rabbitmq publisher`
- `SEN-317: document bootstrap prerequisites`

### Reuse model

- Every repo uses the same tiny `commit-message-check.yml` file
- Rule is intentionally minimal: `^SEN(-[0-9]+)?: .+`
- No local git hooks and no validator scripts required

### Status across repos

| Repo | CI workflow |
|------|-------------|
| sentic-infra | `commit-message-check.yml` |
| sentic-notifier | `commit-message-check.yml` |
| sentic-signal | `commit-message-check.yml` |
| sentic-extractor | `commit-message-check.yml` |
| sentic-aggregator | `commit-message-check.yml` |
| sentic-analyst | `commit-message-check.yml` |
| sentic-dx | `commit-message-check.yml` |

## CI Pipeline Pattern

All service repos (`sentic-signal`, `sentic-notifier`) follow the same pipeline:

```text
push to main
  -> test + helm-lint (parallel)
    -> build-and-push (GHCR)
      -> trivy vulnerability scan
        -> open image-tag PR (ci/image-tag-<sha>)
          -> auto-merge -> ArgoCD sync -> deploy
```

### Image Tag PRs

After a successful build, CI opens a PR that bumps the image tag in `values.yaml`
(or `kustomization.yaml` for repos using the infra reusable workflow). The PR is scoped to
the deploy config file only.

Auto-merge is enabled on the PR immediately after creation using
`peter-evans/enable-pull-request-automerge` with squash merge.

### Commit Message Check

All PRs (including image-tag PRs) pass through `commit-message-check.yml`.
Image-tag PR commits use `SEN-0:` to satisfy the same rule.

### Required GitHub settings

| Setting | Location |
|---------|----------|
| Allow auto-merge | Settings -> General -> Pull Requests |
| Allow squash merging | Settings -> General -> Pull Requests |
| Actions write permissions | Settings -> Actions -> General -> Workflow permissions |
| Allow Actions to create PRs | Settings -> Actions -> General |

## Adding new tooling

- Applies to one service only -> add to that service's `.github/` directory
- Applies to multiple services -> add here
