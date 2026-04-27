#!/usr/bin/env bash
# shellcheck shell=bash
# approve-compound-bash — PreToolUse hook for Claude Code
#
# Started from the oryband script, then adapted for this repo.
# Local hardening: commands containing shell redirection operators fall through
# to Claude's native prompt so read-only prefixes do not silently approve writes.
#
# Dependencies: bash 3.2+, shfmt, jq

set -uo pipefail

DEBUG=false
readonly ALLOW_JSON='{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'

allowed_prefixes=()
denied_prefixes=()
stripped_candidates=()
parsed_commands=()

debug() { if $DEBUG; then printf '[approve-compound] %s\n' "$*" >&2; fi; }
approve() { printf '%s\n' "$ALLOW_JSON"; exit 0; }
deny() {
  jq -n --arg msg "$1" '{
    hookSpecificOutput: {hookEventName:"PreToolUse", permissionDecision:"deny"},
    systemMessage: $msg
  }' >&2
  exit 2
}

find_git_root() {
  local toplevel git_dir git_common_dir
  toplevel=$(git rev-parse --show-toplevel 2>/dev/null) || return
  git_dir=$(git rev-parse --git-dir 2>/dev/null)
  git_common_dir=$(git rev-parse --git-common-dir 2>/dev/null)
  if [[ "$git_dir" != "$git_common_dir" ]]; then
    dirname "$git_common_dir"
  else
    printf '%s\n' "$toplevel"
  fi
}

