function __ccf_explain --description 'Print an explanation of the command line above the prompt; leaves the command line untouched'
    set -l buffer (commandline -b | string collect)
    test -n "$buffer"; or return

    # Keep the call's stderr apart from the reply so it prints on its own row, clear of the repaint.
    # A logged-out call (status 3) is shown, then retried once if the user logs in.
    set -l err
    set -l reply
    set -l code
    set -l text
    for attempt in 1 2
        set err
        set reply (begin; __ccf_run explain $buffer; set -g __ccf_status $status; end 2>| read -z err)
        set code $__ccf_status
        set -e __ccf_status

        set text
        test -n "$err"; and set text (string trim -c \n -- $err | string collect)
        test $code -eq 3; and test $attempt -eq 1; or break
        test (count $text) -gt 0; and __ccf_print_above $text >&2
        set text
        __ccf_offer_login explain; or break
    end
    if test $code -eq 0
        __ccf_print_above $text $reply
    else if test -n "$text"
        __ccf_print_above $text >&2
    end
    commandline -f repaint
end
