# claude-code.fish: plan

A fish plugin that gives `ask`, `explain`, a suggest key and an explain key, each a thin wrapper over `claude --print`. It is a clean-room port of zsh-claude-code 0.1.1 (commit 6aaa34f, MIT). We build from its README's observable behavior only. Nobody building this opens the upstream source, including `lib/` and `CLAUDE.md`. The system prompts are our own wording.

## Behavior contract

Taken from the upstream README. Where the README is silent, the item is an open question below.

**Commands**

- `ask <words…>` prints a terse answer. If the answer is a command, it shows the command first in a fenced block, then at most one short line of context.
- `explain <command>` prints one overview line, then a short bullet per flag or argument.
- Both join their arguments into one question and send it with `claude --print` and a model chosen per feature (default `sonnet`).

**Keys**

- Suggest (default Ctrl+X): the command line holds a plain-English request. The line is replaced with one shell command. Nothing runs. The user reviews, edits, and presses Enter.
- Explain (default Alt+E): the command line holds a command. The explanation prints above the prompt and the command line is untouched.
- Suggest strips code fences from the reply before putting it on the line.

**Failure**

- `claude` not on `PATH`: the plugin loads without error. `ask` and `explain` still exist and print a short, helpful message. The keys are not bound at all.
- `claude` logged out or failing: a helpful message, never a crash. A failed suggest restores the original command line.

**Safety and scope**

- Each call is one-shot: no session saved, no tools, no slash commands. The helper only prints text. Tests assert the flags we pass.
- The suggest key is opt-in per key press. We do not override Enter or add a `#` prefix trigger.
- Suggest strips code fences, backticks, and surrounding whitespace before it fills the line.

**Non-goals**

- Multi-turn chat.
- Streaming into the line editor.
- Non-Claude providers.
- Extra default keys beyond the two.

**Configuration** (read at load time, set before the plugin loads)

Upstream names are `ZSH_CLAUDE_*`. We use `CLAUDE_FISH_*` with the same suffixes, and the names are our own.

| Variable | Default |
|---|---|
| `CLAUDE_FISH_ASK_MODEL`, `_EXPLAIN_MODEL`, `_SUGGEST_MODEL` | `sonnet` |
| `CLAUDE_FISH_SUGGEST_KEY` | `\cx` |
| `CLAUDE_FISH_EXPLAIN_KEY` | `\ee` |
| `CLAUDE_FISH_ASK_SYSTEM_PROMPT`, `_EXPLAIN_SYSTEM_PROMPT`, `_SUGGEST_SYSTEM_PROMPT` | built-in; a set value fully replaces the built-in |
| `CLAUDE_FISH_EXTRA_FLAGS` | empty; appended to every call |

Fish-specific behavior:

- Unquoted `*`, `$` and `|` are parsed by fish before `ask` or `explain` sees them. The README documents quoting, as upstream does. An unmatched `*` is a fish error that stops the command (status 124, tested on this machine), so the README must say to quote.
- Bindings are registered for default and vi (insert and default) modes.
- Install is via Fisher: `functions/`, `conf.d/`, `completions/`.

## Open questions

Each is answered by choosing, then testing the choice.

1. Exact exit codes and message text on failure. We choose: message to stderr, exit 1.
2. Whether `ask` and `explain` stream or print at the end. We choose: print at the end.
3. Whether suggest shows a busy indicator. We choose: none at first.
4. Behavior on an empty command line. We choose: do nothing, no call.

## Task outline (superseded by Build tasks)

Each task is test first, run in sequence in one worktree, and committed in Conventional Commit form.

