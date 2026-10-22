set -g here (status dirname)
source $here/helpers.fish
set -g fdir (path resolve $here/../functions)
set -p fish_function_path $fdir

function args
    cat $CCF_STUB_LOG
end

function after --description 'line following flag $argv[1] in the log'
    set -l lines (cat $CCF_STUB_LOG)
    set -l i (contains -i -- $argv[1] $lines)
    echo $lines[(math $i + 1)]
end

# question is last argument, words joined
ccf_setup
set -e CLAUDE_FISH_ASK_MODEL CLAUDE_FISH_ASK_SYSTEM_PROMPT CLAUDE_FISH_EXTRA_FLAGS
ask how do I list files </dev/null >/dev/null
set lines (args)
@test "question is last argument" "$lines[-1]" = "how do I list files"
@test "default model sonnet" (after --model) = sonnet
@test "built-in prompt used" (after --system-prompt) = (__ccf_default_prompt ask)
@test "fixed flags present" (string join , -- $lines[1..-2]) = (string join , -- --print --model sonnet --system-prompt (__ccf_default_prompt ask) --no-session-persistence --disable-slash-commands --tools "")
ccf_teardown

# model override and prompt override and extra flags
ccf_setup
set -gx CLAUDE_FISH_ASK_MODEL opus
set -gx CLAUDE_FISH_ASK_SYSTEM_PROMPT "be brief"
set -g CLAUDE_FISH_EXTRA_FLAGS --max-turns 3
ask hi </dev/null >/dev/null
@test "model override" (after --model) = opus
@test "prompt override" (after --system-prompt) = "be brief"
@test "extra flags appended before question" (string join , -- (args)[-3..-1]) = "--max-turns,3,hi"
set -e CLAUDE_FISH_ASK_MODEL CLAUDE_FISH_ASK_SYSTEM_PROMPT CLAUDE_FISH_EXTRA_FLAGS
ccf_teardown

# stdout passthrough
ccf_setup
set -gx CCF_STUB_REPLY pong
@test "stdout passthrough" (ask hi </dev/null) = pong
ccf_teardown

# claude absent
ccf_setup
ccf_no_claude
set out (ask hi 2>$CCF_TMP/err </dev/null)
set code $status
@test "absent: status 1" $code -eq 1
@test "absent: stdout empty" -z "$out"
@test "absent: stderr message" -s $CCF_TMP/err
set -gx PATH $CCF_SAVED_PATH
ccf_teardown

# claude fails
ccf_setup
set -gx CCF_STUB_EXIT 2
ask hi 2>$CCF_TMP/err </dev/null >/dev/null
set code $status
@test "failure: status 2" $code -eq 2
@test "failure: stderr message" -s $CCF_TMP/err
ccf_teardown

# no arguments
ccf_setup
ask 2>$CCF_TMP/err </dev/null
set code $status
@test "no args: status 2" $code -eq 2
@test "no args: usage" (cat $CCF_TMP/err) = "usage: ask <question>"
@test "no args: no call" ! -s $CCF_STUB_LOG
ccf_teardown
