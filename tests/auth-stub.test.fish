set -g here (status dirname)
source $here/helpers.fish

# status, logged in
ccf_setup
set out (claude auth status </dev/null)
set code $status
@test "status logged in prints JSON" "$out" = '{"loggedIn": true}'
@test "status logged in exits 0" $code -eq 0
ccf_teardown

# status, logged out
ccf_setup
ccf_logged_out
set out (claude auth status </dev/null)
set code $status
@test "status logged out prints JSON" "$out" = '{"loggedIn": false}'
@test "status logged out exits 1" $code -eq 1
ccf_teardown

# login with CCF_STUB_LOGIN_OK=1 clears the logged-out state
ccf_setup
ccf_logged_out
set -gx CCF_STUB_LOGIN_OK 1
claude auth login </dev/null
set code $status
@test "login exits 0" $code -eq 0
test -e $CCF_STUB_LOGGED_OUT
@test "login ok removed the file" $status -ne 0
ccf_teardown

# login without it leaves the state
ccf_setup
ccf_logged_out
claude auth login </dev/null
set code $status
@test "login not ok exits 0" $code -eq 0
test -e $CCF_STUB_LOGGED_OUT
@test "login not ok keeps the file" $status -eq 0
ccf_teardown

# auth calls are logged to the auth log, never to the claude log
ccf_setup
claude auth status </dev/null >/dev/null
claude auth login </dev/null
@test "auth calls go to auth log" "$(string join , (cat $CCF_STUB_AUTH_LOG))" = status,login
@test "auth calls absent from claude log" (count (cat $CCF_STUB_LOG)) -eq 0
ccf_teardown

# a normal call while logged out
ccf_setup
ccf_logged_out
set out (claude --print hi </dev/null)
set code $status
@test "logged-out call prints hint" "$out" = 'Not logged in · Please run /login'
@test "logged-out call exits 1" $code -eq 1
@test "logged-out call still logs args" "$(string join , -- (cat $CCF_STUB_LOG))" = "--print,hi"
ccf_teardown

# teardown clears the auth variables
ccf_setup
ccf_logged_out
set -gx CCF_STUB_LOGIN_OK 1
ccf_teardown
@test "teardown clears auth vars" (count (set -n | string match -r '^CCF_STUB_(AUTH_LOG|LOGGED_OUT|LOGIN_OK)$')) -eq 0
