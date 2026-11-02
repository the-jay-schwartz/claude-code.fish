function ask --description 'Ask a terse shell question: ask <question>'
    if test (count $argv) -eq 0
        echo "usage: ask <question>" >&2
        return 2
    end
    __ccf_run ask $argv
    set -l code $status
    # Logged out: offer to log in on a terminal, then retry once.
    if test $code -eq 3; and isatty stdin; and isatty stderr; and __ccf_offer_login ask
        __ccf_run ask $argv
        return $status
    end
    return $code
end
