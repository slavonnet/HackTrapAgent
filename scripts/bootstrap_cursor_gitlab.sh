#!/usr/bin/env bash
set -euo pipefail

gitlab_url="http://192.168.200.35"
kit_project_path="infra/cursor-agent-kit"
kit_ref="main"
bot_username="cursor-bot"
bot_name="Cursor Agent Bot"
bot_email="cursor-bot@example.local"
bot_token_name="cursor-agent-bot"
trigger_description="cursor-agent-note-webhook"
webhook_name="Cursor Agent note trigger"
visibility="private"
token_expires_at=""
ssl_verify="false"
dry_run=0
rotate_bot_token=0
all_projects=0
include_subgroups=1
target_projects=()
target_groups=()

usage() {
  cat <<'USAGE'
Bootstrap Cursor Agent automation for a GitLab Self-Managed instance.

The script expects that you have already authenticated glab as an instance admin:

  glab auth login --hostname 192.168.200.35

Default setup:
  - GitLab URL: http://192.168.200.35
  - kit project: infra/cursor-agent-kit
  - bot user: cursor-bot

What it configures:
  - Ensures the infra group and cursor-agent-kit project exist.
  - Ensures a cursor-bot user exists.
  - Creates a bot PAT if the kit project does not already have GITLAB_TOKEN,
    then stores it as a masked CI/CD variable in the kit project.
  - Stores CURSOR_API_KEY as a masked CI/CD variable if CURSOR_API_KEY is set
    in the local environment.
  - Creates or reuses a pipeline trigger token in the kit project.
  - Installs Note Hook webhooks in target projects so Issue/MR comments trigger
    the central kit pipeline.
  - Adds cursor:* labels to target projects.
  - Adds the bot as Owner on target groups and Maintainer on target projects.

Examples:
  scripts/bootstrap_cursor_gitlab.sh \
    --target-project my-group/my-project

  CURSOR_API_KEY=... scripts/bootstrap_cursor_gitlab.sh \
    --target-group apps

  scripts/bootstrap_cursor_gitlab.sh \
    --all-projects

Options:
  --gitlab-url URL              GitLab base URL. Default: http://192.168.200.35
  --kit-project PATH            Central kit project path. Default: infra/cursor-agent-kit
  --kit-ref REF                 Ref used to trigger the kit pipeline. Default: main
  --target-project PATH         Configure one project. Can be repeated.
  --target-group PATH           Configure all projects in a group. Can be repeated.
  --all-projects                Configure all visible projects on the instance.
  --no-include-subgroups        Do not include subgroup projects for --target-group.
  --bot-username USERNAME       Bot username. Default: cursor-bot
  --bot-email EMAIL             Bot email. Default: cursor-bot@example.local
  --token-expires-at YYYY-MM-DD Expiration date for newly-created bot PAT.
  --rotate-bot-token            Create a new bot PAT and overwrite GITLAB_TOKEN.
  --ssl-verify true|false       Webhook SSL verification flag. Default: false.
  --visibility private|internal Visibility for created groups/projects. Default: private
  --dry-run                     Show planned mutations without changing GitLab.
  -h, --help                    Show this help.

Notes:
  - Existing project CI/CD is not modified.
  - The direct webhook mode intentionally runs the central kit pipeline, not the
    target project's normal build/release pipeline.
  - The kit pipeline should parse TRIGGER_PAYLOAD and ignore comments that do
    not contain /cursor or @cursor-bot.
USAGE
}

log() {
  printf '[cursor-bootstrap] %s\n' "$*" >&2
}

warn() {
  printf '[cursor-bootstrap] WARNING: %s\n' "$*" >&2
}