1. **Test harness.** Use `fishtape`, installed with fisher (`fisher install jorgebucaran/fishtape`). Fisher 4.4.8 is on the dev machine and `fisher list` shows fishtape is not installed yet. Put a stub `claude` on `PATH` that records its arguments and stdin and prints a canned reply. Add a `mise` or `Makefile` task to run the tests.
2. **`ask`.** Cover argument joining, model default and override, system-prompt default and override, extra flags, and a missing `claude`.
3. **`explain`.** Same coverage as `ask`, plus quoted metacharacters.
4. **Suggest key.** Cover buffer replacement, fence stripping, an empty line, a failing `claude` leaving the buffer unchanged, and the binding in default and vi modes. Test through `commandline` in an interactive `fish -i` run, or by calling the widget function directly.
5. **Explain key.** The buffer stays intact, the explanation prints above the prompt, and the prompt repaints.
6. **Config and keys.** Custom key variables read at load, and defaults when unset.
7. **Completions and docs.** `ask` and `explain` completions, README, MIT license, install and troubleshooting, and a manual test checklist.
8. **CI.** GitHub Actions running the fish tests on Linux and macOS, plus a Conventional Commits check.
9. **Smoke test** against the real `claude` CLI, and a final side-by-side check of each documented behavior against upstream's README.

Releases (release-please) are out of scope until the plugin works.

## Clean-room wall

- The upstream README is saved at `.workbench/sources/README.md`, untracked and gitignored, so a builder in an isolated worktree cannot see it.
- Run each `implementer` with `isolation: "worktree"` and give it this plan, not the upstream URL.
- Keep the upstream source and `CLAUDE.md` unread.

## Build tasks

Shared facts for every task: fish plugin laid out for Fisher (`functions/`, `conf.d/`, `completions/`). Tests use fishtape 3.0.1 (`fishtape tests/<name>.test.fish`) with the stub `claude` from T1 first on `PATH`. The whole fast suite is `fishtape tests/*.test.fish`. Commits are Conventional Commits.

### T1: Test harness and stub claude
**Owns:** tests/stubs/claude, tests/helpers.fish, tests/harness.test.fish
**Blocked by:** none

**Commands:** `fishtape tests/harness.test.fish` · `fishtape tests/*.test.fish` · fishtape is installed through fisher
**Context:** Every later test needs a fake `claude` so tests are deterministic and offline. The real CLI is called as `claude --print …`.
**Build:** An executable fish script `tests/stubs/claude` (first line `#!/usr/bin/env fish`, mode 755). It appends each argument on its own line to the file named by `$CCF_STUB_LOG`. It writes stdin to `$CCF_STUB_STDIN` when that is set. It prints `$CCF_STUB_REPLY` to stdout (nothing when unset) and exits with `$CCF_STUB_EXIT` (0 when unset). `tests/helpers.fish` defines three functions. `ccf_setup` saves `PATH` in the global `CCF_SAVED_PATH`, makes a temp dir in the global `CCF_TMP`, creates an empty `$CCF_TMP/claude.log` and sets `CCF_STUB_LOG` to it, sets `CCF_STUB_STDIN` to `$CCF_TMP/stdin`, sets `CCF_STUB_REPLY` to empty and `CCF_STUB_EXIT` to 0, and puts `tests/stubs` first on `PATH`. `ccf_no_claude` sets `PATH` to `/usr/bin /bin` only, so that `claude` is not found; if `command -q claude` still succeeds there, report BLOCKED. `ccf_teardown` restores `PATH` from `CCF_SAVED_PATH`, removes `CCF_TMP`, and erases all the globals named here.
- [ ] After `ccf_setup`, `claude --print hi` appends `--print` then `hi` as separate lines to the log
- [ ] `CCF_STUB_REPLY` appears on stdout and `CCF_STUB_EXIT=3` makes the exit status 3
- [ ] After `ccf_no_claude`, `command -q claude` fails
- [ ] `ccf_teardown` leaves `PATH` as it was, removes the temp dir, and erases the globals

### T2: Core runner, default prompts, and `ask`
**Owns:** functions/__ccf_run.fish, functions/__ccf_default_prompt.fish, functions/ask.fish, tests/ask.test.fish
**Blocked by:** T1

