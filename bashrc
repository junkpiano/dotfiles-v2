# -*- mode: sh; sh-shell: bash -*-
# vim: set filetype=bash:
# ~/.bashrc on every machine (WSL, Pi, macOS). Per-machine bits: ~/.bash_aliases or ~/.bashrc.local.
# shellcheck shell=bash disable=SC1090,SC1091  # sources optional files that may not exist here

[[ $- == *i* ]] || return   # scripts and scp: nothing below applies

# --- environment ---
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export EDITOR=vim
GPG_TTY=$(tty); export GPG_TTY

path_prepend() { [[ -d "$1" && ":$PATH:" != *":$1:"* ]] && PATH="$1:$PATH"; }
for f in "$HOME/.local/bin" "$HOME/bin" "$HOME/.bun/bin" "$HOME/.opencode/bin"; do path_prepend "$f"; done
export PATH

for f in /opt/homebrew/bin/brew /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
  if [[ -x "$f" ]]; then eval "$("$f" shellenv)"; break; fi
done

# --- history: big, shared across terminals, with timestamps ---
HISTSIZE=50000 HISTFILESIZE=100000
HISTCONTROL=ignoreboth:erasedups HISTTIMEFORMAT='%F %T '
shopt -s histappend cmdhist

# --- behavior ---
shopt -s checkwinsize globstar autocd cdspell dirspell no_empty_cmd_completion
bind 'set completion-ignore-case on' 'set show-all-if-ambiguous on' 'set mark-symlinked-directories on' 'set colored-stats on'
bind '"\e[A": history-search-backward' '"\e[B": history-search-forward'   # up/down: search history by what is typed

# --- completion ---
if ! shopt -oq posix; then
  for f in /usr/share/bash-completion/bash_completion /etc/bash_completion \
           "${HOMEBREW_PREFIX:-/nonexistent}/etc/profile.d/bash_completion.sh"; do
    if [[ -r "$f" ]]; then . "$f"; break; fi
  done
fi

# --- prompt: host:dir (branch*=) $   (exit status in red when non-zero) ---
for f in /usr/lib/git-core/git-sh-prompt "${HOMEBREW_PREFIX:-/nonexistent}/etc/bash_completion.d/git-prompt.sh"; do
  if [[ -r "$f" ]]; then . "$f"; break; fi
done
unset f
# shellcheck disable=SC2034  # read by __git_ps1
GIT_PS1_SHOWDIRTYSTATE=1 GIT_PS1_SHOWUPSTREAM=auto
__prompt() {
  local status=$? branch=''
  declare -F __git_ps1 >/dev/null && branch=$(__git_ps1 ' (%s)')
  PS1='\[\e[36m\]\h\[\e[0m\]:\[\e[34m\]\w\[\e[33m\]'"$branch"'\[\e[0m\] '
  (( status != 0 )) && PS1+='\[\e[31m\]'"$status"'\[\e[0m\] '
  PS1+='\$ '
  history -a   # write each command right away, so other terminals can load it
}
PROMPT_COMMAND=__prompt   # set before mise, which adds its own hook

# --- tools (each only if installed) ---
command -v mise >/dev/null && eval "$(mise activate bash)"
[[ -r /usr/share/doc/fzf/examples/key-bindings.bash ]] && . /usr/share/doc/fzf/examples/key-bindings.bash   # fzf from apt: Ctrl-R, Ctrl-T, Alt-C

# --- aliases (interactive only; scripts are unaffected) ---
if [[ "$(uname)" == Darwin ]]; then
  alias ls='ls -FG'
  alias rm='rm -i'
else
  alias ls='ls -F --color=auto'
  alias rm='rm -I --preserve-root=all'   # ask before deleting many files or recursing
fi
alias cp='cp -i' mv='mv -i' grep='grep --color=auto'
alias ll='ls -alh' la='ls -A' g=git

# --- git, with oh-my-zsh's names; extra options pass through (ggpush --force-with-lease) ---
alias gst='git status -sb' gco='git checkout'   # gst: short, with the branch and ahead/behind
if [[ -r /usr/share/bash-completion/completions/git ]]; then . /usr/share/bash-completion/completions/git; __git_complete gco _git_checkout; fi # Tab after gco: branch names
gbda() { git branch --merged main | grep -vE '^[*+]|^ *main$' | xargs -r git branch -d; }   # delete branches merged into main (not squash-merged ones)
alias glol="git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset'"
__git_branch() { git symbolic-ref --quiet --short HEAD || { echo "not on a branch" >&2; return 1; }; }
ggpush() { local b; b=$(__git_branch) || return; git push -u origin "$b" "$@"; }        # -u: track on first push
ggpull() { local b; b=$(__git_branch) || return; git pull --ff-only origin "$b" "$@"; } # never a surprise merge
# gpr <n>: fetch pull request <n> as pr/<n>, list the files it changes, then browse its commits (tig, or git log -p)
gpr() { [[ "${1:-}" =~ ^[0-9]+$ ]] || { echo "usage: gpr <number>" >&2; return 1; }
  local base; base=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD || echo origin/main)
  git fetch -f origin "pull/$1/head:pr/$1" && git diff --stat "$base...pr/$1" &&
  { if command -v tig >/dev/null; then tig "$base..pr/$1"; else git log -p "$base..pr/$1"; fi; }; }
epr() { [[ "${1:-}" =~ ^[0-9]+$ ]] || { echo "usage: epr <number>" >&2; return 1; }; emacs -nw --eval "(my/pr-review $1)"; }   # PR as a diff in Emacs
__pr_title() { local u t; u=$(git remote get-url origin)
  if [[ "$u" == *github.com* ]]; then t=$(gh pr view "$1" --json title -q .title 2>/dev/null)
  else t=$(tea pr ls --repo "$(sed -E 's#^.*[:/]([^/]+/[^/]+)$#\1#; s#\.git$##' <<< "$u")" --state all --limit 100 --fields index,title --output tsv 2>/dev/null | awk -F'\t' -v n="$1" '$1==n {print $2; exit}'); fi
  [[ -n "$t" ]] && echo "$t (#$1)"; }
# gsquash <branch|PR number>: squash it onto an up-to-date main as one commit signed with your key; edit the message; push yourself.
# With a number, the message starts from the PR's title (gh for GitHub, tea for Gitea).
gsquash() { local ref="${1:-}" title=""; [[ -n "$ref" ]] || { echo "usage: gsquash <branch|PR number>" >&2; return 1; }
  [[ -z "$(git status --porcelain)" ]] || { echo "commit or stash your changes first" >&2; return 1; }
  if [[ "$ref" =~ ^[0-9]+$ ]]; then git fetch -f origin "pull/$ref/head:pr/$ref" || return; title=$(__pr_title "$ref"); ref="pr/$ref"; fi
  git switch main && git pull --ff-only && git merge --squash "$ref" &&
  git commit -S -e -m "${title:-$(git log --reverse --format=%s "main..$ref" | head -1)}" -m "$(git log --reverse --format='- %s' "main..$ref")"; }

# --- per-machine: aliases, then private overrides (neither is in this repo) ---
if [[ -r "$HOME/.bash_aliases" ]]; then . "$HOME/.bash_aliases"; fi
if [[ -r "$HOME/.bashrc.local" ]]; then . "$HOME/.bashrc.local"; fi
