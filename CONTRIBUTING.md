# Contributing

**This repository does not accept pull requests.** To contribute, send a patch to the author.

## Sending a patch

1. Make one change per commit. Keep the subject short and in the style of the history
   (`fix: ...`, `feat: ...`, `docs: ...`); say why in the body.
2. Turn it into a patch:

   ```sh
   git format-patch -1            # the last commit; several: git format-patch origin/main
   ```

3. Send it to the author: open an issue, attach the `.patch` file, and add a line on why.

## Scope

These are personal settings kept small on purpose: few dependencies, fast to start, easy to rebuild,
`bashrc` within 100 lines. Fixes and simplifications are welcome; changes that add dependencies or
features most people would not need are unlikely to go in. Questions and bug reports are fine as issues too.
