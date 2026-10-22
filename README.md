# claude-code.fish

Ask Claude shell questions from the fish prompt. Two commands and two key bindings, each a one-shot, tool-less `claude` call.

Inspired by matheus-poli/zsh-claude-code

## Requirements

- fish 3.4 or newer
- the `claude` CLI installed and logged in (`claude login` or `ANTHROPIC_API_KEY`)

## Install

```fish
fisher install the-jay-schwartz/claude-code.fish
```

## Features

| Feature | How | What it does |
|---|---|---|
| `ask` | `ask <question>` | Answers tersely; a command comes first in a code block. |
| `explain` | `explain '<command>'` | One overview line, then a bullet per flag or argument. Tab completes the command. |
| suggest key | `Ctrl+X` (`\cx`) | Replaces the command line, written as a plain-English request, with one suggested command. It is never run. |
| explain key | `Alt+E` (`\ee`) | Prints an explanation of the command line above the prompt. The command line is left intact. |

The keys are bound in default and insert modes, and only if `claude` is on `PATH` when the plugin loads.

## Configuration

Set variables before the plugin loads (for example in `config.fish`); keys are read once, at load time.

| Variable | Default | Meaning |
|---|---|---|
| `CLAUDE_FISH_ASK_MODEL` | `sonnet` | Model for `ask` |
| `CLAUDE_FISH_EXPLAIN_MODEL` | `sonnet` | Model for `explain` and the explain key |
| `CLAUDE_FISH_SUGGEST_MODEL` | `sonnet` | Model for the suggest key |
| `CLAUDE_FISH_SUGGEST_KEY` | `\cx` | Suggest key binding |
| `CLAUDE_FISH_EXPLAIN_KEY` | `\ee` | Explain key binding |
| `CLAUDE_FISH_ASK_SYSTEM_PROMPT` | built-in | Replaces the system prompt for `ask` |
| `CLAUDE_FISH_EXPLAIN_SYSTEM_PROMPT` | built-in | Replaces the system prompt for `explain` |
| `CLAUDE_FISH_SUGGEST_SYSTEM_PROMPT` | built-in | Replaces the system prompt for suggest |
| `CLAUDE_FISH_EXTRA_FLAGS` | none | Extra flags passed to `claude`; must be a fish list, e.g. `set -g CLAUDE_FISH_EXTRA_FLAGS --max-turns 3`. A single quoted string such as `'--max-turns 3'` is passed as one argument. Flags that change tools, permissions, settings or MCP (such as `--tools`, `--allowedTools`, `--permission-mode`, `--mcp-config`, `--settings`, `--add-dir`) are refused |

## Quoting

fish parses the line before `ask` or `explain` sees it. Quote any argument that holds `*`, `$`, `|`, `;`, `>` or `<`; an unmatched `*` is an error.

```fish
explain 'find . -name "*.log" | xargs rm'
ask 'how do I list files > 1MB?'
```

## Privacy

`explain` and the suggest key send the command line to the Claude API.

## Troubleshooting

- **`the 'claude' command was not found`**: install Claude Code and put it on `PATH`. Without it no keys are bound.
- **A key does nothing or does something else**: another binding took it. Run `bind | grep __ccf` to see what is bound, and set another key with the variables above.
- **Stray code fences in a suggestion**: the suggest key strips one surrounding fence or pair of backticks. If more appear, tighten `CLAUDE_FISH_SUGGEST_SYSTEM_PROMPT`.

## Manual test checklist

- [ ] `ask` and `explain` with `?`, `!`, `*` and quotes in the argument (quoted) give an answer, not a fish error
- [ ] Suggest key with a clear request ("list files by size") gives one command
- [ ] Suggest key with an ambiguous request still gives one command and does not run it
- [ ] Explain key prints an explanation and leaves the command line intact
- [ ] Logged out, `claude` failure gives a message, not a crash
- [ ] Custom keys work when set before the plugin loads

## License

MIT