**Commands:** `fishtape tests/ask.test.fish` · `fishtape tests/*.test.fish` · fishtape via fisher
**Context:** Behavior contract. `ask <words…>` prints a terse answer; if the answer is a command it shows the command first in a fenced block, then at most one short line of context. Arguments are joined with spaces into one question. Model per feature defaults to `sonnet`; the variable is `CLAUDE_FISH_ASK_MODEL`. `CLAUDE_FISH_ASK_SYSTEM_PROMPT`, when set, fully replaces the built-in prompt. `CLAUDE_FISH_EXTRA_FLAGS` (a list) is appended to every call. Each call is one-shot with no tools: `claude --print --model <m> --system-prompt <p> --no-session-persistence --disable-slash-commands --tools "" <extra flags> -- <question>`. The `--` is needed because the real CLI's `--tools` takes a variadic list and would otherwise swallow the question (found by running the real CLI; the stub cannot show it). If `claude` is not on `PATH`, print a short helpful message to stderr and return 1. If `claude` fails, print a short helpful message to stderr and return its status. The same runner also serves `explain` (T3) and the suggest widget (T4), so it takes the feature name.
**Build:** `__ccf_run <feature> <question words…>` for feature `ask`, `explain` or `suggest`; it reads `CLAUDE_FISH_<FEATURE>_MODEL`, `CLAUDE_FISH_<FEATURE>_SYSTEM_PROMPT` and `CLAUDE_FISH_EXTRA_FLAGS`, runs the call above, and passes stdout through. `__ccf_default_prompt <feature>` prints the built-in system prompt for each of the three features, in your own words: ask is terse and fences a command first; explain gives one overview line then one short bullet per flag or argument; suggest outputs exactly one shell command and nothing else. `ask` calls `__ccf_run ask $argv`.
- [ ] `ask how do I list files` sends the question `how do I list files` as the last argument
- [ ] Default model is `sonnet`; `CLAUDE_FISH_ASK_MODEL=opus` changes it
- [ ] A set `CLAUDE_FISH_ASK_SYSTEM_PROMPT` replaces the built-in; unset uses the built-in
- [ ] Extra flags appear in the call, and the fixed flags `--print`, `--no-session-persistence`, `--disable-slash-commands`, `--tools` with an empty value are always present
- [ ] With `claude` absent (detected by `command -q claude`; tests call `ccf_no_claude`): message on stderr, status 1, nothing on stdout
- [ ] With `CCF_STUB_EXIT=2`: message on stderr and status 2
- [ ] `ask` with no arguments prints `usage: ask <question>` to stderr, returns 2, and makes no call

### T3: `explain`
**Owns:** functions/explain.fish, tests/explain.test.fish
**Blocked by:** T2

**Commands:** `fishtape tests/explain.test.fish` · `fishtape tests/*.test.fish` · fishtape via fisher
**Context:** `explain <command>` prints one overview line, then a short bullet per flag or argument. Arguments are joined with spaces. Model variable `CLAUDE_FISH_EXPLAIN_MODEL` (default `sonnet`); `CLAUDE_FISH_EXPLAIN_SYSTEM_PROMPT` replaces the built-in. Fish parses `|`, `>`, `;`, `$` and `*` before `explain` runs, and an unmatched `*` is a fish error, so users quote the command. `__ccf_run <feature> <words…>` exists from T2.
**Build:** `explain` calls `__ccf_run explain $argv`.
- [ ] `explain 'find . -type f | sort'` sends that exact string as the last argument
- [ ] Multiple unquoted words are joined with single spaces
- [ ] `CLAUDE_FISH_EXPLAIN_MODEL` and `CLAUDE_FISH_EXPLAIN_SYSTEM_PROMPT` are honored
- [ ] A missing `claude` gives the T2 error behavior
- [ ] `explain` with no arguments prints `usage: explain <command>` to stderr, returns 2, and makes no call

### T4: Suggest widget function
**Owns:** functions/__ccf_suggest.fish, tests/suggest.test.fish
**Blocked by:** T2

