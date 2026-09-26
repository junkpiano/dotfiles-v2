# -*- mode: sh; sh-shell: bash -*-
# vim: set filetype=bash:
# ~/.bash_profile: login shells (ssh, new terminal) read this instead of ~/.bashrc, so just use ~/.bashrc.
# Linked from ~/dotfiles/bash_profile. Without it, bash falls back to ~/.profile (Debian's also sources ~/.bashrc).
if [[ -r "$HOME/.bashrc" ]]; then . "$HOME/.bashrc"; fi
