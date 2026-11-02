function __ccf_print_above --description 'Print lines on fresh rows below the command line, padded for the repaint: __ccf_print_above <line...>'
    # The cursor is on the command line. The repaint that follows starts one row up per extra
    # prompt line, so a multi-line prompt would draw over the last rows printed here. One
    # newline per extra prompt line keeps the output clear of it.
    echo
    string join \n -- $argv
    string repeat -N -n (math "max(0, "(count (fish_prompt))" - 1)") \n
end
