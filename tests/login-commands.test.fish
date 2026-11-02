set -g here (status dirname)
source $here/helpers.fish
ccf_load_functions

# Pretend stdin and stderr are a terminal; the answer still comes through a pipe.
function isatty
    return 0
end

for cmd in ask explain
    # logged out, terminal, y, login works: retry succeeds
    ccf_setup
    ccf_logged_out
    set -gx CCF_STUB_LOGIN_OK 1
    set -gx CCF_STUB_REPLY pong
    set -l out (echo y | $cmd what 2>/dev/null)
    set -l code $status
    @test "$cmd: login then retry returns 0" $code -eq 0
    @test "$cmd: login then retry prints reply" "$out" = pong
    @test "$cmd: login then retry calls claude twice" (ccf_calls) -eq 2
    @test "$cmd: login then retry asks the question both times" (count (string match -- what <$CCF_STUB_LOG)) -eq 2
    ccf_teardown

    # not a terminal: no offer
    ccf_setup
    ccf_logged_out
    set -gx CCF_STUB_LOGIN_OK 1
    functions -e isatty
    echo y | $cmd what >/dev/null 2>$CCF_TMP/err
    set -l code $status
    function isatty
        return 0
    end
    @test "$cmd: no terminal returns 3" $code -eq 3
    @test "$cmd: no terminal prints the hint" (cat $CCF_TMP/err) = "$cmd: claude is not logged in; run 'claude auth login'"
    @test "$cmd: no terminal does not log in" (ccf_logins) -eq 0
    ccf_teardown

    # n: declined
    ccf_setup
    ccf_logged_out
    set -gx CCF_STUB_LOGIN_OK 1
    echo n | $cmd what >/dev/null 2>&1
    set -l code $status
    @test "$cmd: n returns 3" $code -eq 3
    @test "$cmd: n does not log in" (ccf_logins) -eq 0
    ccf_teardown

    # y but the login does not take: one call only
    ccf_setup
    ccf_logged_out
    echo y | $cmd what >/dev/null 2>&1
    set -l code $status
    @test "$cmd: failed login returns 3" $code -eq 3
    @test "$cmd: failed login runs claude once" (ccf_calls) -eq 1
    ccf_teardown

    # failure while logged in: no offer
    ccf_setup
    set -gx CCF_STUB_EXIT 1
    echo y | $cmd what >/dev/null 2>&1
    set -l code $status
    @test "$cmd: logged-in failure keeps status" $code -eq 1
    @test "$cmd: logged-in failure does not log in" (ccf_logins) -eq 0
    ccf_teardown
end

functions -e isatty ccf_calls ccf_logins
