# Test helpers: a fake `claude` on PATH and a scratch dir per test.

function ccf_setup --description 'Put the stub claude first on PATH with a fresh temp dir'
    set -g CCF_SAVED_PATH $PATH
    set -g CCF_TMP (mktemp -d)
    touch $CCF_TMP/claude.log
    set -gx CCF_STUB_LOG $CCF_TMP/claude.log
    set -gx CCF_STUB_STDIN $CCF_TMP/stdin
    set -gx CCF_STUB_REPLY ''
    set -gx CCF_STUB_EXIT 0
    touch $CCF_TMP/auth.log
    set -gx CCF_STUB_AUTH_LOG $CCF_TMP/auth.log
    set -l stubs (path resolve (status dirname)/stubs)
    set -gx PATH $stubs $PATH
end

function ccf_logged_out --description 'Make the stub claude behave as logged out'
    touch $CCF_TMP/loggedout
    set -gx CCF_STUB_LOGGED_OUT $CCF_TMP/loggedout
end

function ccf_no_claude --description 'Make claude unfindable'
    set -gx PATH /usr/bin /bin
end

function ccf_teardown --description 'Undo ccf_setup'
    set -gx PATH $CCF_SAVED_PATH
    rm -rf $CCF_TMP
    set -e CCF_SAVED_PATH CCF_TMP CCF_STUB_LOG CCF_STUB_STDIN CCF_STUB_REPLY CCF_STUB_EXIT CCF_STUB_AUTH_LOG CCF_STUB_LOGGED_OUT CCF_STUB_LOGIN_OK
end

function ccf_calls --description 'number of claude calls that carried --print'
    count (string match -- --print <$CCF_STUB_LOG)
end

function ccf_logins --description 'number of times the stub claude was asked to log in'
    count (string match login <$CCF_TMP/auth.log)
end

function ccf_load_functions --description 'Put the worktree functions/ dir first on fish_function_path'
    set -p fish_function_path (path resolve (status dirname)/../functions)
end

function after --description 'line following flag $argv[1] in the log'
    set -l lines (cat $CCF_STUB_LOG)
    set -l i (contains -i -- $argv[1] $lines)
    echo $lines[(math $i + 1)]
end

# Shadow the builtin: record -r text and -f functions, serve a canned buffer for -b.
function commandline
    switch $argv[1]
        case -b
            printf %s $CCF_BUFFER
        case -r
            set -g CCF_REPLACED $argv[-1]
            set -g CCF_REPLACE_COUNT (math $CCF_REPLACE_COUNT + 1)
        case -f
            set -ga CCF_FUNCS $argv[2]
    end
end

function ccf_reset_commandline --description 'ccf_reset_commandline <buffer>; fresh state for the commandline shadow'
    set -g CCF_BUFFER $argv[1]
    set -g CCF_REPLACED
    set -g CCF_REPLACE_COUNT 0
    set -g CCF_FUNCS
end
