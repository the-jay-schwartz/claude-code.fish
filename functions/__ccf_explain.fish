function __ccf_explain --description 'Print an explanation of the command line above the prompt; leaves the command line untouched'
    set -l buffer (commandline -b | string collect)
    test -n "$buffer"; or return

    # Keep the call's stderr apart from the reply so it prints on its own row, clear of the repaint.
    set -l err
    set -l reply (begin; __ccf_run explain $buffer; set -g __ccf_status $status; end 2>| read -z err)
    set -l code $__ccf_status
    set -e __ccf_status

    set -l text
    test -n "$err"; and set text (string trim -c \n -- $err | string collect)
    if test $code -eq 0
        __ccf_print_above $text $reply
    else if test -n "$text"
        __ccf_print_above $text >&2
    end
    commandline -f repaint
end
