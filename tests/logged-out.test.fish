set -g here (status dirname)
source $here/helpers.fish
ccf_load_functions

# __ccf_logged_out
ccf_setup
ccf_logged_out
__ccf_logged_out
@test "logged out detected" $status -eq 0
ccf_teardown

ccf_setup
__ccf_logged_out
@test "logged in is not logged out" $status -eq 1
ccf_teardown

ccf_setup
ccf_no_claude
__ccf_logged_out
@test "missing claude is not logged out" $status -eq 1
ccf_teardown

# __ccf_run logged out
ccf_setup
ccf_logged_out
set -l out (__ccf_run ask hi 2>$CCF_TMP/err)
set -l code $status
@test "logged out status 3" $code -eq 3
@test "logged out stdout empty" -z "$out"
@test "logged out message on stderr" (cat $CCF_TMP/err) = "ask: claude is not logged in; run 'claude auth login'"
ccf_teardown

# failure while logged in is unchanged
ccf_setup
set -gx CCF_STUB_REPLY partial
set -gx CCF_STUB_EXIT 1
set -l out (__ccf_run explain hi 2>$CCF_TMP/err)
set -l code $status
@test "logged-in failure status" $code -eq 1
@test "logged-in failure keeps stdout" "$out" = partial
@test "logged-in failure message" (cat $CCF_TMP/err) = "explain: claude failed with status 1"
ccf_teardown
