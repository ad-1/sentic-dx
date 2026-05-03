---
description: "Use when: pushing a sentic service to main, waiting for CI pipeline to pass, and pulling the automated image-tag PR merge back locally. Handles the full push → pipeline watch → PR awareness → git pull cycle for sentic-notifier and sentic-signal."
agent: "agent"
tools: [run_in_terminal, get_terminal_output]
argument-hint: "notifier | signal"
---

You are automating the CI deploy cycle for a Sentic service. The user has provided the service name as the argument (e.g. `notifier` or `signal`). If no argument was given, ask which service before proceeding.

## Context

Both `sentic-notifier` and `sentic-signal` follow the same CI pipeline on push to `main`:
1. **Test** — unit tests must pass.
2. **Build & Push** — Docker image built and pushed to GHCR with a `sha-<short>` tag.
3. **Update Image Tag** — CI opens a PR to bump `deploy/chart/values.yaml` with the new tag. This PR requires human approval before merge.
4. **ArgoCD** — detects the merged PR and syncs the cluster automatically.

After the tag-bump PR is merged, the local repo will be behind `origin/main` by one commit (the automated bump). A `git pull` is required before the next push to avoid a merge conflict on `values.yaml`.

## Repo paths

- notifier → `/Users/andrewdavies/Code/sentic/sentic-notifier`
- signal → `/Users/andrewdavies/Code/sentic/sentic-signal`

## Steps to follow

### 1 — Push to main

Run in the target repo directory:
```
git push origin main
```
Report the output. If the push fails (e.g. diverged history), stop and explain.

### 2 — Watch the CI pipeline

Use the GitHub CLI to watch the run triggered by that push:
```
gh run watch --repo ad-1/sentic-<service>
```
This streams live output and exits with a non-zero code if the pipeline fails.

If the pipeline fails, display the failure step and stop — do not proceed to the pull.

### 3 — Find the image-tag PR

Once the pipeline succeeds, list the open PRs to surface the automated tag-bump PR:
```
gh pr list --repo ad-1/sentic-<service> --head "ci/image-tag-*"
```
Show the PR title and URL. Remind the user that **this PR requires manual approval** before it can be merged.

Wait for the user to confirm the PR has been merged before continuing.

### 4 — Pull the merged commit

Once the user confirms the PR is merged, run:
```
git -C <repo-path> pull --ff-only origin main
```
Confirm the local branch is now up to date and show the latest commit (the automated tag bump).

### 5 — Summary

Print a brief summary:
- Service deployed
- Image tag pushed (extract from the PR title or values.yaml)
- CI status
- Local branch status
