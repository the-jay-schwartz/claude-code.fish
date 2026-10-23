# claude-code.fish

A fish plugin that puts Claude at the prompt. Two commands and two key bindings, each a thin wrapper over one `claude --print` call:

- **`ask <question>`** prints a terse answer. A command comes first in a fenced block, then at most one line of context.
- **`explain <command>`** prints one overview line, then a short list item per flag or argument.
- **Ctrl+X** (`__ccf_suggest`) replaces the command line, a plain-English request, with one shell command. The user reviews it and presses Enter.
- **Alt+E** (`__ccf_explain`) prints an explanation of the command line above the prompt and leaves the line intact.

The plugin has no runtime dependency beyond fish and the `claude` CLI. It is a fish port of [matheus-poli/zsh-claude-code](https://github.com/matheus-poli/zsh-claude-code). We built the code from that project's README and observed behavior without reading its source, so the implementation is ours. Parts of our README are adapted from theirs, under the notice in `THIRD_PARTY_LICENSES`.

## Target users

fish users, usually installing with Fisher, who already use Claude Code and want terminal helpers without leaving their shell, prompt or theme.

## Requirements

- fish 3.4 or newer. CI runs fish 3.7 (Ubuntu) and the current Homebrew fish (macOS).
- The `claude` CLI, installed and logged in with `claude login` or `ANTHROPIC_API_KEY`.

Dev only: [fishtape](https://github.com/jorgebucaran/fishtape) for tests. Users do not need it.

## Related projects

- [matheus-poli/zsh-claude-code](https://github.com/matheus-poli/zsh-claude-code) is the zsh original and the source of the feature set.
- [michellepol/claude-cmd.fish](https://github.com/michellepol/claude-cmd.fish) and [jglanz/fish-claude-ai-plugin](https://github.com/jglanz/fish-claude-ai-plugin) are existing fish plugins.
## Repository layout

```
functions/   one autoloaded function per file; __ccf_* are internal
  __ccf_run.fish            the one-shot claude call, shared by every feature
  __ccf_default_prompt.fish built-in system prompt per feature
  __ccf_suggest.fish        Ctrl+X widget body
  __ccf_explain.fish        Alt+E widget body
  ask.fish, explain.fish    the commands
conf.d/claude-code.fish     reads the key variables and binds the keys, once, at load
completions/                tab completion for ask and explain
tests/                      fishtape tests; stubs/claude is the fake CLI
```

## Public surface

The `CLAUDE_FISH_*` variables are documented in the README. Keys are read once at load, so a change needs a new shell. Models and prompts are read on every call.

## Design notes

- **`--system-prompt` replaces the default prompt.** Claude Code's default prompt is large and aimed at agentic tool use. A terminal helper wants short answers, and replacing is faster than appending.
- **`--tools ""`, `--no-session-persistence`, `--disable-slash-commands`.** The helpers are text in and text out. Tools would let Claude read files or run commands the user did not expect, and a saved session would clutter `claude --resume`.
- **`--setting-sources user --strict-mcp-config`.** Project settings and MCP servers in the current directory would change what a one-shot call can do. User-level settings and `CLAUDE.md` still apply on purpose, so a user who prefers `fd` to `find` gets `fd` suggestions.
- **`--` before the question.** `--tools` takes a variadic list and would swallow the question without it. The stub CLI cannot show this; we found it by running the real CLI.
- **Not `--bare`.** It disables OAuth and the keychain, which breaks users logged in with `claude login`.
- **`CLAUDE_FISH_EXTRA_FLAGS` is an allowlist.** Only `--effort`, `--max-budget-usd` and `--fallback-model` pass, alone or as `flag=value`, and any other dash token is refused with status 2. A denylist missed flag orderings that re-enabled tools. The value must be a fish list; a quoted `'--effort low'` is one argument.
- **Suggest replaces the buffer; explain does not.** Suggest is an authoring flow: the user reviews the command and presses Enter. Explain is read-only: it prints above the prompt and leaves the line as typed.
- **Suggest never runs the command.** It strips one wrapping code fence or one pair of backticks, and trims whitespace. Backticks inside the command stay. A reply of more than one line is rejected, not inserted, because a multi-line buffer could run several commands on one Enter.
- **A failed call leaves the command line as it was.** An empty line makes no call. An empty reply leaves the buffer alone and prints a message.
- **Dedicated keys, not Enter or a `#` prefix.** Overriding Enter puts every command through our hook. A key is opt-in per press.
- **Missing `claude`.** The plugin loads without error and binds no keys. `ask` and `explain` still exist and print a message to stderr with status 1.
- **Quoting is the user's job.** fish parses `*`, `$`, `|`, `;`, `>` and `<` before `ask` or `explain` runs, and an unmatched `*` is a fish error. The README says to quote. The commands join their arguments with single spaces.
- **Models.** All three features default to `sonnet`. Each has its own variable, so a user can pick another model per feature.
- **Binding names differ across fish versions.** fish 3.7 prints `bind \cg …` and 4.x prints `bind ctrl-g …`, so tests that read `bind` output accept both.

## Testing

- **Unit tests:** `fishtape tests/*.test.fish`. They run offline against `tests/stubs/claude`, which records its arguments and stdin and prints a canned reply. `tests/helpers.fish` provides `ccf_setup`, `ccf_no_claude` and `ccf_teardown`. The suite asserts the flags we pass.
- **Widgets:** a real command line is not available in a test, so the tests shadow `commandline` with a function that records its calls.
- **Live smoke test:** `CCF_LIVE=1 fishtape tests/live.test.fish` makes a few small API calls to the real `claude`. Without the variable it shows one placeholder test. Run it before a release.
- **CI** (`.github/workflows/ci.yml`) runs the suite on Ubuntu and macOS for every push to `main` and every PR. The two runners give two fish versions (3.7 and 4.x), which is the point. Actions are pinned by SHA.
- **Manual checklist:** the README's Contributing section lists the cases the stub cannot cover.
- **No test for the failure message on stderr** in the explain widget. fish sends a command substitution's stderr straight to the terminal, so a test cannot capture it. The code does not touch that stream, so check it by hand.

## Releases

[release-please](https://github.com/googleapis/release-please) runs from `.github/workflows/release-please.yml` on every push to `main`. It keeps one open release PR with the computed version, the manifest change and the `CHANGELOG.md` entry. Merging that PR creates the tag and the GitHub release, so `main` is always releasable without being released. Users can pin a release with `fisher install the-jay-schwartz/claude-code.fish@v0.1.0`.

- **Version from commits:** `feat:` bumps minor, `fix:` bumps patch, `feat!:` or a `BREAKING CHANGE:` footer bumps major. At 0.x, `bump-minor-pre-major` makes a breaking change bump minor, so the plugin stays below 1.0.0 until we choose to release it with `release-as`. `docs:`, `test:`, `chore:`, `ci:` and `refactor:` are hidden from the changelog and cut no release.
- **Why 0.x:** 1.0.0 promises the commands, the `CLAUDE_FISH_*` variables and the default keys will not break without a major bump. The `claude` CLI and fish both change outside our control, so we wait for real users before making that promise.
- **`release-type` is `simple`.** The plugin has no package manifest, and the version lives in `.release-please-manifest.json` and the git tag. The strategy did not create a `version.txt` in the first release, and nothing reads one.
- **`bootstrap-sha`** is the commit before the first `feat:`, so the first changelog skips the build history. Release-please ignores it after the first release PR merges, and it can be removed then.
- **Actions must be allowed to open PRs:** Settings → Actions → General → "Allow GitHub Actions to create and approve pull requests".
- **Known limitation:** the workflow runs as `GITHUB_TOKEN`, so the release PR does not trigger `ci.yml`. The PR changes only the changelog and the manifest. Pass a PAT as the action's `token:` input if that ever matters.

## Non-goals

- Multi-turn chat. Run `claude` directly for that.
- Streaming output into the line editor.
- Non-Claude providers.
- Extra default keys. Users can rebind the two we ship.

## Conventions

- **Commits:** [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `docs:`, `test:`, `chore:`, `ci:`). release-please reads them to pick the version and write the changelog. PRs are squash-merged, so the PR title becomes the commit message, and `.github/workflows/pr-title.yml` fails a PR whose title is not a Conventional Commit.- **Changing a test assertion** needs the maintainer's yes. Adding tests does not.
- **Fish style:** quote expansions, use `set -l` for function variables, and write one function per file in `functions/`.
- **Dependencies:** none at runtime. Keep it that way.
- **Contributors:** all-contributors keeps the list in the README. Add someone with `@all-contributors please add @user for code, doc`.

## Known issues

- The widgets block the prompt while the call runs, usually one to three seconds. There is no busy indicator.
- Keys are read at load, so a new key needs a new shell.