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
    set -q $model_var; and set model $$model_var
    set -l prompt (__ccf_default_prompt $feature)
    set -q $prompt_var; and set prompt $$prompt_var

    claude --print --model $model --system-prompt (string join \n -- $prompt) \
        --no-session-persistence --disable-slash-commands --tools "" \
        $CLAUDE_FISH_EXTRA_FLAGS $question
    set -l code $status
    if test $code -ne 0
        echo "$feature: claude failed with status $code" >&2
    end
    return $code
end
