function __ccf_explain --description 'Print an explanation of the command line above the prompt; leaves the command line untouched'
    set -l buffer (commandline -b | string collect)
    test -n "$buffer"; or return

    set -l reply (__ccf_run explain $buffer)
    if test $status -eq 0
        echo
        string join \n -- $reply
    end
    commandline -f repaint
end
