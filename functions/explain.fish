function explain --description "Explain a shell command: explain '<command>'"
    if test (count $argv) -eq 0
        echo "usage: explain <command>" >&2
        return 2
    end
    __ccf_run explain $argv
    set -l code $status
    # Logged out: offer to log in on a terminal, then retry once.
    if test $code -eq 3; and isatty stdin; and isatty stderr; and __ccf_offer_login explain
        __ccf_run explain $argv
        return $status
    end
    return $code
end
