# dotfiles v2

bash and Emacs, kept small: few dependencies, fast to start, easy to rebuild.

## Requirements

The bash and Emacs setups expect these tools. `bashrc` skips a tool that is missing, so nothing
breaks, but the feature in the second column needs it.

| Tool | Used for | Debian / Ubuntu |
|------|----------|-----------------|
| git | everything; the branch in the prompt (`git-sh-prompt`) | `sudo apt install git` |
| bash-completion | Tab completion, branch names after `gco` | `sudo apt install bash-completion` |
| fzf | Ctrl-R history, Ctrl-T files, Alt-C dirs; `gf` | `sudo apt install fzf` |
| tig | browsing history; `gpr` (falls back to `git log -p`) | `sudo apt install tig` |
| tea | Gitea from the shell: pull requests, issues, repositories; PR titles for `gsquash <n>` | release binary from gitea.com (see below) |
| gh | GitHub from the shell; PR titles for `gsquash <n>` on GitHub remotes | `sudo apt install gh`, then `gh auth login` |
| mise | node and rust versions | `curl https://mise.run \| sh` |
| Emacs 30 or later | `emacs/` (uses built-in `which-key`) | |
| emacs-mozc-bin | Japanese input in Emacs (`C-\`) | `sudo apt install emacs-mozc-bin` |
| Fonts | Ricty Diminished, Noto Sans Mono CJK JP, Noto Color Emoji (GUI Emacs only) | |

All at once on Debian / Ubuntu:

```sh
sudo apt install git bash-completion fzf tig gh emacs-mozc-bin
```

- tea is not in apt (the apt package `tea` is an unrelated text editor). Get `tea-<version>-linux-amd64.xz`
  (or `-arm64` on a Pi) from https://gitea.com/gitea/tea/releases, check it against its `.sha256`,
  and put it in `~/.local/bin/tea`. Then `tea login add --name home --url https://<your-gitea>`
  (it asks for a token with write access to repositories).
- Ubuntu 24.04's fzf (0.44) has no `fzf --bash`; `bashrc` then loads the key bindings from
  `/usr/share/doc/fzf/examples/key-bindings.bash`, which the apt package ships.
- Emacs installs its own two packages (`markdown-mode`, `mozc`) from MELPA on the first start.

## Aliases and functions

From `bashrc`. Aliases work only in an interactive shell; scripts get the plain commands.

| Name | Does | Notes |
|------|------|-------|
| `ls` | `ls -F --color=auto` (`ls -FG` on macOS) | marks directories and links |
| `grep` | `grep --color=auto` | |
| `cp`, `mv` | `cp -i`, `mv -i` | ask before overwriting |
| `rm` | `rm -I --preserve-root=all` (`rm -i` on macOS) | asks before deleting many files or recursing |
| `gst` | `git status -sb` | short, with the branch and ahead/behind |
| `gco` | `git checkout` | Tab completes branch names |
| `gc` | `git commit` | options pass through (`gc -m ...`, `gc -a`); Tab completes them |
| `gc!` | `git commit --amend` | redo the last commit; `gc! --no-edit` keeps its message |
| `ggpush` | `git push -u origin <current branch>` | tracks on the first push; extra options pass through |
| `ggpull` | `git pull --ff-only origin <current branch>` | stops instead of making a merge commit |
| `gbda` | delete local branches merged into `main` | uses `git branch -d`; squash-merged branches stay |
| `gpr <n>` | fetch pull request `<n>` as `pr/<n>`, list its files, browse it in tig | GitHub and Gitea |
| `epr <n>` | fetch pull request `<n>` as `pr/<n>` and open it in Emacs as one read-only diff, like the PR page | the same as `C-c r` inside Emacs; `n` / `p` move between hunks, `o` opens the file |
| `gsquash <branch\|n>` | squash a branch or pull request onto an up-to-date `main` as one commit signed with your key | opens the editor (message from the PR title with a number); does not push; then `gship <n>` |
| `gship <n>` | after `gsquash <n>`, on `main`: push `main`, mark PR `<n>` merged (Gitea: manually merged with the squash commit; GitHub: closed with a comment), delete its branch here and on the remote | the branch is the one pointing at the PR's head commit, never `main`; Gitea repos need "allow manual merge" on, else the PR is just closed |
| `gf <pattern> [dir]` | search files under `dir` (default `.`), narrow the hits in fzf, open the chosen line in Emacs | skips `.git` and binary files; preview shows the lines around; Esc cancels |

Keys: Ctrl-R (history), Ctrl-T (files), Alt-C (directories) come from fzf; up/down search the history
by what is already typed.

## bash (every machine: WSL, Raspberry Pi, macOS)

```sh
git clone https://github.com/junkpiano/dotfiles-v2.git ~/dotfiles
~/dotfiles/link.sh -n   # show what it would do
~/dotfiles/link.sh      # link bashrc, bash_profile and emacs/
chsh -s /bin/bash   # if the login shell is something else
```

Try it first without changing anything: `bash --rcfile ~/dotfiles/bashrc`.
`bashrc` reads `~/.bash_aliases` (per-machine aliases, kept outside this repo)
and then `~/.bashrc.local` (private, not in git).

## Emacs (every machine)

A minimal Emacs 30 setup for reading files: built-ins first, only `markdown-mode` and `mozc` from MELPA,
installed on the first start. `.md` opens read-only and rendered; `M-x gfm-mode` to edit.

`link.sh` links `~/.emacs.d` too.

Try it first without changing anything: `emacs --init-directory ~/dotfiles/emacs`.
Japanese input (`C-\`) needs `mozc_emacs_helper` (`sudo apt install emacs-mozc-bin`).

## link.sh

`./link.sh [-n]` links the files above into `$HOME`. Links already in place are left alone;
anything else in the way is moved to `<name>.orig`, never deleted (it stops if that `.orig` exists too).
Safe to run again.
