set -g here (status dirname)
source $here/helpers.fish
ccf_load_functions

function run_suggest --description 'run_suggest <buffer>'
    ccf_reset_commandline $argv[1]
    __ccf_suggest </dev/null >/dev/null 2>&1
end

ccf_setup
set -gx CCF_STUB_REPLY '```bash
ls -la
```'
run_suggest 'list files'
@test "fence with tag removed" "$CCF_REPLACED" = 'ls -la'
@test "repaints" "$CCF_FUNCS" = repaint
ccf_teardown

ccf_setup
set -gx CCF_STUB_REPLY '`ls -la`'
run_suggest 'list files'
@test "single backticks removed" "$CCF_REPLACED" = 'ls -la'
ccf_teardown

ccf_setup
set -gx CCF_STUB_REPLY '

   ls -la   

'
run_suggest 'list files'
@test "whitespace trimmed" "$CCF_REPLACED" = 'ls -la'
ccf_teardown

ccf_setup
set -gx CCF_STUB_REPLY 'echo `date`'
run_suggest 'print date'
@test "inner backticks kept" "$CCF_REPLACED" = 'echo `date`'
ccf_teardown

ccf_setup
set -gx CCF_STUB_REPLY 'cd /tmp
ls'
ccf_reset_commandline 'go and list'
set err (__ccf_suggest </dev/null 2>&1 >/dev/null | string collect)
@test "multi-line reply is rejected" $CCF_REPLACE_COUNT -eq 0 -a -z "$CCF_REPLACED" -a "$CCF_BUFFER" = 'go and list' -a "$err" = 'suggest: claude returned more than one line; not inserting' -a "$CCF_FUNCS" = repaint
ccf_teardown

ccf_setup
set -gx CCF_STUB_REPLY 'echo hi
'
run_suggest 'say hi'
@test "trailing newline still lands" "$CCF_REPLACED" = 'echo hi'
ccf_teardown

ccf_setup
set -gx CCF_STUB_REPLY 'ls'
set -gx CCF_STUB_EXIT 1
run_suggest 'list files'
@test "failure: no replace" $CCF_REPLACE_COUNT -eq 0
@test "failure: still repaints" "$CCF_FUNCS" = repaint
ccf_teardown

ccf_setup
run_suggest ''
@test "empty buffer: no call" ! -s $CCF_STUB_LOG
@test "empty buffer: no replace" $CCF_REPLACE_COUNT -eq 0
ccf_teardown

ccf_setup
set -gx CCF_STUB_REPLY "touch $CCF_TMP/ran"
run_suggest 'make a file'
@test "suggested command not executed" ! -e $CCF_TMP/ran
ccf_teardown

ccf_setup
set -e CLAUDE_FISH_SUGGEST_MODEL
set -gx CCF_STUB_REPLY ls
run_suggest 'list'
set lines (cat $CCF_STUB_LOG)
@test "default model haiku" $lines[(math (contains -i -- --model $lines) + 1)] = haiku
ccf_teardown

for reply in '' '```
```' '  
 '
    ccf_setup
    set -gx CCF_STUB_REPLY $reply
    ccf_reset_commandline 'list files'
    set err (__ccf_suggest </dev/null 2>&1 >/dev/null | string collect)
    @test "empty reply: buffer untouched" $CCF_REPLACE_COUNT -eq 0
    @test "empty reply: message on stderr" "$err" = 'suggest: claude returned no command'
    @test "empty reply: still repaints" "$CCF_FUNCS" = repaint
    ccf_teardown
end
