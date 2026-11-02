function __ccf_suggest --description 'Replace the command line (a plain-English request) with one suggested command; never runs it'
    set -l buffer (commandline -b | string collect)
    test -n "$buffer"; or return

    # Keep the call's stderr apart from the reply so it prints on its own row, clear of the repaint.
    set -l err
    set -l reply (begin; __ccf_run suggest $buffer; set -g __ccf_status $status; end 2>| read -z err)
    set -l code $__ccf_status
    set -e __ccf_status

    set -l text
    test -n "$err"; and set text (string trim -c \n -- $err | string collect)
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
