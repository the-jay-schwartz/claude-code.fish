set -g here (status dirname)
source $here/helpers.fish
set -g root (path resolve $here/..)
set -g fish_bin (command -s fish)

function load_plugin --description 'load_plugin <query>; source conf.d in a child fish, then run the query'
    $fish_bin -N -c "set fish_function_path $root/functions \$fish_function_path
source $root/conf.d/claude-code.fish
$argv" 2>&1 </dev/null | string collect
end

ccf_setup
@test "default: Ctrl+X binds suggest" (string match -rq '__ccf_suggest' -- (load_plugin 'bind \cx'); echo $status) = 0
@test "default: Alt+E binds explain" (string match -rq '__ccf_explain' -- (load_plugin 'bind \ee'); echo $status) = 0
@test "insert mode: Ctrl+X binds suggest" (string match -rq '__ccf_suggest' -- (load_plugin 'bind -M insert \cx'); echo $status) = 0
@test "insert mode: Alt+E binds explain" (string match -rq '__ccf_explain' -- (load_plugin 'bind -M insert \ee'); echo $status) = 0
@test "custom keys: suggest" (string match -rq '__ccf_suggest' -- (load_plugin 'set -g CLAUDE_FISH_SUGGEST_KEY \cg; source '$root'/conf.d/claude-code.fish; bind \cg'); echo $status) = 0
ccf_teardown

ccf_setup
set -g pre "set -g CLAUDE_FISH_SUGGEST_KEY \\cg; set -g CLAUDE_FISH_EXPLAIN_KEY \\ek;"
set -g custom_out ($fish_bin -N -c "$pre set fish_function_path $root/functions \$fish_function_path; source $root/conf.d/claude-code.fish; bind \\cg; bind \\ek; bind -M insert \\cg; bind -M insert \\ek" 2>&1 </dev/null | string collect)
@test "custom suggest key bound" (string match -rq 'bind ctrl-g __ccf_suggest' -- $custom_out; echo $status) = 0
@test "custom explain key bound" (string match -rq 'bind alt-k __ccf_explain' -- $custom_out; echo $status) = 0
@test "custom keys bound in insert mode" (string match -rq 'bind -M insert alt-k __ccf_explain' -- $custom_out; echo $status) = 0
ccf_teardown

ccf_setup
ccf_no_claude
set -g nc_out ($fish_bin -N -c "set fish_function_path $root/functions \$fish_function_path; source $root/conf.d/claude-code.fish" 2>&1 </dev/null | string collect)
$fish_bin -N -c "set fish_function_path $root/functions \$fish_function_path; source $root/conf.d/claude-code.fish" >/dev/null 2>&1 </dev/null
set -g nc_status $status

set -g nc_bind ($fish_bin -N -c "set fish_function_path $root/functions \$fish_function_path; source $root/conf.d/claude-code.fish; bind; bind -M insert" 2>&1 </dev/null | string collect)
@test "no claude: prints nothing" -z "$nc_out"
@test "no claude: exit 0" $nc_status -eq 0
@test "no claude: no suggest binding" (string match -q '*__ccf_suggest*' -- $nc_bind; echo $status) = 1
@test "no claude: no explain binding" (string match -q '*__ccf_explain*' -- $nc_bind; echo $status) = 1
ccf_teardown
