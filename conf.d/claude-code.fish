# Key bindings. fish sources conf.d before config.fish, so the keys are read and bound at the
# first prompt, after config.fish has set CLAUDE_FISH_SUGGEST_KEY and CLAUDE_FISH_EXPLAIN_KEY.
# Without claude on PATH nothing is bound; ask and explain report that error themselves.
function __ccf_bind_keys --on-event fish_prompt
    functions -e __ccf_bind_keys
    command -q claude; or return

    set -q CLAUDE_FISH_SUGGEST_KEY; or set CLAUDE_FISH_SUGGEST_KEY \cx
    set -q CLAUDE_FISH_EXPLAIN_KEY; or set CLAUDE_FISH_EXPLAIN_KEY \ee

    for mode in default insert
        bind -M $mode $CLAUDE_FISH_SUGGEST_KEY __ccf_suggest
        bind -M $mode $CLAUDE_FISH_EXPLAIN_KEY __ccf_explain
    end
end
