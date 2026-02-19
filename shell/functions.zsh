#### FUNCTIONS ####

# Find file by name (kept from old, but quoted)
f()  { find . -name "*$1*"; }
ff() { find . -type f -name "*$1*"; }

# Prefer rg for grep-style helpers (faster + .gitignore aware)
# -S = smart case, -n = line numbers, --hidden includes hidden files, but we still ignore .git by default
gall() {
  if command -v rg >/dev/null 2>&1; then
    rg -n -S --hidden -- "$@"
  else
    grep -ir --include="*" -- "$@" .
  fi
}

# Source grep (C, C++, JS, Py)
glsrc() {
  if command -v rg >/dev/null 2>&1; then
    rg -n -S --glob='*.[ch]*' --glob='*.js*' --glob='*.py' -- "$@" *
  else
    grep -i --include="*.[ch]*" --include="*.js*" --include="*.py" -- "$@" *
  fi
}

gsrc() {
  if command -v rg >/dev/null 2>&1; then
    rg -n -S --glob='*.[ch]*' --glob='*.js*' --glob='*.py' -- "$@" .
  else
    grep -ir --include="*.[ch]*" --include="*.js*" --include="*.py" -- "$@" .
  fi
}

# Python grep
glpy() {
  if command -v rg >/dev/null 2>&1; then
    rg -n -S --glob='*.py' -- "$@" *
  else
    grep -i --include="*.py" -- "$@" *
  fi
}

gpy() {
  if command -v rg >/dev/null 2>&1; then
    rg -n -S --glob='*.py' -- "$@" .
  else
    grep -ir --include="*.py" -- "$@" .
  fi
}

# JavaScript grep
gljs() {
  if command -v rg >/dev/null 2>&1; then
    rg -n -S --glob='*.js*' -- "$@" *
  else
    grep -i --include="*.js*" -- "$@" *
  fi
}

gjs() {
  if command -v rg >/dev/null 2>&1; then
    rg -n -S --glob='*.js*' -- "$@" .
  else
    grep -ir --include="*.js*" -- "$@" .
  fi
}

#### PRODUCTIVITY FUNCTIONS ####
# These functions are adapted from mathiasbynens/dotfiles
# Each function is documented with usage examples and explanation

# mkd - Make directory and change into it
# Usage: mkd foldername
# Example: mkd ~/projects/new-project
# Why useful: Combines mkdir -p and cd in one command, saves typing
mkd() {
  mkdir -p "$@" && cd "$_" || return
}

# server - Start a simple HTTP server from current directory
# Usage: server [port]
# Example: server 8080  (or just 'server' for default port 8000)
# Why useful: Quick way to serve static files for testing web projects
# Requires: Python 3 (pre-installed on macOS)
server() {
  local port="${1:-8000}"
  echo "Starting HTTP server on port $port..."
  echo "Access at: http://localhost:$port"
  python3 -m http.server "$port"
}

# targz - Create compressed tar.gz archive with smart compression
# Usage: targz <archive_name.tar.gz> <file_or_folder>
# Example: targz backup.tar.gz ~/documents
# Why useful: Automatically uses best available compression (zopfli > pigz > gzip)
# Note: Falls back to standard gzip if advanced tools aren't installed
targz() {
  local tmpFile="${1%/}.tar"
  tar -cvf "${tmpFile}" --exclude=".DS_Store" "${2}" || return 1

  size=$(
    stat -f"%z" "${tmpFile}" 2>/dev/null || # macOS
    stat -c"%s" "${tmpFile}" 2>/dev/null    # Linux
  )

  local cmd=""
  if (( size < 52428800 )) && command -v zopfli >/dev/null 2>&1; then
    # Use zopfli for files < 50 MB (slower but better compression)
    cmd="zopfli"
  else
    if command -v pigz >/dev/null 2>&1; then
      # Use pigz for parallel compression (faster)
      cmd="pigz"
    else
      # Fall back to standard gzip
      cmd="gzip"
    fi
  fi

  echo "Compressing .tar ($((size / 1000)) kB) using \`${cmd}\`…"
  "${cmd}" -v "${tmpFile}" || return 1
  [ -f "${tmpFile}" ] && rm "${tmpFile}"

  zippedSize=$(
    stat -f"%z" "${tmpFile}.gz" 2>/dev/null || # macOS
    stat -c"%s" "${tmpFile}.gz" 2>/dev/null    # Linux
  )

  echo "${tmpFile}.gz ($((zippedSize / 1000)) kB) created successfully."
}

# dataurl - Convert file to base64-encoded data URL
# Usage: dataurl <file>
# Example: dataurl image.png
# Why useful: Creates data URLs for embedding images/files in HTML/CSS
# Output: data:image/png;base64,iVBORw0KGgoAAAANS...
dataurl() {
  local mimeType
  mimeType=$(file -b --mime-type "$1")
  if [[ $mimeType == text/* ]]; then
    mimeType="${mimeType};charset=utf-8"
  fi
  echo "data:${mimeType};base64,$(openssl base64 -in "$1" | tr -d '\n')"
}

# getcertnames - Show SSL certificate names for a domain
# Usage: getcertnames <domain>
# Example: getcertnames google.com
# Why useful: Quickly check SSL certificate details, SANs, debugging HTTPS issues
# Requires: openssl (pre-installed on macOS)
getcertnames() {
  if [ -z "${1}" ]; then
    echo "Usage: getcertnames <domain>"
    return 1
  fi

  local domain="${1}"
  echo "Testing ${domain}…"
  echo "" # newline

  local tmp
  tmp=$(echo -e "GET / HTTP/1.0\nEOT" \
    | openssl s_client -connect "${domain}:443" -servername "${domain}" 2>&1)

  if [[ "${tmp}" = *"-----BEGIN CERTIFICATE-----"* ]]; then
    local certText
    certText=$(echo "${tmp}" \
      | openssl x509 -text -certopt "no_aux, no_header, no_issuer, no_pubkey, \
      no_serial, no_sigdump, no_signame, no_validity, no_version")
    echo "Common Name:"
    echo "" # newline
    echo "${certText}" | grep "Subject:" | sed -e "s/^.*CN=//" | sed -e "s/\/emailAddress=.*//"
    echo "" # newline
    echo "Subject Alternative Name(s):"
    echo "" # newline
    echo "${certText}" | grep -A 1 "Subject Alternative Name:" \
      | sed -e "2s/DNS://g" -e "s/ //g" | tr "," "\n" | tail -n +2
    return 0
  else
    echo "ERROR: Certificate not found."
    return 1
  fi
}

# tre - Tree view with gitignore awareness
# Usage: tre [directory]
# Example: tre    (shows tree of current directory)
# Why useful: Shows directory structure while hiding .git, node_modules, etc.
# Requires: tree (install via: brew install tree)
tre() {
  if ! command -v tree >/dev/null 2>&1; then
    echo "Error: 'tree' command not found. Install with: brew install tree"
    return 1
  fi

  tree -aC -I '.git|node_modules|bower_components|.DS_Store' --dirsfirst "$@" | less -FRNX
}

#### HTTP - httpie-style curl wrapper ####
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
