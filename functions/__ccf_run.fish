function __ccf_run --description 'Run a one-shot, tool-less claude call: __ccf_run <ask|explain|suggest> <question words...>'
    set -l feature $argv[1]
    set -l question (string join ' ' -- $argv[2..-1])
    set -l upper (string upper -- $feature)

    if not command -q claude
        echo "$feature: the 'claude' command was not found; install Claude Code and make sure it is on your PATH" >&2
        return 1
    end

    set -l model_var CLAUDE_FISH_{$upper}_MODEL
    set -l prompt_var CLAUDE_FISH_{$upper}_SYSTEM_PROMPT
    # Suggest writes one short command, where haiku matches sonnet at about a
    # sixteenth of the cost; ask and explain write prose, where sonnet is tighter.
    set -l model sonnet
    test "$feature" = suggest; and set model haiku
    test -n "$$model_var"; and set model $$model_var
    set -l prompt (__ccf_default_prompt $feature)
    test -n "$$prompt_var"; and set prompt $$prompt_var

    # Extra flags are allowlisted: a dash token must be one of these flags (or flag=value),
    # so nothing can re-enable tools or load settings/MCP, whatever the flag order.
    for token in $CLAUDE_FISH_EXTRA_FLAGS
        string match -q -- '-*' $token; or continue
        string match -qr -- '^(--effort|--max-budget-usd|--fallback-model)(=.*)?$' $token; and continue
        echo "$feature: CLAUDE_FISH_EXTRA_FLAGS may not change tools, permissions, settings or MCP (found $token)" >&2
        return 2
    end

    claude --print --model $model --system-prompt (string join \n -- $prompt) \
        --no-session-persistence --disable-slash-commands --tools "" \
        --setting-sources user --strict-mcp-config \
        $CLAUDE_FISH_EXTRA_FLAGS -- $question
    set -l code $status
    if test $code -ne 0
        echo "$feature: claude failed with status $code" >&2
    end
    return $code
end