**Commands:** `fishtape tests/suggest.test.fish` · `fishtape tests/*.test.fish` · fishtape via fisher
**Context:** The command line holds a plain-English request. Suggest replaces the line with one shell command; nothing runs, and the user reviews and presses Enter. Cleaning the reply: remove a leading fence line and a trailing fence line (three backticks, with any language tag); trim leading and trailing whitespace and newlines; if the whole result is wrapped in one pair of single backticks, remove that pair. Backticks inside the command, and newlines between lines of a multi-line reply, stay. A failed call restores the original command line. An empty line does nothing and makes no call. Model variable `CLAUDE_FISH_SUGGEST_MODEL` (default `sonnet`). Tests cannot use a real command line, so they define a shadowing function named `commandline` that records `-r` text and `-f` functions and returns a canned buffer for `-b`.
**Build:** `__ccf_suggest`: read the buffer with `commandline -b`; return if empty; call `__ccf_run suggest <buffer>`; on success clean the reply and `commandline -r <clean>`; on failure leave the buffer unchanged; finish with `commandline -f repaint`.
- [ ] A reply wrapped in a fenced block with a `bash` tag, or in backticks, lands on the line without fences or backticks
- [ ] Leading and trailing whitespace and newlines are removed
- [ ] A reply of ``echo `date` `` keeps the inner backticks, and a two-line reply keeps its newline
- [ ] `CCF_STUB_EXIT=1` leaves the buffer untouched (no `-r` call) and still repaints
- [ ] An empty buffer makes no `claude` call
- [ ] The widget never executes the suggested command

### T5: Explain widget function
**Owns:** functions/__ccf_explain.fish, tests/explain-widget.test.fish
**Blocked by:** T2

**Commands:** `fishtape tests/explain-widget.test.fish` · `fishtape tests/*.test.fish` · fishtape via fisher
**Context:** The command line holds a command. The explanation prints above the prompt and the command line is untouched, so the user can still edit or run it. Uses the explain model and prompt (`CLAUDE_FISH_EXPLAIN_*`). An empty line does nothing. Tests shadow `commandline` as in T4.
**Build:** `__ccf_explain`: read the buffer with `commandline -b`; return if empty; call `__ccf_run explain <buffer>`; on success print a blank line then the output to stdout; finish with `commandline -f repaint`. Never call `commandline -r`. On failure the message from `__ccf_run` stays on stderr, no blank line is printed, and the widget still repaints.
- [ ] The explanation text is on stdout and the buffer is never replaced
- [ ] An empty buffer makes no `claude` call
- [ ] A failing `claude` still repaints and does not replace the buffer
- [ ] It uses `CLAUDE_FISH_EXPLAIN_MODEL`

### T6: Key bindings
**Owns:** conf.d/claude-code.fish, tests/bindings.test.fish
**Blocked by:** T4, T5

**Commands:** `fishtape tests/bindings.test.fish` · `fishtape tests/*.test.fish` · fishtape via fisher
**Context:** Keys are read at load time, so users set them before the plugin loads. `CLAUDE_FISH_SUGGEST_KEY` defaults to `\cx` (Ctrl+X); `CLAUDE_FISH_EXPLAIN_KEY` defaults to `\ee` (Alt+E). If `claude` is not on `PATH`, no keys are bound, but loading raises no error. Bindings cover the default mode and vi insert mode. `ask` and `explain` exist regardless, since they report the missing-`claude` error themselves.
**Build:** `conf.d/claude-code.fish` binds the suggest key to `__ccf_suggest` and the explain key to `__ccf_explain`, each with `bind` and `bind -M insert`. Tests source the file in a child fish and read `bind` output. For the no-`claude` case they call `ccf_no_claude` (T1) before starting the child fish.
- [ ] Default keys bind `__ccf_suggest` and `__ccf_explain`
- [ ] Custom key variables set before sourcing change the bound keys
- [ ] With `claude` off `PATH`: sourcing prints nothing, exits 0, and binds neither key
- [ ] Insert-mode bindings exist for both keys

### T7: Completions, README, license
**Owns:** completions/ask.fish, completions/explain.fish, tests/completions.test.fish, README.md, LICENSE
**Blocked by:** T6