load_prefixes() {
  local git_root line
  git_root=$(find_git_root 2>/dev/null || true)

  allowed_prefixes=()
  denied_prefixes=()

  local files=(
    "$HOME/.claude/settings.json"
    "$HOME/.claude/settings.local.json"
  )
  if [[ -n "$git_root" ]]; then
    files+=("$git_root/.claude/settings.json" "$git_root/.claude/settings.local.json")
  else
    files+=(".claude/settings.json" ".claude/settings.local.json")
  fi

  while IFS= read -r line; do
    case "$line" in
      allow:*) allowed_prefixes+=("${line#allow:}") ;;
      deny:*) denied_prefixes+=("${line#deny:}") ;;
    esac
  done < <(
    for file in "${files[@]}"; do
      [[ -f "$file" ]] || continue
      debug "Reading prefixes from: $file"
      jq -r '
        def extract_prefix: sub("^Bash\\("; "") | sub("( \\*|\\*|:\\*)\\)$"; "") | sub("\\)$"; "");
        (.permissions.allow[]? // empty | select(startswith("Bash(")) | "allow:" + extract_prefix),
        (.permissions.deny[]?  // empty | select(startswith("Bash(")) | "deny:"  + extract_prefix)
      ' "$file" 2>/dev/null || true
    done | sort -u
  )
}

needs_compound_parse() {
  # shellcheck disable=SC2016  # $( is a literal pattern, not an expansion
  [[ "$1" == *['|&;`<>']* || "$1" == *'$('* || "$1" == *'<('* || "$1" == *'>('* ]]
}

read -r -d '' SHFMT_AST_FILTER << 'JQEOF' || true
def get_part_value:
  if (type == "object" | not) then ""
  elif .Type == "Lit" then .Value // ""
  elif .Type == "DblQuoted" then
    "\"" + ([.Parts[]? | get_part_value] | join("")) + "\""
  elif .Type == "SglQuoted" then
    "'" + (.Value // "") + "'"
  elif .Type == "ParamExp" then
    "$" + (.Param.Value // "")
  elif .Type == "CmdSubst" then "$(..)"
  else ""
  end;

def find_cmd_substs:
  if type == "object" then
    if .Type == "CmdSubst" or .Type == "ProcSubst" then .
    elif .Type == "DblQuoted" then .Parts[]? | find_cmd_substs
    elif .Type == "ParamExp" then
      (.Exp?.Word | find_cmd_substs),
      (.Repl?.Orig | find_cmd_substs),
      (.Repl?.With | find_cmd_substs)
    elif .Parts then .Parts[]? | find_cmd_substs
    else empty
    end
  elif type == "array" then .[] | find_cmd_substs
  else empty
  end;

def get_arg_value:
  [.Parts[]? | get_part_value] | join("");

def get_command_string:
  if .Type == "CallExpr" and .Args then
    [.Args[] | get_arg_value] | map(select(length > 0)) | join(" ")
  else empty
  end;

def extract_commands:
  if type == "object" then
    if .Type == "CallExpr" then
      get_command_string,
      (.Args[]? | find_cmd_substs | .Stmts[]? | extract_commands),
      (.Assigns[]?.Value | find_cmd_substs | .Stmts[]? | extract_commands),
      (.Assigns[]?.Array?.Elems[]?.Value | find_cmd_substs | .Stmts[]? | extract_commands),
      (.Redirs[]?.Word | find_cmd_substs | .Stmts[]? | extract_commands)
    elif .Type == "BinaryCmd" then
      (.X | extract_commands), (.Y | extract_commands)
    elif .Type == "Subshell" or .Type == "Block" then
      (.Stmts[]? | extract_commands)
    elif .Type == "CmdSubst" then
      (.Stmts[]? | extract_commands)
    elif .Type == "IfClause" then
      (.Cond[]? | extract_commands),
      (.Then[]? | extract_commands),
      (.Else | extract_commands)
    elif .Type == "WhileClause" or .Type == "UntilClause" then
      (.Cond[]? | extract_commands), (.Do[]? | extract_commands)
    elif .Type == "ForClause" then
      (.Loop.Items[]? | find_cmd_substs | .Stmts[]? | extract_commands),
      (.Do[]? | extract_commands)
    elif .Type == "CaseClause" then
      (.Items[]?.Stmts[]? | extract_commands)
    elif .Type == "DeclClause" then
      (.Args[]?.Value | find_cmd_substs | .Stmts[]? | extract_commands),
      (.Args[]?.Array?.Elems[]?.Value | find_cmd_substs | .Stmts[]? | extract_commands)
    elif .Cmd then
      (.Cmd | extract_commands),
      (.Redirs[]?.Word | find_cmd_substs | .Stmts[]? | extract_commands)
    elif .Stmts then
      (.Stmts[] | extract_commands)
    else
      (.[] | extract_commands)
    end
  elif type == "array" then
    (.[] | extract_commands)
  else empty
  end;

extract_commands | select(length > 0)
JQEOF
readonly SHFMT_AST_FILTER

parse_compound() {
  local cmd="$1"
  local ast raw_commands line

  if [[ "$cmd" == *"=~"* ]]; then
    cmd=$(sed -E 's/\[\[[[:space:]]*\\?![[:space:]]+(.+)[[:space:]]+=~/! [[ \1 =~/g' <<< "$cmd")
  fi

  if ! ast=$(shfmt -ln bash -tojson <<< "$cmd" 2>/dev/null); then
    debug "shfmt parse failed"
    return 1
  fi

  raw_commands=$(jq -r "$SHFMT_AST_FILTER" <<< "$ast" 2>/dev/null) || return 1

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    if [[ "$line" =~ ^(env[[:space:]]+)?(/[^[:space:]]*/)?((ba)?sh)[[:space:]]+-c[[:space:]]*[\'\"](.*)[\'\"]$ ]]; then
      debug "Recursing into shell -c: ${BASH_REMATCH[5]}"
      if ! parse_compound "${BASH_REMATCH[5]}"; then
        printf '%s\0' "$line"
      fi
    else
      printf '%s\0' "$line"
    fi
  done <<< "$raw_commands"
}

collect_parsed_commands() {
  local input_command="$1"
  local parsed_command

  parsed_commands=()
  while IFS= read -r -d '' parsed_command; do
    parsed_commands+=("$parsed_command")
  done < <(parse_compound "$input_command")
}

# normalize_git_globals — strip git's global flags so the *subcommand* is what
# gets matched against the allowlist. Examples:
#   git -C /path status         -> git status
#   git -c user.email=x commit  -> git commit
#   git --git-dir=foo log       -> git log
# The first non-flag token is the subcommand, so a destructive verb like `rm`
# stays visible to the matcher: `git -C /path rm` -> `git rm` (not allow-matched).
normalize_git_globals() {
  local cmd="$1"
  if [[ "$cmd" != "git "* ]]; then
    printf '%s\n' "$cmd"
    return
  fi

  local -a tokens=()
  read -r -a tokens <<< "$cmd"

  local i=1 n=${#tokens[@]}
  while (( i < n )); do
    case "${tokens[i]}" in
      # Globals that take a separate value token
      -C|-c|--git-dir|--work-tree|--namespace|--super-prefix|--exec-path|--config-env|--attr-source)
        (( i += 2 ))
        ;;
      # Globals with =value form
      --git-dir=*|--work-tree=*|--namespace=*|--super-prefix=*|--exec-path=*|--config-env=*|--attr-source=*|--list-cmds=*)
        (( i += 1 ))
        ;;
      # Boolean globals
      -p|-P|--paginate|--no-pager|--bare|--no-replace-objects|--no-lazy-fetch|--no-optional-locks|--no-advice|--html-path|--man-path|--info-path)
        (( i += 1 ))
        ;;
      *)
        # First non-global token = subcommand. Emit it and the rest verbatim.
        printf 'git %s\n' "${tokens[*]:i}"
        return
        ;;
    esac
  done
  printf 'git\n'
}

strip_env_vars() {
  local full_command="$1"
  local stripped="$full_command"

  while [[ "$stripped" =~ ^[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+(.*) ]]; do
    stripped="${BASH_REMATCH[1]}"
  done

  stripped_candidates=("$full_command")
  [[ "$stripped" != "$full_command" ]] && stripped_candidates+=("$stripped")

  # Also try git-globals-normalized forms for each candidate, so allowlist
  # entries like `Bash(git status)` cover `git -C /path status` too.
  local original_count=${#stripped_candidates[@]} idx cand normalized
  for (( idx = 0; idx < original_count; idx++ )); do
    cand="${stripped_candidates[idx]}"
    normalized=$(normalize_git_globals "$cand")
    [[ "$normalized" != "$cand" ]] && stripped_candidates+=("$normalized")
  done
}

matches_prefix_list() {
  local full_command="$1"
  local list_name="$2"
  local label="${3:-$list_name}"
  local cmd prefix

  case "$list_name" in
    allow) [[ ${#allowed_prefixes[@]} -eq 0 ]] && return 1 ;;
    deny) [[ ${#denied_prefixes[@]} -eq 0 ]] && return 1 ;;
    *) return 1 ;;
  esac

  strip_env_vars "$full_command"

  for cmd in "${stripped_candidates[@]}"; do
    if [[ "$list_name" == "allow" ]]; then
      for prefix in "${allowed_prefixes[@]}"; do
        if [[ "$cmd" == "$prefix" ]] || [[ "$cmd" == "$prefix "* ]] || [[ "$cmd" == "$prefix/"* ]]; then
          debug "MATCH ($label): '$cmd' -> '$prefix'"
          return 0
        fi
      done
    else
      for prefix in "${denied_prefixes[@]}"; do
        if [[ "$cmd" == "$prefix" ]] || [[ "$cmd" == "$prefix "* ]] || [[ "$cmd" == "$prefix/"* ]]; then
          debug "MATCH ($label): '$cmd' -> '$prefix'"
          return 0
        fi
      done
    fi
  done
  return 1
}

is_allowed() {
  local cmd="$1"
  if matches_prefix_list "$cmd" deny "deny"; then
    return 1
  fi
  matches_prefix_list "$cmd" allow "allow"
}

all_allowed() {
  local cmd

  for cmd in "$@"; do
    [[ -z "$cmd" ]] && continue
    if ! is_allowed "$cmd"; then
      debug "Not all commands approved"
      return 1
    fi
  done
  return 0
}

any_denied() {
  local cmd

  [[ ${#denied_prefixes[@]} -eq 0 ]] && return 1

  for cmd in "$@"; do
    [[ -z "$cmd" ]] && continue
    if matches_prefix_list "$cmd" deny "deny"; then
      debug "Denied segment found: $cmd"
      return 0
    fi
  done
  return 1
}

main() {
  local permissions_json="" deny_json="" mode="hook"
  local line cmd c input command

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --debug) DEBUG=true; shift ;;
      --permissions) permissions_json="$2"; shift 2 ;;
      --deny) deny_json="$2"; shift 2 ;;
      parse) mode="parse"; shift ;;
      *) shift ;;
    esac
  done

  for dep in jq shfmt; do
    if ! command -v "$dep" >/dev/null 2>&1; then
      debug "Missing $dep, falling through"
      exit 0
    fi
  done

  if [[ "$mode" == "parse" ]]; then
    cmd=$(cat)
    [[ -z "$cmd" ]] && exit 0
    if ! needs_compound_parse "$cmd"; then
      printf '%s\n' "$cmd"
    else
      collect_parsed_commands "$cmd"
      for c in "${parsed_commands[@]}"; do
        [[ -n "$c" ]] && printf '%s\n' "$c"
      done
    fi
    exit 0
  fi

  input=$(cat)
  command=$(jq -r '.tool_input.command // empty' <<< "$input")
  [[ -z "$command" ]] && exit 0

  debug "Command: $command"

  allowed_prefixes=()
  denied_prefixes=()
  if [[ -n "$permissions_json" ]]; then
    while IFS= read -r line; do
      [[ -n "$line" ]] && allowed_prefixes+=("$line")
    done < <(jq -r '.[] | sub("^Bash\\("; "") | sub("( \\*|\\*|:\\*)\\)$"; "") | sub("\\)$"; "")' <<< "$permissions_json" 2>/dev/null)
    if [[ -n "$deny_json" ]]; then
      while IFS= read -r line; do
        [[ -n "$line" ]] && denied_prefixes+=("$line")
      done < <(jq -r '.[] | sub("^Bash\\("; "") | sub("( \\*|\\*|:\\*)\\)$"; "") | sub("\\)$"; "")' <<< "$deny_json" 2>/dev/null)
    fi
  else
    load_prefixes
  fi
  debug "Loaded ${#allowed_prefixes[@]} allow, ${#denied_prefixes[@]} deny prefixes"
  [[ ${#allowed_prefixes[@]} -eq 0 ]] && exit 0

  if ! needs_compound_parse "$command"; then
    debug "Simple command"
    is_allowed "$command" && approve
    exit 0
  fi

  debug "Compound command"
  collect_parsed_commands "$command"

  [[ ${#parsed_commands[@]} -eq 0 || -z "${parsed_commands[0]}" ]] && exit 0

  all_allowed "${parsed_commands[@]}" && approve

  any_denied "${parsed_commands[@]}" && deny "Compound command contains a denied sub-command"
  exit 0
}

main "$@"
