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
