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

## Tasks

Each task is test first, run in sequence in one worktree, and committed in Conventional Commit form.

1. **Test harness.** `fisher`, `fishtape` and `littlecheck` are all absent on the dev machine (checked). Pick one and install it, or vendor it, before any test runs. Put a stub `claude` on `PATH` that records its arguments and stdin and prints a canned reply. Add a `mise` or `Makefile` task to run the tests.
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
