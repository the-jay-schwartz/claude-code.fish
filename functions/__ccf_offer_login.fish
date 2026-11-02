function __ccf_offer_login --description 'Offer to run `claude auth login`; succeed iff the user ends up logged in'
    set -l feature $argv[1]
    printf 'Log in now? [y/N] ' >&2
    # -P '': on a terminal read draws its own "read> " prompt over ours.
    read -n 1 -P '' key; or begin
        echo >&2
        return 1
    end
    echo >&2
    string match -qi y -- $key; or return 1

    # A widget leaves the terminal in raw-ish modes; the login child needs sane
    # ones to receive pasted input. Skip when stty is missing or stdin is no tty.
    set -l modes
    if command -q stty
        set modes (stty -g 2>/dev/null)
        or set modes
    end
    test -n "$modes"; and stty sane
    claude auth login
    test -n "$modes"; and stty $modes

    # The login exits 0 even on Ctrl+C, so judge success by the auth state.
    if __ccf_logged_out
        echo "$feature: still not logged in" >&2
        return 1
    end
end
