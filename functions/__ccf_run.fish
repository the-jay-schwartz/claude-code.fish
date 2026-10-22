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
    set -l model sonnet
    test -n "$$model_var"; and set model $$model_var
    set -l prompt (__ccf_default_prompt $feature)
    test -n "$$prompt_var"; and set prompt $$prompt_var

    # Extra flags must not re-enable tools or load settings/MCP (flag order gives no protection).
    set -l forbidden --tools --allowedTools --allowed-tools --dangerously --permission-mode \
        --mcp-config --settings --setting-sources --strict-mcp-config --add-dir
    for token in $CLAUDE_FISH_EXTRA_FLAGS
        for prefix in $forbidden
            if string match -q -- "$prefix*" $token
                echo "$feature: CLAUDE_FISH_EXTRA_FLAGS may not change tools, permissions, settings or MCP (found $token)" >&2
                return 2
            end
        end
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