die() {
  printf '[cursor-bootstrap] ERROR: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

urlencode() {
  python3 - "$1" <<'PY'
import sys
import urllib.parse

print(urllib.parse.quote(sys.argv[1], safe=""))
PY
}

random_token() {
  python3 - <<'PY'
import secrets

print(secrets.token_urlsafe(32))
PY
}

default_expiry() {
  python3 - <<'PY'
from datetime import date, timedelta

print((date.today() + timedelta(days=365)).isoformat())
PY
}

normalize_gitlab_url() {
  gitlab_url="${gitlab_url%/}"
  gitlab_hostname="${gitlab_url#http://}"
  gitlab_hostname="${gitlab_hostname#https://}"
  gitlab_hostname="${gitlab_hostname%%/*}"
}

api() {
  glab api --hostname "$gitlab_hostname" "$@"
}

api_maybe() {
  api "$@" 2>/dev/null || true
}

mutate_api() {
  if [[ "$dry_run" == "1" ]]; then
    log "DRY RUN: glab api $*"
    return 0
  fi
  api "$@"
}

json_get() {
  jq -r "$1 // empty"
}

ensure_group() {
  local group_path="$1"
  local current=""
  local parent_id=""
  local part
  local encoded
  local response
  local group_id

  IFS='/' read -ra parts <<< "$group_path"
  for part in "${parts[@]}"; do
    [[ -n "$part" ]] || continue
    if [[ -n "$current" ]]; then
      current="${current}/${part}"
    else
      current="$part"
    fi

    encoded="$(urlencode "$current")"
    response="$(api_maybe "groups/${encoded}?with_projects=false")"
    group_id="$(jq -r '.id // empty' <<< "$response" 2>/dev/null || true)"
    if [[ -n "$group_id" ]]; then
      log "Group exists: ${current} (${group_id})"
      parent_id="$group_id"
      continue
    fi

    log "Creating group: ${current}"
    if [[ "$dry_run" == "1" ]]; then
      parent_id="0"
      continue
    fi

    if [[ -n "$parent_id" ]]; then
      response="$(mutate_api -X POST groups \
        -f "name=${part}" \
        -f "path=${part}" \
        -f "parent_id=${parent_id}" \
        -f "visibility=${visibility}")"
    else
      response="$(mutate_api -X POST groups \
        -f "name=${part}" \
        -f "path=${part}" \
        -f "visibility=${visibility}")"
    fi
    parent_id="$(jq -r '.id' <<< "$response")"
  done

  [[ -n "$parent_id" ]] || die "Could not resolve group: ${group_path}"
  printf '%s\n' "$parent_id"
}

ensure_project() {
  local project_path="$1"
  local encoded
  local response
  local project_id
  local namespace_path
  local project_slug
  local namespace_id

  encoded="$(urlencode "$project_path")"
  response="$(api_maybe "projects/${encoded}")"
  project_id="$(jq -r '.id // empty' <<< "$response" 2>/dev/null || true)"
  if [[ -n "$project_id" ]]; then
    log "Project exists: ${project_path} (${project_id})"
    printf '%s\n' "$project_id"
    return 0
  fi

  [[ "$project_path" == */* ]] || die "Project path must include a group: ${project_path}"
  namespace_path="${project_path%/*}"
  project_slug="${project_path##*/}"
  namespace_id="$(ensure_group "$namespace_path")"

  log "Creating project: ${project_path}"
  if [[ "$dry_run" == "1" ]]; then
    printf '0\n'
    return 0
  fi

  response="$(mutate_api -X POST projects \
    -f "name=${project_slug}" \
    -f "path=${project_slug}" \
    -f "namespace_id=${namespace_id}" \
    -f "visibility=${visibility}" \
    -f "initialize_with_readme=true" \
    -f "issues_access_level=enabled" \
    -f "merge_requests_access_level=enabled" \
    -f "builds_access_level=enabled" \
    -f "snippets_access_level=disabled")"
  jq -r '.id' <<< "$response"
}

ensure_bot_user() {
  local response
  local user_id

  response="$(api_maybe "users?username=$(urlencode "$bot_username")")"
  user_id="$(jq -r '.[0].id // empty' <<< "$response" 2>/dev/null || true)"
  if [[ -n "$user_id" ]]; then
    log "Bot user exists: ${bot_username} (${user_id})"
    printf '%s\n' "$user_id"
    return 0
  fi

  log "Creating bot user: ${bot_username}"
  if [[ "$dry_run" == "1" ]]; then
    printf '0\n'
    return 0
  fi

  response="$(mutate_api -X POST users \
    -f "username=${bot_username}" \
    -f "name=${bot_name}" \
    -f "email=${bot_email}" \
    -f "force_random_password=true" \
    -f "skip_confirmation=true" \
    -f "can_create_group=false" \
    -f "projects_limit=0")"
  jq -r '.id' <<< "$response"
}

project_variable_exists() {
  local project_id="$1"
  local key="$2"
  local response

  response="$(api_maybe "projects/${project_id}/variables/${key}")"
  jq -e '.key' <<< "$response" >/dev/null 2>&1
}

set_project_variable() {
  local project_id="$1"
  local key="$2"
  local value="$3"
  local masked="$4"
  local protected="${5:-false}"
  local description="${6:-Managed by scripts/bootstrap_cursor_gitlab.sh}"

  if [[ -z "$value" ]]; then
    warn "Skipping empty variable ${key}"
    return 0
  fi

  if project_variable_exists "$project_id" "$key"; then
    log "Updating CI/CD variable ${key} in project ${project_id}"
    mutate_api -X PUT "projects/${project_id}/variables/${key}" \
      -f "value=${value}" \
      -f "masked=${masked}" \
      -f "protected=${protected}" \
      -f "raw=true" \
      -f "variable_type=env_var" \
      -f "description=${description}" >/dev/null
  else
    log "Creating CI/CD variable ${key} in project ${project_id}"
    mutate_api -X POST "projects/${project_id}/variables" \
      -f "key=${key}" \
      -f "value=${value}" \
      -f "masked=${masked}" \
      -f "protected=${protected}" \
      -f "raw=true" \
      -f "variable_type=env_var" \
      -f "description=${description}" >/dev/null
  fi
}

ensure_bot_token_variable() {
  local kit_project_id="$1"
  local bot_user_id="$2"
  local response
  local token

  if [[ "$rotate_bot_token" != "1" ]] && project_variable_exists "$kit_project_id" "GITLAB_TOKEN"; then
    log "Kit project already has GITLAB_TOKEN; keeping existing token"
    return 0
  fi

  log "Creating a new PAT for ${bot_username} and storing it as masked GITLAB_TOKEN"
  if [[ "$dry_run" == "1" ]]; then
    log "DRY RUN: would create bot PAT and update GITLAB_TOKEN"
    return 0
  fi

  response="$(mutate_api -X POST "users/${bot_user_id}/personal_access_tokens" \
    -f "name=${bot_token_name}" \
    -f "description=Cursor Agent GitLab automation token" \
    -f "expires_at=${token_expires_at}" \
    -f "scopes[]=api" \
    -f "scopes[]=read_repository" \
    -f "scopes[]=write_repository")"
  token="$(jq -r '.token // empty' <<< "$response")"
  [[ -n "$token" ]] || die "GitLab did not return the created bot PAT"
  set_project_variable "$kit_project_id" "GITLAB_TOKEN" "$token" "true" "false" \
    "Bot PAT used by Cursor Agent jobs"
}

ensure_trigger_token() {
  local kit_project_id="$1"
  local response
  local existing
  local existing_token
  local token

  response="$(api_maybe "projects/${kit_project_id}/triggers")"
  existing="$(jq -r --arg desc "$trigger_description" '.[]? | select(.description == $desc) | @base64' <<< "$response" 2>/dev/null | head -n 1 || true)"
  if [[ -n "$existing" ]]; then
    existing_token="$(printf '%s' "$existing" | base64 -d | jq -r '.token // empty')"
    if [[ "${#existing_token}" -gt 8 ]]; then
      log "Reusing existing pipeline trigger token: ${trigger_description}"
      printf '%s\n' "$existing_token"
      return 0
    fi
    warn "Existing trigger token is not fully visible to this user; creating a new one"
  fi

  log "Creating pipeline trigger token in kit project"
  if [[ "$dry_run" == "1" ]]; then
    printf 'dry-run-token\n'
    return 0
  fi

  response="$(mutate_api -X POST "projects/${kit_project_id}/triggers" \
    -f "description=${trigger_description}")"
  token="$(jq -r '.token // empty' <<< "$response")"
  [[ -n "$token" ]] || die "GitLab did not return the created pipeline trigger token"
  printf '%s\n' "$token"
}

ensure_group_member() {
  local group_id="$1"
  local user_id="$2"
  local response
  local access_level

  response="$(api_maybe "groups/${group_id}/members/all/${user_id}")"
  access_level="$(jq -r '.access_level // 0' <<< "$response" 2>/dev/null || true)"
  if [[ "$access_level" =~ ^[0-9]+$ ]] && (( access_level >= 50 )); then
    log "Bot already has Owner access to group ${group_id}"
    return 0
  fi

  log "Granting bot Owner access to group ${group_id}"
  if [[ "$dry_run" == "1" ]]; then
    return 0
  fi

  if ! mutate_api -X POST "groups/${group_id}/members" \
    -f "user_id=${user_id}" \
    -f "access_level=50" >/dev/null 2>&1; then
    mutate_api -X PUT "groups/${group_id}/members/${user_id}" \
      -f "access_level=50" >/dev/null
  fi
}

ensure_project_member() {
  local project_id="$1"
  local user_id="$2"
  local response
  local access_level

  response="$(api_maybe "projects/${project_id}/members/all/${user_id}")"
  access_level="$(jq -r '.access_level // 0' <<< "$response" 2>/dev/null || true)"
  if [[ "$access_level" =~ ^[0-9]+$ ]] && (( access_level >= 40 )); then
    log "Bot already has Maintainer access to project ${project_id}"
    return 0
  fi

  log "Granting bot Maintainer access to project ${project_id}"
  if [[ "$dry_run" == "1" ]]; then
    return 0
  fi

  if ! mutate_api -X POST "projects/${project_id}/members" \
    -f "user_id=${user_id}" \
    -f "access_level=40" >/dev/null 2>&1; then
    mutate_api -X PUT "projects/${project_id}/members/${user_id}" \
      -f "access_level=40" >/dev/null
  fi
}

ensure_project_label() {
  local project_id="$1"
  local name="$2"
  local color="$3"
  local response

  response="$(api_maybe "projects/${project_id}/labels?search=$(urlencode "$name")")"
  if jq -e --arg name "$name" '.[]? | select(.name == $name)' <<< "$response" >/dev/null 2>&1; then
    log "Label exists in project ${project_id}: ${name}"
    return 0
  fi

  log "Creating label in project ${project_id}: ${name}"
  mutate_api -X POST "projects/${project_id}/labels" \
    -f "name=${name}" \
    -f "color=${color}" >/dev/null || true
}

ensure_project_webhook() {
  local project_id="$1"
  local hook_url="$2"
  local hook_token="$3"
  local response
  local hook_id

  response="$(api_maybe "projects/${project_id}/hooks")"
  hook_id="$(jq -r --arg url "$hook_url" '.[]? | select(.url == $url) | .id' <<< "$response" 2>/dev/null | head -n 1 || true)"

  if [[ -n "$hook_id" ]]; then
    log "Updating Cursor Agent webhook in project ${project_id}"
    mutate_api -X PUT "projects/${project_id}/hooks/${hook_id}" \
      -f "url=${hook_url}" \
      -f "name=${webhook_name}" \
      -f "description=Trigger central Cursor Agent pipeline from Issue/MR notes" \
      -f "token=${hook_token}" \
      -f "note_events=true" \
      -f "confidential_note_events=false" \
      -f "push_events=false" \
      -f "issues_events=false" \
      -f "merge_requests_events=false" \
      -f "tag_push_events=false" \
      -f "job_events=false" \
      -f "pipeline_events=false" \
      -f "wiki_page_events=false" \
      -f "enable_ssl_verification=${ssl_verify}" >/dev/null
  else
    log "Creating Cursor Agent webhook in project ${project_id}"
    mutate_api -X POST "projects/${project_id}/hooks" \
      -f "url=${hook_url}" \
      -f "name=${webhook_name}" \
      -f "description=Trigger central Cursor Agent pipeline from Issue/MR notes" \
      -f "token=${hook_token}" \
      -f "note_events=true" \
      -f "confidential_note_events=false" \
      -f "push_events=false" \
      -f "issues_events=false" \
      -f "merge_requests_events=false" \
      -f "tag_push_events=false" \
      -f "job_events=false" \
      -f "pipeline_events=false" \
      -f "wiki_page_events=false" \
      -f "enable_ssl_verification=${ssl_verify}" >/dev/null
  fi
}

verify_kit_ci_file() {
  local kit_project_id="$1"
  local encoded_file
  local response

  encoded_file="$(urlencode "ci/cursor-agent.gitlab-ci.yml")"
  response="$(api_maybe "projects/${kit_project_id}/repository/files/${encoded_file}?ref=$(urlencode "$kit_ref")")"
  if jq -e '.file_path' <<< "$response" >/dev/null 2>&1; then
    log "Kit CI file exists at ci/cursor-agent.gitlab-ci.yml on ${kit_ref}"
  else
    warn "Could not find ci/cursor-agent.gitlab-ci.yml in ${kit_project_path}@${kit_ref}"
    warn "Create the kit pipeline file before relying on webhooks."
  fi
}

project_id_to_path() {
  local project_id="$1"
  api "projects/${project_id}" | jq -r '.path_with_namespace'
}

collect_projects_from_group() {
  local group_path="$1"
  local group_id
  local include_param

  if [[ "$dry_run" == "1" ]] && ! command -v glab >/dev/null 2>&1; then
    warn "Cannot enumerate group projects in offline dry-run mode: ${group_path}"
    return 0
  fi

  group_id="$(ensure_group "$group_path")"
  include_param="false"
  [[ "$include_subgroups" == "1" ]] && include_param="true"
  api --paginate "groups/${group_id}/projects?include_subgroups=${include_param}&simple=true&per_page=100" \
    | jq -r '.[]?.path_with_namespace'
}

collect_all_projects() {
  if [[ "$dry_run" == "1" ]] && ! command -v glab >/dev/null 2>&1; then
    warn "Cannot enumerate all projects in offline dry-run mode"
    return 0
  fi
  api --paginate "projects?simple=true&per_page=100" | jq -r '.[]?.path_with_namespace'
}

add_unique_project() {
  local path="$1"
  local existing

  for existing in "${resolved_projects[@]}"; do
    [[ "$existing" == "$path" ]] && return 0
  done
  resolved_projects+=("$path")
}

configure_target_project() {
  local project_path="$1"
  local bot_user_id="$2"
  local hook_url="$3"
  local project_id
  local hook_token

  project_id="$(ensure_project "$project_path")"
  ensure_project_member "$project_id" "$bot_user_id"
  ensure_project_label "$project_id" "cursor:running" "#1f75cb"
  ensure_project_label "$project_id" "cursor:needs-input" "#d93f0b"
  ensure_project_label "$project_id" "cursor:done" "#0e8a16"
  ensure_project_label "$project_id" "cursor:failed" "#b60205"
  hook_token="$(random_token)"
  ensure_project_webhook "$project_id" "$hook_url" "$hook_token"
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --gitlab-url)
        gitlab_url="${2:?Missing value for --gitlab-url}"
        shift 2
        ;;
      --kit-project)
        kit_project_path="${2:?Missing value for --kit-project}"
        shift 2
        ;;
      --kit-ref)
        kit_ref="${2:?Missing value for --kit-ref}"
        shift 2
        ;;
      --target-project)
        target_projects+=("${2:?Missing value for --target-project}")
        shift 2
        ;;
      --target-group)
        target_groups+=("${2:?Missing value for --target-group}")
        shift 2
        ;;
      --all-projects)
        all_projects=1
        shift
        ;;
      --no-include-subgroups)
        include_subgroups=0
        shift
        ;;
      --bot-username)
        bot_username="${2:?Missing value for --bot-username}"
        shift 2
        ;;
      --bot-email)
        bot_email="${2:?Missing value for --bot-email}"
        shift 2
        ;;
      --token-expires-at)
        token_expires_at="${2:?Missing value for --token-expires-at}"
        shift 2
        ;;
      --rotate-bot-token)
        rotate_bot_token=1
        shift
        ;;
      --ssl-verify)
        ssl_verify="${2:?Missing value for --ssl-verify}"
        shift 2
        ;;
      --visibility)
        visibility="${2:?Missing value for --visibility}"
        shift 2
        ;;
      --dry-run)
        dry_run=1
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        die "Unknown argument: $1"
        ;;
    esac
  done
}

