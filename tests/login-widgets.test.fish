set -g here (status dirname)
source $here/helpers.fish
ccf_load_functions

# $argv[1] widget, $argv[2] answer; stderr (the messages) lands in $CCF_TMP/err
function run_widget
    ccf_reset_commandline 'say hi'
    echo $argv[2] | $argv[1] >$CCF_TMP/out 2>$CCF_TMP/err
end

for w in suggest explain
    # y, login works: retried once, result handled normally
    ccf_setup
    ccf_logged_out
    set -gx CCF_STUB_LOGIN_OK 1
    set -gx CCF_STUB_REPLY 'echo hi'
    run_widget __ccf_$w y
    @test "$w: login then retry calls claude twice" (ccf_calls) -eq 2
    @test "$w: login then retry logs in once" (ccf_logins) -eq 1
    @test "$w: logged-out message shown first" (string match -q '*not logged in*' <$CCF_TMP/err; echo $status) -eq 0
    @test "$w: login then retry repaints once" "$CCF_FUNCS" = repaint
    @test "$w: logged-out message not repeated after the retry" (count (string match '*not logged in*' <$CCF_TMP/err)) -eq 1
    if test $w = suggest
        @test "suggest: login then retry inserts command" "$CCF_REPLACED" = 'echo hi'
    else
        @test "explain: login then retry prints explanation" (string match -q '*echo hi*' <$CCF_TMP/out; echo $status) -eq 0
        @test "explain: buffer untouched" $CCF_REPLACE_COUNT -eq 0
    end
    ccf_teardown

    # n: message shown, no login
    ccf_setup
    ccf_logged_out
    set -gx CCF_STUB_LOGIN_OK 1
    set -gx CCF_STUB_REPLY 'echo hi'
    run_widget __ccf_$w n
    @test "$w: n does not log in" (ccf_logins) -eq 0
    @test "$w: n calls claude once" (ccf_calls) -eq 1
    @test "$w: n leaves buffer" $CCF_REPLACE_COUNT -eq 0
    @test "$w: n shows the message" (string match -q '*not logged in*' <$CCF_TMP/err; echo $status) -eq 0
    @test "$w: n repaints once" "$CCF_FUNCS" = repaint
    ccf_teardown

    # y but login does not take
    ccf_setup
    ccf_logged_out
    set -gx CCF_STUB_REPLY 'echo hi'
    run_widget __ccf_$w y
    @test "$w: failed login leaves buffer" $CCF_REPLACE_COUNT -eq 0
    @test "$w: failed login calls claude once" (ccf_calls) -eq 1
    @test "$w: failed login repaints once" "$CCF_FUNCS" = repaint
    ccf_teardown

    # failure while logged in: no offer
    ccf_setup
    set -gx CCF_STUB_EXIT 1
    run_widget __ccf_$w y
    @test "$w: logged-in failure does not log in" (ccf_logins) -eq 0
    @test "$w: logged-in failure calls claude once" (ccf_calls) -eq 1
    @test "$w: logged-in failure repaints once" "$CCF_FUNCS" = repaint
    ccf_teardown
end

functions -e run_widget
