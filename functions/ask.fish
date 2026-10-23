function ask --description 'Ask a terse shell question: ask <question>'
    if test (count $argv) -eq 0
        echo "usage: ask <question>" >&2
        return 2
    end
    __ccf_run ask $argv
end
