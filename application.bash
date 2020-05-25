#!/usr/bin/env bash

set -xueo pipefail

# TODO: Implement
_escape_command_for_apple_script() {
    local -r sh_command="$1"
    echo "${sh_command}"
}

readonly DELAY_BETWEEN_COMMANDS="${DELAY_BETWEEN_COMMANDS:-"0.5"}" # In seconds

# Meant to be called in a prefix form , like `_with_delay echo 'Yo!''`
_with_delay() {
    "$@"; sleep "${DELAY_BETWEEN_COMMANDS}"
}

# Returns window ID
execute_command_in_new_terminal_window() {
    local -r sh_command="${1:-""}"

    local -r escaped_sh_command="$(_escape_command_for_apple_script "${sh_command}")"
    local -r as_command="tell application \"Terminal\" to do script \"${escaped_sh_command}\""

    # The output looks like 'tab 1 of window id 686'
    local -r raw_output="$(osascript -e "${as_command}")"

    # 'r' MUST be before 'a' here
    read -ra parsed_output <<< "${raw_output}"

    _with_delay echo "${parsed_output[5]}"
}

launch_new_terminal_window() {
    execute_command_in_new_terminal_window
}

execute_command_in_existing_terminal_window() {
    local -r window_id="$1"
    local -r sh_command="$2"

    local -r escaped_sh_command="$(_escape_command_for_apple_script "${sh_command}")"
    local -r as_command="tell application \"Terminal\" to do script \"${escaped_sh_command}\" in window id ${window_id}"

    _with_delay osascript -e "${as_command}" > /dev/null
}

close_terminal_window() {
    local -r window_id="$1"

    execute_command_in_existing_terminal_window "${window_id}" "logout"

    # Handles the case that a window closes on logout gracefully
    osascript << EOF
tell application "Terminal"
    set anEmptyList to {}
    set myWindows to windows whose id is equal to ${window_id}
    if myWindows is not equal to anEmptyList then
        close first item of myWindows
    end if
end tell
EOF
}

capture_window() {
    local -r window_id="$1"
    local -r output_path="${2:-""}"

    local arguments=("-w" "-l" "${window_id}")
    if [[ -z "${output_path}" ]]; then
        arguments+=("-P") # Show in Preview instead
    else
        arguments+=("${output_path}")
    fi

    screencapture "${arguments[@]}"
}

# 1. Creates a new Terminal window
# 2. Executes every command with DELAY_BETWEEN_COMMANDS between them
# 3. Makes a screenshot of it saving into specified location
# 4. Closes the window it created
capture_terminal_window_after_commands() {
    local -r output_path="$1"; shift
    local -r sh_commands=("$@")

    local -r window_id="$(launch_new_terminal_window)"

    for sh_command in "${sh_commands[@]}"; do
        execute_command_in_existing_terminal_window "${window_id}" "${sh_command}"
    done
    capture_window "${window_id}" "${output_path}"
    close_terminal_window "${window_id}"
}

readonly THEMES_DIR="${THEMES_DIR:-"${ZSH}/themes"}"
readonly THEME_SUFFIX=".zsh-theme"
readonly OUTPUT_DIR="${OUTPUT_DIR:-"$(mktemp -d)"}"

_get_theme_name() {
    local -r theme_path="$1"
    basename "${theme_path}" "${THEME_SUFFIX}"
}

echo "The images will be saved into ${OUTPUT_DIR}"
for theme_path in "${THEMES_DIR}"/*"${THEME_SUFFIX}"; do
    theme_name="$(_get_theme_name "${theme_path}")"
    output_path="${OUTPUT_DIR}/${theme_name}.png"
    commands=(
        "source ${theme_path} && clear"
        "cd \$ZSH"
        "ll"
    )

    capture_terminal_window_after_commands "${output_path}" "${commands[@]}"
done
