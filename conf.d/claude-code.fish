# Key bindings. Keys are read at load time: set the variables before the plugin loads.
# Without claude on PATH nothing is bound; ask and explain report that error themselves.
set -q CLAUDE_FISH_SUGGEST_KEY; or set CLAUDE_FISH_SUGGEST_KEY \cx
set -q CLAUDE_FISH_EXPLAIN_KEY; or set CLAUDE_FISH_EXPLAIN_KEY \ee

if command -q claude
    for mode in default insert
        bind -M $mode $CLAUDE_FISH_SUGGEST_KEY __ccf_suggest
        bind -M $mode $CLAUDE_FISH_EXPLAIN_KEY __ccf_explain
    end
end
