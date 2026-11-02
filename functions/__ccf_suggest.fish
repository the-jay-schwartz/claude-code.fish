function __ccf_suggest --description 'Replace the command line (a plain-English request) with one suggested command; never runs it'
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
        set reply (begin; __ccf_run suggest $buffer; set -g __ccf_status $status; end 2>| read -z err)
        set code $__ccf_status
        set -e __ccf_status

        set text
        test -n "$err"; and set text (string trim -c \n -- $err | string collect)
        test $code -eq 3; and test $attempt -eq 1; or break
        test (count $text) -gt 0; and __ccf_print_above $text >&2
        set text
        __ccf_offer_login suggest; or break
    end
    if test $code -eq 0
        # Drop a leading/trailing fence line, trim, then unwrap one pair of
        # backticks that surrounds a command containing none.
        set -l clean (string join \n -- $reply | string collect)
        set clean (string replace -r -- '\A\s*```[^\n]*\n' '' $clean | string collect)
        set clean (string replace -r -- '(\A|\n)[ \t]*```\s*\z' '' $clean | string collect)
        set clean (string trim -- $clean | string collect)
        set clean (string replace -r -- '\A`([^`]*)`\z' '$1' $clean | string collect)
        if string match -q -- "*"\n"*" $clean
            set -a text 'suggest: claude returned more than one line; not inserting'
        else if test -n "$clean"
            commandline -r -- $clean
        else
            set -a text 'suggest: claude returned no command'
        end
    end
    test (count $text) -gt 0; and __ccf_print_above $text >&2
    commandline -f repaint
end
