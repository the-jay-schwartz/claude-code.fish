# Test helpers: a fake `claude` on PATH and a scratch dir per test.

function ccf_setup --description 'Put the stub claude first on PATH with a fresh temp dir'
    set -g CCF_SAVED_PATH $PATH
    set -g CCF_TMP (mktemp -d)
    touch $CCF_TMP/claude.log
    set -gx CCF_STUB_LOG $CCF_TMP/claude.log
    set -gx CCF_STUB_STDIN $CCF_TMP/stdin
    set -gx CCF_STUB_REPLY ''
    set -gx CCF_STUB_EXIT 0
    set -l stubs (path resolve (status dirname)/stubs)
    set -gx PATH $stubs $PATH
end

function ccf_no_claude --description 'Make claude unfindable'
    set -gx PATH /usr/bin /bin
end

function ccf_teardown --description 'Undo ccf_setup'
    set -gx PATH $CCF_SAVED_PATH
    rm -rf $CCF_TMP
    set -e CCF_SAVED_PATH CCF_TMP CCF_STUB_LOG CCF_STUB_STDIN CCF_STUB_REPLY CCF_STUB_EXIT
end
