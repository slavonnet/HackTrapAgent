# Cursor Agent GitLab bootstrap

This repository includes `scripts/bootstrap_cursor_gitlab.sh`, a bootstrap helper for a GitLab Self-Managed installation that uses a central Cursor Agent kit project.

## Target architecture

The bootstrap script configures the direct central-pipeline mode:

1. A user comments in a GitLab issue or merge request.
2. The target project's Note Hook calls the central `infra/cursor-agent-kit` pipeline trigger endpoint.
3. The kit pipeline reads GitLab's `TRIGGER_PAYLOAD`.
4. The kit job ignores non-agent comments and comments from `cursor-bot`.
5. For `/cursor ...` commands or `@cursor-bot` mentions, the kit job runs Cursor CLI headlessly and posts the result back to GitLab.

This keeps normal project pipelines separate from agent automation. Build, test, release, and deployment jobs in application projects do not need to be changed for the agent bootstrap.

## Prerequisites

- GitLab Self-Managed is reachable at `http://192.168.200.35`.
- `glab` is installed locally.
- `jq` and `python3` are installed locally.
- You are authenticated as an instance administrator:

```bash
glab auth login --hostname 192.168.200.35
```

- The central project exists, or the script is allowed to create it:

```text
infra/cursor-agent-kit
```

- The kit project contains the central pipeline file:

```text
ci/cursor-agent.gitlab-ci.yml
```

## Basic usage

Configure one project:

```bash
CURSOR_API_KEY=... scripts/bootstrap_cursor_gitlab.sh \
  --target-project my-group/my-project
```

Configure all projects in one group, including subgroups:

```bash
CURSOR_API_KEY=... scripts/bootstrap_cursor_gitlab.sh \
  --target-group apps
```

Configure every visible project on the instance:

```bash
CURSOR_API_KEY=... scripts/bootstrap_cursor_gitlab.sh \
  --all-projects
```

Preview changes without mutating GitLab:

```bash
scripts/bootstrap_cursor_gitlab.sh --target-group apps --dry-run
```

## What the script changes

- Ensures the `infra` group exists.
- Ensures the `infra/cursor-agent-kit` project exists.
- Ensures a `cursor-bot` user exists.
- Creates a bot personal access token when the kit project does not already have `GITLAB_TOKEN`.
- Stores `GITLAB_TOKEN` as a masked CI/CD variable in the kit project.
- Stores `CURSOR_API_KEY` as a masked CI/CD variable in the kit project when it is provided in the local environment.
- Creates or reuses a pipeline trigger token in the kit project.
- Adds Note Hook webhooks to selected target projects.
- Adds `cursor:running`, `cursor:needs-input`, `cursor:done`, and `cursor:failed` labels to selected target projects.
- Grants `cursor-bot` Owner access to selected target groups and Maintainer access to selected standalone target projects.

The script does not patch target project `.gitlab-ci.yml` files. This is intentional: the central kit pipeline handles agent work without interfering with project-owned CI/CD.

## Token behavior

The bot token is not printed. It is written directly to the central kit project's masked `GITLAB_TOKEN` variable.

If `GITLAB_TOKEN` already exists, the script leaves it unchanged. To rotate it:

```bash
CURSOR_API_KEY=... scripts/bootstrap_cursor_gitlab.sh \
  --target-group apps \
  --rotate-bot-token
```

Use `--token-expires-at YYYY-MM-DD` to control the expiration date for newly-created bot tokens.

## Webhook behavior

Target project webhooks point at the central kit trigger endpoint:

```text
http://192.168.200.35/api/v4/projects/<kit-project-id>/ref/<kit-ref>/trigger/pipeline?token=<trigger-token>
```

Only Note Hook events are enabled. The kit pipeline must parse `TRIGGER_PAYLOAD` and ignore comments that are not commands.

## Safety model

- No force-push is configured.
- No auto-merge is configured.
- Existing target project CI/CD files are not modified.
- Existing `GITLAB_TOKEN` is not overwritten unless `--rotate-bot-token` is passed.
- The script uses generated tokens and does not store static passwords in the repository.
