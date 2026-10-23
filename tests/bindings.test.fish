set -g here (status dirname)
source $here/helpers.fish
set -g root (path resolve $here/..)
set -g fish_bin (command -s fish)

function load_plugin --description 'load_plugin <query> [pre-source snippet]; source conf.d in a child fish, then run the query; child exit status in $load_plugin_status'
    set -l out ($fish_bin -N -c "$argv[2]
set fish_function_path $root/functions \$fish_function_path
source $root/conf.d/claude-code.fish
$argv[1]" 2>&1 </dev/null)
    set -g load_plugin_status $status
    string collect -- $out
end

ccf_setup
@test "default: Ctrl+X binds suggest" (string match -rq '__ccf_suggest' -- (load_plugin 'bind \cx'); echo $status) = 0
@test "default: Alt+E binds explain" (string match -rq '__ccf_explain' -- (load_plugin 'bind \ee'); echo $status) = 0
@test "insert mode: Ctrl+X binds suggest" (string match -rq '__ccf_suggest' -- (load_plugin 'bind -M insert \cx'); echo $status) = 0
@test "insert mode: Alt+E binds explain" (string match -rq '__ccf_explain' -- (load_plugin 'bind -M insert \ee'); echo $status) = 0
@test "custom keys: suggest" (string match -rq '__ccf_suggest' -- (load_plugin 'source '$root'/conf.d/claude-code.fish; bind \cg' 'set -g CLAUDE_FISH_SUGGEST_KEY \cg'); echo $status) = 0
ccf_teardown

ccf_setup
set -g pre "set -g CLAUDE_FISH_SUGGEST_KEY \\cg; set -g CLAUDE_FISH_EXPLAIN_KEY \\ek;"
set -g custom_out (load_plugin 'bind \cg; bind \ek; bind -M insert \cg; bind -M insert \ek' $pre)
@test "custom suggest key bound" (string match -rq 'bind (ctrl-g|\\\\cg) __ccf_suggest' -- $custom_out; echo $status) = 0
@test "custom explain key bound" (string match -rq 'bind (alt-k|\\\\ek) __ccf_explain' -- $custom_out; echo $status) = 0
@test "custom keys bound in insert mode" (string match -rq 'bind -M insert (alt-k|\\\\ek) __ccf_explain' -- $custom_out; echo $status) = 0
ccf_teardown

ccf_setup
ccf_no_claude
set -g nc_out (load_plugin '')
set -g nc_status $load_plugin_status
set -g nc_bind (load_plugin 'bind; bind -M insert')
@test "no claude: prints nothing" -z "$nc_out"
@test "no claude: exit 0" $nc_status -eq 0
@test "no claude: no suggest binding" (string match -q '*__ccf_suggest*' -- $nc_bind; echo $status) = 1
@test "no claude: no explain binding" (string match -q '*__ccf_explain*' -- $nc_bind; echo $status) = 1
ccf_teardown
