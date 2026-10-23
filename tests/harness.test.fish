set -g here (status dirname)
source $here/helpers.fish

# stub logs each argument on its own line
ccf_setup
claude --print hi </dev/null
@test "stub logs arguments one per line" "$(string join , -- (cat $CCF_STUB_LOG))" = "--print,hi"

# reply and exit status
set -gx CCF_STUB_REPLY pong
set -gx CCF_STUB_EXIT 3
set out (claude --print x </dev/null)
set code $status
@test "stub prints reply" "$out" = pong
@test "stub exits with CCF_STUB_EXIT" $code -eq 3

# stdin capture
set -gx CCF_STUB_EXIT 0
set -gx CCF_STUB_REPLY ""
echo piped | claude --print
@test "stub records stdin" (cat $CCF_STUB_STDIN) = piped
ccf_teardown

# no claude
ccf_setup
ccf_no_claude
command -q claude
@test "claude not found after ccf_no_claude" $status -ne 0
ccf_teardown

# teardown
set before $PATH
ccf_setup
set tmp $CCF_TMP
ccf_teardown
@test "teardown restores PATH" (string join : $PATH) = (string join : $before)
@test "teardown removes tmp dir" ! -e $tmp
@test "teardown erases globals" -z "$CCF_TMP$CCF_SAVED_PATH$CCF_STUB_LOG$CCF_STUB_STDIN$CCF_STUB_REPLY$CCF_STUB_EXIT"
