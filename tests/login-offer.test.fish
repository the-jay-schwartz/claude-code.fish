set -g here (status dirname)
source $here/helpers.fish
ccf_load_functions

ccf_setup
ccf_logged_out
set -gx CCF_STUB_LOGIN_OK 1
printf y | __ccf_offer_login ask >$CCF_TMP/out 2>$CCF_TMP/err
set -l code $status
@test "y with working login returns 0" $code -eq 0
@test "y runs login once" (ccf_logins) -eq 1
@test "prompt on stderr" (string match -q -e "Log in now? [y/N] " -- (cat $CCF_TMP/err | string collect); echo $status) = 0
@test "stdout empty" ! -s $CCF_TMP/out
ccf_teardown

ccf_setup
ccf_logged_out
printf Y | __ccf_offer_login ask 2>/dev/null
@test "capital Y accepted" $status -eq 1
@test "capital Y runs login" (ccf_logins) -eq 1
ccf_teardown

for input in n '\n' ''
    ccf_setup
    ccf_logged_out
    set -gx CCF_STUB_LOGIN_OK 1
    printf $input | __ccf_offer_login ask >/dev/null 2>&1
    set -l code $status
    @test "declined ('$input') returns 1" $code -eq 1
    @test "declined ('$input') does not log in" (ccf_logins) -eq 0
    ccf_teardown
end

ccf_setup
ccf_logged_out
printf y | __ccf_offer_login ask >/dev/null 2>$CCF_TMP/err
set -l code $status
@test "failed login returns 1" $code -eq 1
@test "failed login message" (string match -q '*ask: still not logged in*' (cat $CCF_TMP/err | string collect); and echo ok) = ok
ccf_teardown