main() {
  local kit_project_id
  local bot_user_id
  local trigger_token
  local hook_url
  local group_id
  local group_path
  local project_path
  local project_from_group

  parse_args "$@"
  normalize_gitlab_url
  token_expires_at="${token_expires_at:-$(default_expiry)}"

  require_command jq
  require_command python3
  if [[ "$dry_run" != "1" ]]; then
    require_command glab
  elif ! command -v glab >/dev/null 2>&1; then
    warn "glab is not installed; offline dry-run will use placeholder IDs"
  fi

  if [[ "$ssl_verify" != "true" && "$ssl_verify" != "false" ]]; then
    die "--ssl-verify must be true or false"
  fi

  if [[ "$dry_run" != "1" ]]; then
    glab auth status --hostname "$gitlab_hostname" >/dev/null
  else
    log "Dry-run mode is enabled"
  fi

  log "GitLab URL: ${gitlab_url}"
  log "Kit project: ${kit_project_path}"

  kit_project_id="$(ensure_project "$kit_project_path")"
  bot_user_id="$(ensure_bot_user)"

  ensure_bot_token_variable "$kit_project_id" "$bot_user_id"
  set_project_variable "$kit_project_id" "GITLAB_HOST" "$gitlab_url" "false" "false" \
    "GitLab instance URL"
  set_project_variable "$kit_project_id" "CURSOR_BOT_USERNAME" "$bot_username" "false" "false" \
    "GitLab username ignored by agent triggers"
  set_project_variable "$kit_project_id" "CURSOR_AGENT_KIT_PROJECT" "$kit_project_path" "false" "false" \
    "Central Cursor Agent kit project path"

  if [[ -n "${CURSOR_API_KEY:-}" ]]; then
    set_project_variable "$kit_project_id" "CURSOR_API_KEY" "$CURSOR_API_KEY" "true" "false" \
      "Cursor API key used by headless agent jobs"
  else
    warn "CURSOR_API_KEY is not set locally; skipping kit CI variable CURSOR_API_KEY"
  fi

  verify_kit_ci_file "$kit_project_id"
  trigger_token="$(ensure_trigger_token "$kit_project_id")"
  hook_url="${gitlab_url}/api/v4/projects/${kit_project_id}/ref/$(urlencode "$kit_ref")/trigger/pipeline?token=${trigger_token}"

  resolved_projects=()
  for project_path in "${target_projects[@]}"; do
    add_unique_project "$project_path"
  done

  for group_path in "${target_groups[@]}"; do
    group_id="$(ensure_group "$group_path")"
    ensure_group_member "$group_id" "$bot_user_id"
    while IFS= read -r project_from_group; do
      [[ -n "$project_from_group" ]] && add_unique_project "$project_from_group"
    done < <(collect_projects_from_group "$group_path")
  done

  if [[ "$all_projects" == "1" ]]; then
    while IFS= read -r project_path; do
      [[ -n "$project_path" ]] && add_unique_project "$project_path"
    done < <(collect_all_projects)
  fi

  if [[ "${#resolved_projects[@]}" -eq 0 ]]; then
    warn "No target projects were selected. Use --target-project, --target-group, or --all-projects."
  else
    for project_path in "${resolved_projects[@]}"; do
      configure_target_project "$project_path" "$bot_user_id" "$hook_url"
    done
  fi

  log "Bootstrap complete"
  log "Next check: comment '/cursor help' in a configured Issue or Merge Request."
}

main "$@"
