set -g here (status dirname)
set -g root (path resolve $here/..)
source $root/completions/ask.fish
source $root/completions/explain.fish

@test "explain completes the command being explained" (contains -- git (complete -C 'explain gi' | string split -f1 \t); echo $status) = 0
@test "ask offers no files" (count (complete -C 'ask ')) = 0
