function explain --description "Explain a shell command: explain '<command>'"
    if test (count $argv) -eq 0
        echo "usage: explain <command>" >&2
        return 2
    end
    __ccf_run explain $argv
end
