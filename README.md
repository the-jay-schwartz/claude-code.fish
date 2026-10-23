# claude-code.fish

Claude-powered helpers for your fish prompt. Ask questions, explain commands, and turn natural language into shell commands - without leaving the terminal.

All four features wrap the [`claude` CLI](https://code.claude.com/docs/en/overview) (Claude Code) in `--print` mode, so if you're already logged in with `claude login` there's nothing else to set up.

- **<kbd>Ctrl</kbd>+<kbd>X</kbd>** - describe a command in plain English, press to rewrite the line into shell.
- **<kbd>Alt</kbd>+<kbd>E</kbd>** - type or paste a command, press to print an explanation above it.

## Features

| | What | Trigger | Default model |
|---|---|---|---|
| **Ask** | Terse answer to any dev/terminal question | `ask <question>` | `sonnet` |
| **Explain** | Summarize a command in natural, concise English | `explain <command>` | `sonnet` |
| **Suggest widget** | Rewrite the current line (natural language) → one shell command, in place | <kbd>Ctrl</kbd>+<kbd>X</kbd> | `sonnet` |
| **Explain widget** | Explain the command at the prompt, above it (command stays intact) | <kbd>Alt</kbd>+<kbd>E</kbd> | `sonnet` |

Each call is one-shot: no saved session, no tools, no slash commands. Your user-level Claude settings and `CLAUDE.md` still apply, so a preference like "use `fd` instead of `find`" shapes the suggestions. Project-level settings and MCP servers are ignored.

## Requirements

- [fish](https://fishshell.com) 3.4+
- [`claude` CLI](https://code.claude.com/docs/en/overview) installed and authenticated (either `claude login` or `ANTHROPIC_API_KEY` in the environment)
- [Fisher](https://github.com/jorgebucaran/fisher) to install
- No other runtime dependencies

## Installation

```fish
fisher install the-jay-schwartz/claude-code.fish
```

Open a new shell, or run `exec fish`.

## Usage

### `ask`

```fish
ask how do I list files modified in the last 24 hours
ask 'what is the difference between $* and $@ in bash?'
```

Prints a terse answer. If the answer is a command, it shows the command first in a fenced block, then at most one short line of context.

### `explain`

```fish
explain 'find . -type f -exec md5sum {} + | sort | uniq -w32 -dD'
```

Prints one overview line + a short list item per flag/argument. Tab completes the command.

fish parses the line before `ask` or `explain` sees it. Wrap the argument in single quotes whenever it contains `*`, `$`, `|`, `;`, `>` or `<`. An unquoted `*` that matches nothing is a fish error, and the command never runs.

### Suggest widget (<kbd>Ctrl</kbd>+<kbd>X</kbd>)

Type a natural-language request, then press <kbd>Ctrl</kbd>+<kbd>X</kbd>:

```plaintext
find all js files larger than 100kb modified in the last week
```

becomes:

```fish
find . -name "*.js" -size +100k -mtime -7
```

Review the command, press <kbd>Enter</kbd> to run (or edit first). The suggestion is never run for you. If the reply is more than one line, it is not inserted.

### Explain widget (<kbd>Alt</kbd>+<kbd>E</kbd>)

Type or paste a command at the prompt, then press <kbd>Alt</kbd>+<kbd>E</kbd>. The explanation prints above the prompt; your command stays intact so you can still edit or run it.

The keys are bound in default and insert modes, and only if `claude` is on `PATH` at the first prompt.

## Configuration

Set any of these in `~/.config/fish/config.fish`. The keys are read once, at the first prompt, so changing one needs a new shell.

| Variable | Default | Description |
|---|---|---|
| `CLAUDE_FISH_ASK_MODEL` | `sonnet` | Model for `ask` |
| `CLAUDE_FISH_EXPLAIN_MODEL` | `sonnet` | Model for `explain` + explain widget |
| `CLAUDE_FISH_SUGGEST_MODEL` | `sonnet` | Model for the suggest widget |
| `CLAUDE_FISH_SUGGEST_KEY` | `\cx` | Keybind for the suggest widget |
| `CLAUDE_FISH_EXPLAIN_KEY` | `\ee` | Keybind for the explain widget (`\ee` = Alt+E) |
| `CLAUDE_FISH_ASK_SYSTEM_PROMPT` | *(built-in)* | Full override of the `ask` system prompt |
| `CLAUDE_FISH_EXPLAIN_SYSTEM_PROMPT` | *(built-in)* | Full override of the `explain` system prompt |
| `CLAUDE_FISH_SUGGEST_SYSTEM_PROMPT` | *(built-in)* | Full override of the suggest system prompt |
| `CLAUDE_FISH_EXTRA_FLAGS` | *(empty)* | Extra flags appended to every `claude --print` call (advanced) |

`CLAUDE_FISH_EXTRA_FLAGS` must be a fish list, for example `set -g CLAUDE_FISH_EXTRA_FLAGS --effort low`. A single quoted string such as `'--effort low'` is passed as one argument. Only `--effort`, `--max-budget-usd` and `--fallback-model` (alone or as `flag=value`) are allowed. Any other flag is refused, so tools, permissions, settings and MCP cannot be changed.

### Example: change keybind and use a stronger `ask` model

```fish
# ~/.config/fish/config.fish
set -g CLAUDE_FISH_SUGGEST_KEY \cg     # Ctrl+G instead of Ctrl+X
set -g CLAUDE_FISH_ASK_MODEL opus      # stronger model for ask, slower
```

## Privacy

`explain` and the explain and suggest widgets send the command line to the Claude API.

## Troubleshooting

- **"the 'claude' command was not found"** - the plugin loads but binds no keys when `claude` isn't on `PATH`. Install Claude Code and run `claude login`.
- **Widget doesn't fire** - another plugin may have rebound the key. Try setting `CLAUDE_FISH_SUGGEST_KEY` to something else, or use `bind | grep __ccf` to confirm the binding.
- **Output has stray backticks / code fences** - the suggest widget strips one surrounding fence or pair of backticks. If more appear, tighten `CLAUDE_FISH_SUGGEST_SYSTEM_PROMPT`, or open an issue with the input that produced it.

## Contributing

Contributions welcome - PRs, bug reports, feature ideas. Tests use [fishtape](https://github.com/jorgebucaran/fishtape) with a stub `claude` on `PATH`, so they run offline:

```fish
fisher install jorgebucaran/fishtape
fishtape tests/*.test.fish
```

Commits follow [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `docs:`, `chore:`, …).

**Manual test checklist** before sending a PR that touches the plugin code:

- `ask` and `explain` with `?`, `!`, `*`, and quoted strings
- <kbd>Ctrl</kbd>+<kbd>X</kbd> with a clear request and an ambiguous one
- <kbd>Alt</kbd>+<kbd>E</kbd> on a typed command - original command must stay intact
- All four features with `claude` logged out → helpful error, not a crash
- Custom keybinds set before plugin load

See [CLAUDE.md](./CLAUDE.md) for design notes and the reasoning behind each decision.

## Contributors

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tbody>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/the-jay-schwartz"><img src="https://avatars.githubusercontent.com/u/26683765?v=4?s=100" width="100px;" alt="Jay Schwartz"/><br /><sub><b>Jay Schwartz</b></sub></a><br /><a href="https://github.com/the-jay-schwartz/claude-code.fish/commits?author=the-jay-schwartz" title="Code">💻</a> <a href="https://github.com/the-jay-schwartz/claude-code.fish/commits?author=the-jay-schwartz" title="Documentation">📖</a> <a href="https://github.com/the-jay-schwartz/claude-code.fish/commits?author=the-jay-schwartz" title="Tests">⚠️</a> <a href="#infra-the-jay-schwartz" title="Infrastructure (Hosting, Build-Tools, etc)">🚇</a> <a href="#ideas-the-jay-schwartz" title="Ideas, Planning, & Feedback">🤔</a></td>
    </tr>
  </tbody>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://allcontributors.org) specification. Contributions of any kind are welcome. After a merged PR, comment on it to add yourself:

```plaintext
@all-contributors please add @your-username for code, doc
```

## Other shells

| Shell | Project |
|---|---|
| zsh | [matheus-poli/zsh-claude-code](https://github.com/matheus-poli/zsh-claude-code) |
| fish | [the-jay-schwartz/claude-code.fish](https://github.com/the-jay-schwartz/claude-code.fish) (this project) |

## License

[MIT](./LICENSE) © Jay Schwartz

## Credits

The behavior and feature set come from [matheus-poli/zsh-claude-code](https://github.com/matheus-poli/zsh-claude-code) (MIT © Matheus Poli), and parts of this README are adapted from its README. See [THIRD_PARTY_LICENSES](./THIRD_PARTY_LICENSES) for the notice that covers that text.
