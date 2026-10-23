set -g here (status dirname)
source $here/helpers.fish
ccf_load_functions

function run_explain --description 'run_explain <buffer>; stdout to $CCF_OUT'
    ccf_reset_commandline $argv[1]
    set -g CCF_OUT (__ccf_explain 2>/dev/null </dev/null | string collect)
end

ccf_setup
set -gx CCF_STUB_REPLY 'lists files'
run_explain 'ls -la'
@test "explanation on stdout after blank line" "$CCF_OUT" = \nlists\ files
@test "buffer not replaced" $CCF_REPLACE_COUNT -eq 0
@test "repaints" "$CCF_FUNCS" = repaint
ccf_teardown

ccf_setup
run_explain ''
@test "empty buffer: no call" ! -s $CCF_STUB_LOG
ccf_teardown

ccf_setup
set -gx CCF_STUB_REPLY oops
set -gx CCF_STUB_EXIT 1
run_explain 'ls'
@test "failure: no replace" $CCF_REPLACE_COUNT -eq 0
@test "failure: still repaints" "$CCF_FUNCS" = repaint
@test "failure: no stdout" -z "$CCF_OUT"
ccf_teardown

ccf_setup
set -gx CLAUDE_FISH_EXPLAIN_MODEL opus
set -gx CCF_STUB_REPLY ok
run_explain 'ls'
set lines (cat $CCF_STUB_LOG)
@test "uses explain model" $lines[(math (contains -i -- --model $lines) + 1)] = opus
set -e CLAUDE_FISH_EXPLAIN_MODEL
ccf_teardown
