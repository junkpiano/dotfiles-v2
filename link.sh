#!/usr/bin/env bash
# -*- mode: sh; sh-shell: bash -*-
# Link this repo's files into $HOME. Safe to run again: links already in place are left alone,
# and anything else in the way is moved aside to <name>.orig (never deleted).
# Usage: ./link.sh [-n]    -n: only show what would happen
set -euo pipefail

dry_run=0
for arg in "$@"; do
  case "$arg" in
    -n) dry_run=1 ;;
    *) printf 'usage: %s [-n]\n' "$0" >&2; exit 1 ;;
  esac
done

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
if [[ -z "${HOME:-}" || -z "$repo" || "$repo" == "/" ]]; then
  printf 'HOME or the repo path is empty; stopping\n' >&2
  exit 1
fi

run() { if (( dry_run )); then printf '  (would run) %s\n' "$*"; else "$@"; fi; }

# link <path in this repo> <name in $HOME>
link() {
  local src="$repo/$1" dst="$HOME/$2"
  [[ -e "$src" ]] || { printf 'missing %s; stopping\n' "$src" >&2; exit 1; }
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    printf 'ok       %s\n' "$dst"
    return
  fi
  if [[ -e "$dst" || -L "$dst" ]]; then
    if [[ -e "$dst.orig" || -L "$dst.orig" ]]; then
      printf '%s and %s.orig both exist; move one away first\n' "$dst" "$dst" >&2
      exit 1
    fi
    printf 'moving   %s -> %s.orig\n' "$dst" "$dst"
    run mv -- "$dst" "$dst.orig"
  fi
  printf 'linking  %s -> %s\n' "$dst" "$src"
  run ln -s -- "$src" "$dst"
}

link bashrc .bashrc
link bash_profile .bash_profile
link zshrc .zshrc
link emacs .emacs.d
