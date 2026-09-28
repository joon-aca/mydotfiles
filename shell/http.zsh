# zsh-only httpie-style curl wrapper. Sourced from .zshrc.
# Bash keeps the http-get / http-post aliases in aliases.zsh.

# Usage: http [METHOD] URL [ITEM ...]
#
# ITEM types:
#   key==val    URL query parameter
#   key:=val    raw JSON value (number, bool, array, object)
#   key=val     JSON string field
#   Key:val     HTTP header
#   :PORT/path  localhost shorthand  →  http://localhost:PORT/path
#
# Flags: -v / --verbose  (pass -v to curl, shows headers)
#
# Examples:
#   http httpbin.org/get
#   http POST httpbin.org/post name=Alice age:=30 active:=true
#   http httpbin.org/get q==zsh lang==en
#   http PUT httpbin.org/put Authorization:"Bearer tok" field=val
#   http :8080/api/users
http() {
  local method="" url="" verbose=0
  local -a curl_headers=() query_params=() json_fields=()

  for arg in "$@"; do
    case "$arg" in
      -v|--verbose) verbose=1 ;;
      GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS) method="$arg" ;;
      http://*|https://*) url="$arg" ;;
      *)
        if [[ "$arg" == *'=='* ]]; then
          query_params+=("${arg%%==*}=${arg#*==}")
        elif [[ "$arg" == *':='* ]]; then
          json_fields+=("\"${arg%%:=*}\":${arg#*:=}")
        elif [[ "$arg" == *'='* && "${arg%%=*}" != *':'* ]]; then
          local _k="${arg%%=*}" _v="${arg#*=}"
          json_fields+=("\"${_k}\":\"${_v//\"/\\\"}\"")
        elif [[ "$arg" =~ '^:[0-9]' || "$arg" == ':/'* ]]; then
          url="http://localhost${arg}"
        elif [[ "$arg" == *':'* ]]; then
          curl_headers+=("${arg%%:*}: ${arg#*:}")
        else
          url="$arg"
        fi ;;
    esac
  done

  if [[ -z "$url" ]]; then
    echo "Usage: http [METHOD] URL [key=val ...] [Key:Val ...]" >&2
    return 1
  fi

  # Auto-add scheme for bare URLs (e.g. httpbin.org/get)
  [[ "$url" != http://* && "$url" != https://* ]] && url="http://$url"

  # Default method: POST if body fields present, otherwise GET
  [[ -z "$method" ]] && { [[ ${#json_fields[@]} -gt 0 ]] && method="POST" || method="GET"; }

  # Append query params
  if [[ ${#query_params[@]} -gt 0 ]]; then
    local qs="${(j:&:)query_params}"
    [[ "$url" == *'?'* ]] && url="${url}&${qs}" || url="${url}?${qs}"
  fi

  local -a cmd=("curl" "-sS" "-X" "$method")
  [[ $verbose -eq 1 ]] && cmd+=("-v")
  for h in "${curl_headers[@]}"; do cmd+=("-H" "$h"); done
  if [[ ${#json_fields[@]} -gt 0 ]]; then
    cmd+=("-H" "Content-Type: application/json" "-d" "{${(j:,:)json_fields}}")
  fi
  cmd+=("$url")

  if [[ $verbose -eq 1 ]]; then
    "${cmd[@]}"
  elif command -v jq >/dev/null 2>&1; then
    local out; out=$("${cmd[@]}") || return $?
    printf '%s\n' "$out" | jq '.' 2>/dev/null || printf '%s\n' "$out"
  else
    "${cmd[@]}"
  fi
}

# https - same as http but ensures the URL uses https://
https() {
  local -a args=(); local saw_url=0
  for arg in "$@"; do
    if [[ $saw_url -eq 0 && "$arg" != -* &&
          ! "$arg" =~ ^(GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS)$ &&
          "$arg" != *'=='* && "$arg" != *':='* &&
          "$arg" != *'='* && "$arg" != *':'* ]]; then
      [[ "$arg" == http://* ]] && arg="https://${arg#http://}"
      [[ "$arg" != https://* ]] && arg="https://$arg"
      saw_url=1
    fi
    args+=("$arg")
  done
  http "${args[@]}"
}