**Commands:** `fishtape tests/completions.test.fish` · `fishtape tests/*.test.fish` · fishtape via fisher
**Context:** The project is `claude-code.fish`, a fish plugin. The only upstream mention allowed in the README is this credit line: "Inspired by matheus-poli/zsh-claude-code". Install is `fisher install the-jay-schwartz/claude-code.fish`. Requirements: fish 3.4 or newer, and the `claude` CLI installed and logged in (`claude login` or `ANTHROPIC_API_KEY`). The README documents: the four features (`ask`, `explain`, the suggest key, the explain key) and their keys; the variable table (`CLAUDE_FISH_ASK_MODEL`, `_EXPLAIN_MODEL`, `_SUGGEST_MODEL` default `sonnet`; `CLAUDE_FISH_SUGGEST_KEY` `\cx`; `CLAUDE_FISH_EXPLAIN_KEY` `\ee`; `CLAUDE_FISH_{ASK,EXPLAIN,SUGGEST}_SYSTEM_PROMPT`; `CLAUDE_FISH_EXTRA_FLAGS`); set keys before the plugin loads; quote arguments that hold `* $ | ; > <` because fish parses them first and an unmatched `*` is an error; troubleshooting for missing `claude`, a rebound key (`bind | grep __ccf`), and stray fences; the manual test checklist (`ask` and `explain` with `?`, `!`, `*` and quotes; suggest with a clear and an ambiguous request; explain key leaves the command intact; logged-out `claude` gives a message, not a crash; custom keys). License is MIT, copyright line `Copyright (c) 2026 Jay Schwartz`.
**Build:** `completions/ask.fish` offers no completions (`complete -c ask -f`). `completions/explain.fish` is `complete -c explain -x -a "(__fish_complete_subcommand)"`, so it completes the command and its arguments. The completion test runs `source completions/ask.fish` and `source completions/explain.fish` before calling `complete -C`.
- [ ] `complete -C 'explain gi'` includes `git`
- [ ] `complete -C 'ask '` offers no files
- [ ] README holds every item listed in Context; LICENSE is MIT text

### T8: CI
**Owns:** .github/workflows/ci.yml
**Blocked by:** T7

**Commands:** `yq . .github/workflows/ci.yml` · `fishtape tests/*.test.fish` · Conventional Commits
**Context:** CI runs on push to `main` and on every pull request, on `ubuntu-latest` (24.04, whose apt fish is 3.7) and `macos-latest`. Steps: install fish (`sudo apt-get install -y fish` on Ubuntu, `brew install fish` on macOS); then, in steps with `shell: fish {0}`, install fisher with `curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher`, then `fisher install jorgebucaran/fishtape`, then run `fishtape tests/*.test.fish`. A Conventional Commits check is out of scope for this task. No `claude` credentials are available, so tests rely on the stub only.
**Build:** The workflow file.
- [ ] `yq` parses the file and shows a `strategy.matrix.os` with both runners
- [ ] It runs the whole suite with fishtape after installing fisher and fishtape
- [ ] It triggers on `push` to `main` and on `pull_request`

## Progress

T1: done 9a8e975..7d50ec4
T2: done 5111d62..8fe4fa6

## Rulings

Ruling: Config names are `CLAUDE_FISH_*`, not `ZSH_CLAUDE_*`; costs a rename if you want a different prefix.
Ruling: License holder is "Jay Schwartz" and owner `the-jay-schwartz` (from `gh api user`); costs a one-line edit if wrong.
Ruling: After the cold-read, I fixed the tasks myself: no-argument `ask` and `explain` print a usage line and return 2; suggest strips only wrapping fences and backticks; a failed explain widget prints no blank line; the Conventional Commits check is out of CI scope. Each is cheap to reverse.
Ruling: I left the worktree session (`ExitWorktree keep`) so fish could run, and builders work in the worktree path by absolute path. Cost if wrong: a builder could commit in the main checkout; I check `git log` on both after each task.
Ruling: The user approved changing two T2 assertions (argument positions) to account for `--`; the intent of both is unchanged.
Ruling: The upstream README and CLAUDE.md copies live in the main checkout's `.workbench/sources/`, outside the worktree builders run in; costs nothing if wrong.
