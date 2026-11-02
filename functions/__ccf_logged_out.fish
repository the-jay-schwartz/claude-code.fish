function __ccf_logged_out --description 'Succeed iff `claude auth status` reports loggedIn false (the exit code is ignored)'
    command -q claude; or return 1
    string match -qr -- '"loggedIn":\s*false' (claude auth status 2>/dev/null | string collect)
end
