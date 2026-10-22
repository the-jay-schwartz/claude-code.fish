function __ccf_suggest --description 'Replace the command line (a plain-English request) with one suggested command; never runs it'
    set -l buffer (commandline -b | string collect)
    test -n "$buffer"; or return

    set -l reply (__ccf_run suggest $buffer)
    if test $status -eq 0
        # Drop a leading/trailing fence line, trim, then unwrap one pair of
        # backticks that surrounds a command containing none.
        set -l clean (string join \n -- $reply | string collect)
        set clean (string replace -r -- '\A\s*```[^\n]*\n' '' $clean | string collect)
        set clean (string replace -r -- '(\A|\n)[ \t]*```\s*\z' '' $clean | string collect)
        set clean (string trim -- $clean | string collect)
        set clean (string replace -r -- '\A`([^`]*)`\z' '$1' $clean | string collect)
        if string match -q -- "*"\n"*" $clean
            echo 'suggest: claude returned more than one line; not inserting' >&2
        else if test -n "$clean"
            commandline -r -- $clean
        else
            echo 'suggest: claude returned no command' >&2
        end
    end
    commandline -f repaint
end
