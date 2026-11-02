# A multi-line prompt repaints from several rows up, so each widget pads its output with
# one newline per extra prompt line, and starts its messages on a fresh row.
set -g here (status dirname)
source $here/helpers.fish
ccf_load_functions

functions -c fish_prompt ccf_saved_prompt
function fish_prompt
    echo one
    echo two
    echo -n '> '
end

# rows printed = blank start row + text rows + padding (prompt rows - 1)
@test "print_above pads one newline per extra prompt line" (__ccf_print_above hi | count) -eq 4

ccf_setup
set -gx CCF_STUB_REPLY 'lists files'
ccf_reset_commandline 'ls -la'
@test "explain pads its output" (__ccf_explain 2>/dev/null </dev/null | count) -eq 4
ccf_teardown

ccf_setup
set -gx CCF_STUB_REPLY oops
set -gx CCF_STUB_EXIT 1
ccf_reset_commandline ls
set err (__ccf_explain 2>&1 >/dev/null </dev/null | string collect)
@test "explain failure: message on its own row" "$err" = \nexplain:\ claude\ failed\ with\ status\ 1
@test "explain failure: message padded" (__ccf_explain 2>&1 >/dev/null </dev/null | count) -eq 4
ccf_teardown

ccf_setup
set -gx CCF_STUB_REPLY ls
set -gx CCF_STUB_EXIT 1
ccf_reset_commandline 'list files'
set err (__ccf_suggest 2>&1 >/dev/null </dev/null | string collect)
@test "suggest failure: message on its own row" "$err" = \nsuggest:\ claude\ failed\ with\ status\ 1
@test "suggest failure: message padded" (__ccf_suggest 2>&1 >/dev/null </dev/null | count) -eq 4
@test "suggest failure: no replace" $CCF_REPLACE_COUNT -eq 0
ccf_teardown

ccf_setup
set -gx CCF_STUB_REPLY 'cd /tmp
ls'
ccf_reset_commandline 'go and list'
@test "suggest rejection: message padded" (__ccf_suggest 2>&1 >/dev/null </dev/null | count) -eq 4
ccf_teardown

ccf_setup
set -gx CCF_STUB_REPLY ls
ccf_reset_commandline 'list files'
@test "suggest success: prints nothing" (__ccf_suggest 2>&1 </dev/null | count) -eq 0
@test "suggest success: replaces the line" "$CCF_REPLACED" = ls
ccf_teardown

functions -e fish_prompt
functions -c ccf_saved_prompt fish_prompt
functions -e ccf_saved_prompt
