set -g here (status dirname)
source $here/helpers.fish
set -g fdir (path resolve $here/../functions)
set -p fish_function_path $fdir

function after --description 'line following flag $argv[1] in the log'
    set -l lines (cat $CCF_STUB_LOG)
    set -l i (contains -i -- $argv[1] $lines)
    echo $lines[(math $i + 1)]
end

# quoted command is sent verbatim as the last argument
ccf_setup
set -e CLAUDE_FISH_EXPLAIN_MODEL CLAUDE_FISH_EXPLAIN_SYSTEM_PROMPT CLAUDE_FISH_EXTRA_FLAGS
explain 'find . -type f | sort' </dev/null >/dev/null
set lines (cat $CCF_STUB_LOG)
@test "quoted command is last argument" "$lines[-1]" = "find . -type f | sort"
@test "-- before command" "$lines[-2]" = --
@test "default model sonnet" (after --model) = sonnet
ccf_teardown

# unquoted words joined with single spaces
ccf_setup
explain ls -la /tmp </dev/null >/dev/null
set lines (cat $CCF_STUB_LOG)
@test "words joined" "$lines[-1]" = "ls -la /tmp"
ccf_teardown

# overrides
ccf_setup
set -gx CLAUDE_FISH_EXPLAIN_MODEL opus
set -gx CLAUDE_FISH_EXPLAIN_SYSTEM_PROMPT "be brief"
explain ls </dev/null >/dev/null
@test "model override" (after --model) = opus
@test "prompt override" (after --system-prompt) = "be brief"
set -e CLAUDE_FISH_EXPLAIN_MODEL CLAUDE_FISH_EXPLAIN_SYSTEM_PROMPT
ccf_teardown

# claude absent
ccf_setup
ccf_no_claude
set out (explain ls 2>$CCF_TMP/err </dev/null)
set code $status
@test "absent: status 1" $code -eq 1
@test "absent: stdout empty" -z "$out"
@test "absent: stderr message" -s $CCF_TMP/err
set -gx PATH $CCF_SAVED_PATH
ccf_teardown

# no arguments
ccf_setup
explain 2>$CCF_TMP/err </dev/null
set code $status
@test "no args: status 2" $code -eq 2
@test "no args: usage" (cat $CCF_TMP/err) = "usage: explain <command>"
@test "no args: no call" ! -s $CCF_STUB_LOG
ccf_teardown
