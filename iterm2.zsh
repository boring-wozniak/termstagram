#!/usr/bin/env zsh

set -xueo pipefail

readonly DEFAULT_NUMBER_OF_COLUMNS=100
readonly DEFAULT_NUMBER_OF_ROWS=20

readonly NUMBER_OF_COLUMNS="${NUMBER_OF_COLUMNS:-"${DEFAULT_NUMBER_OF_COLUMNS}"}"
readonly NUMBER_OF_ROWS="${NUMBER_OF_ROWS:-"${DEFAULT_NUMBER_OF_ROWS}"}"

do_the_thing() {
  readonly color_preset="$1"
  shift
  readonly commands=("$@")

  osascript - "${color_preset}" "${commands[@]}" <<EOF
on run arguments
  set numberOfColumns to ${NUMBER_OF_COLUMNS}
  set numberOfRows to ${NUMBER_OF_ROWS}

  set colorPreset to the first item in arguments
  set commands to the rest of arguments
  
  tell application "iTerm"
    set theWindow to create window with default profile
    set theTab to the current tab of theWindow
    set theSession to the current session of theTab

    set color preset of theSession to colorPreset
    set columns of theSession to numberOfColumns
    set rows of theSession to numberOfRows
    set name of theSession to colorPreset

    repeat with command in commands
      write theSession text command
      delay 0.5
    end repeat

    return id of theWindow
  end tell
end run
EOF
}

capture_window() {
  readonly window_id="$1"
  readonly output_path="${2:-""}"

  local arguments=("-w" "-l" "${window_id}")
  if [[ -z "${output_path}" ]]; then
    arguments+=("-P") # Show in Preview instead
  else
    arguments+=("${output_path}")
  fi

  screencapture "${arguments[@]}"
}

close_window() {
  readonly window_id="$1"
  osascript -e "tell application \"iTerm\" to close the window id ${window_id}"
}

readonly DEFAULT_COLOR_PRESETS=(
  "Dark Background"
  "Light Background"
  "Pastel (Dark Background)"
  "Smoooooth"
  "Solarized Dark"
  "Solarized Light"
  "Tango Dark"
  "Tango Light"
)

readonly ITERM2_CONFIG_PATH="${HOME}/Library/Preferences/com.googlecode.iterm2.plist"

list_external_color_presets() {
  python3 << EOF
import plistlib
with open("${ITERM2_CONFIG_PATH}", mode="rb") as file:
    content = plistlib.load(file)
for color_preset_name in sorted(content["Custom Color Presets"]):
    print(color_preset_name)
EOF
}

list_all_presets() {
  list_external_color_presets
  for preset in "${DEFAULT_COLOR_PRESETS[@]}"; do
    print "${preset}"
  done
}

# TODO: Spin up all the windows first :)
readonly IMAGES_DIR="${HOME}/Sources/no-good-name-yet/images/iterm2"

list_all_presets | while read -r color_preset; do
  window_id="$(do_the_thing "${color_preset}" "cd Sources/no-good-name-yet" "ll")"
  capture_window "${window_id}" "${IMAGES_DIR}/${color_preset}.png"
  close_window "${window_id}"
done
