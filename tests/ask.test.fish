set -g here (status dirname)
source $here/helpers.fish
ccf_load_functions

# question is last argument, words joined
ccf_setup
set -e CLAUDE_FISH_ASK_MODEL CLAUDE_FISH_ASK_SYSTEM_PROMPT CLAUDE_FISH_EXTRA_FLAGS
ask how do I list files </dev/null >/dev/null
set lines (cat $CCF_STUB_LOG)
@test "question is last argument" "$lines[-1]" = "how do I list files"
@test "-- immediately before question" "$lines[-2]" = --
@test "default model sonnet" (after --model) = sonnet
@test "built-in prompt used" (after --system-prompt) = (__ccf_default_prompt ask)
@test "fixed flags present" (string join , -- $lines[1..-3]) = (string join , -- --print --model sonnet --system-prompt (__ccf_default_prompt ask) --no-session-persistence --disable-slash-commands --tools "" --setting-sources user --strict-mcp-config)
ccf_teardown

# question starting with a dash is passed after --
ccf_setup
set -e CLAUDE_FISH_EXTRA_FLAGS
ask -h how </dev/null >/dev/null
set lines (cat $CCF_STUB_LOG)
@test "dash question after --" (string join , -- $lines[-2..-1]) = "--,-h how"
ccf_teardown

# model override and prompt override and extra flags
ccf_setup
set -gx CLAUDE_FISH_ASK_MODEL opus
set -gx CLAUDE_FISH_ASK_SYSTEM_PROMPT "be brief"
set -g CLAUDE_FISH_EXTRA_FLAGS --max-turns 3
ask hi </dev/null >/dev/null
@test "model override" (after --model) = opus
@test "prompt override" (after --system-prompt) = "be brief"
@test "extra flags appended before question" (string join , -- (cat $CCF_STUB_LOG)[-4..-1]) = "--max-turns,3,--,hi"
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

# set-but-empty overrides fall back to the defaults
ccf_setup
set -gx CLAUDE_FISH_ASK_MODEL ''
set -gx CLAUDE_FISH_ASK_SYSTEM_PROMPT ''
set -e CLAUDE_FISH_EXTRA_FLAGS
ask hi </dev/null >/dev/null
@test "empty model falls back to sonnet" (after --model) = sonnet
@test "empty prompt falls back to built-in" (after --system-prompt) = (__ccf_default_prompt ask)
set -e CLAUDE_FISH_ASK_MODEL CLAUDE_FISH_ASK_SYSTEM_PROMPT
ccf_teardown

# project settings, hooks and MCP servers are ignored
ccf_setup
set -e CLAUDE_FISH_EXTRA_FLAGS
ask hi </dev/null >/dev/null
set lines (cat $CCF_STUB_LOG)
@test "setting sources limited to user" (after --setting-sources) = user
@test "strict mcp config before --" (contains -i -- --strict-mcp-config $lines) -lt (contains -i -- -- $lines)
ccf_teardown

# extra flags may not change tools, permissions, settings or MCP
for flag in --tools --allowedTools --allowed-tools --dangerously-skip-permissions --permission-mode --mcp-config --settings --setting-sources --strict-mcp-config --add-dir
    ccf_setup
    set -g CLAUDE_FISH_EXTRA_FLAGS --max-turns 3 $flag=x
    ask hi 2>$CCF_TMP/err </dev/null >/dev/null
    set code $status
    @test "refuse $flag: status 2" $code -eq 2
    @test "refuse $flag: message" "$(cat $CCF_TMP/err)" = "ask: CLAUDE_FISH_EXTRA_FLAGS may not change tools, permissions, settings or MCP (found $flag=x)"
    @test "refuse $flag: no call" ! -s $CCF_STUB_LOG
    set -e CLAUDE_FISH_EXTRA_FLAGS
    ccf_teardown
end

# harmless extra flags still reach the call
ccf_setup
set -g CLAUDE_FISH_EXTRA_FLAGS --max-turns 3
ask hi </dev/null >/dev/null
@test "harmless extra flag reaches call" (after --max-turns) = 3
set -e CLAUDE_FISH_EXTRA_FLAGS
ccf_teardown
