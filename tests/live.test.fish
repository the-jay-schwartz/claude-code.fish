# Live smoke test against the real claude. Runs only with CCF_LIVE=1 (makes a few small API calls).
set -g here (status dirname)
source $here/helpers.fish
ccf_load_functions

if test "$CCF_LIVE" != 1
    @test "live: skipped (set CCF_LIVE=1 to run against the real claude)" 1 -eq 1
else if not command -q claude
    @test "live: claude must be on PATH when CCF_LIVE=1" (echo "claude not found on PATH" >&2; echo 1) -eq 0
else
    set -e CLAUDE_FISH_ASK_MODEL CLAUDE_FISH_ASK_SYSTEM_PROMPT CLAUDE_FISH_EXPLAIN_MODEL CLAUDE_FISH_EXPLAIN_SYSTEM_PROMPT CLAUDE_FISH_EXTRA_FLAGS

    set out (ask reply with the single word OK </dev/null)
    set code $status
    @test "live: ask returns 0" $code -eq 0
    @test "live: ask prints OK" (string match -q -- '*OK*' "$out"; echo $status) -eq 0

    set out (ask -h reply with the single word OK </dev/null)
    set code $status
    @test "live: ask with leading dash returns 0" $code -eq 0
    @test "live: ask with leading dash prints OK" (string match -q -- '*OK*' "$out"; echo $status) -eq 0

    set out (explain 'ls -la' </dev/null)
    set code $status
    @test "live: explain returns 0" $code -eq 0
    @test "live: explain prints a reply" -n "$out"

    set out (ask 'List the names of the tools you can call, comma separated, or say NONE. Nothing else.' </dev/null)
    @test "live: ask has no tools" (string match -q -- '*NONE*' "$out"; echo $status) -eq 0
end
