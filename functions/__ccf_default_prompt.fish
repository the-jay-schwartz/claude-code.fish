function __ccf_default_prompt --description 'Print the built-in system prompt for a feature (ask, explain, suggest)'
    switch $argv[1]
        case ask
            echo "You answer shell and command-line questions tersely. If the answer is a command, show the command first in a fenced code block, then at most one short line of context. No preamble."
        case explain
            echo "You explain a shell command. Give one overview line, then one short bullet per flag or argument. Nothing else."
        case suggest
            echo "You turn a request into a shell command. Output exactly one shell command and nothing else: no fences, no explanation."
        case '*'
            return 1
    end
end
