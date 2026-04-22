#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
CLAUDE_SRC_DIR="$DOTFILES_DIR/claude"
CLAUDE_DST_DIR="$HOME/.claude"
CLAUDE_SCRIPTS_DST="$CLAUDE_DST_DIR/scripts"
CLAUDE_BACKUP_DIR="$CLAUDE_DST_DIR/backup"
BASE_JSON="$CLAUDE_SRC_DIR/settings.base.json"
LOCAL_JSON="$CLAUDE_DST_DIR/settings.local.json"
TARGET_JSON="$CLAUDE_DST_DIR/settings.json"
HOOK_SRC="$CLAUDE_SRC_DIR/scripts/approve-compound-bash.sh"
HOOK_DST="$CLAUDE_SCRIPTS_DST/approve-compound-bash.sh"

info() {
  printf "\033[1;34m▸ %s\033[0m\n" "$*"
}

warn() {
  printf "\033[1;33m⚠ %s\033[0m\n" "$*"
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf "Missing required command: %s\n" "$1" >&2
    exit 1
  fi
}

require_file() {
  if [[ ! -f "$1" ]]; then
    printf "Missing required file: %s\n" "$1" >&2
    exit 1
  fi
}

dedupe_append() {
  jq -s '
    def uniq_preserve_order:
      reduce .[] as $item ([]; if index($item) == null then . + [$item] else . end);

    def deep_merge($left; $right):
      if ($left | type) == "object" and ($right | type) == "object" then
        reduce (($left | keys_unsorted) + ($right | keys_unsorted) | unique[]) as $key
          ({};
            .[$key] =
              if ($left | has($key)) and ($right | has($key)) then
                deep_merge($left[$key]; $right[$key])
              elif $right | has($key) then
                $right[$key]
              else
                $left[$key]
              end
          )
      elif ($left | type) == "array" and ($right | type) == "array" then
        ($left + $right) | uniq_preserve_order
      else
        $right
      end;

    reduce .[] as $item ({}; deep_merge(.; $item))
  ' "$@"
}

main() {
  require_command jq
  require_file "$BASE_JSON"
  require_file "$HOOK_SRC"

  mkdir -p "$CLAUDE_DST_DIR" "$CLAUDE_SCRIPTS_DST" "$CLAUDE_BACKUP_DIR"
  chmod +x "$HOOK_SRC"
  ln -sfn "$HOOK_SRC" "$HOOK_DST"

  local os_json=""
  case "$(uname -s)" in
    Darwin) os_json="$CLAUDE_SRC_DIR/settings.mac.json" ;;
    Linux) os_json="$CLAUDE_SRC_DIR/settings.linux.json" ;;
  esac

  local -a merge_inputs=("$BASE_JSON")
  if [[ -n "$os_json" && -f "$os_json" ]]; then
    merge_inputs+=("$os_json")
  fi
  if [[ -f "$LOCAL_JSON" ]]; then
    merge_inputs+=("$LOCAL_JSON")
  fi

  local tmp
  tmp="$(mktemp)"
  dedupe_append "${merge_inputs[@]}" >"$tmp"

  if [[ -f "$TARGET_JSON" ]] && ! cmp -s "$TARGET_JSON" "$tmp"; then
    local backup_file
    backup_file="$CLAUDE_BACKUP_DIR/settings.json.$(date +%Y%m%d-%H%M%S)"
    cp "$TARGET_JSON" "$backup_file"
    info "Backed up existing settings to $backup_file"
  fi

  mv "$tmp" "$TARGET_JSON"

  if ! command -v shfmt >/dev/null 2>&1; then
    warn "shfmt is not installed; the compound Bash hook will fall through until it is available"
  fi

  info "Installed Claude settings to $TARGET_JSON"
  info "Linked hook script at $HOOK_DST"
  info "Local per-machine overrides can live in $LOCAL_JSON"
}

main "$@"
