#!/usr/bin/env zsh

set -ueo pipefail

readonly DEFAULT_NUMBER_OF_COLUMNS=100
readonly DEFAULT_NUMBER_OF_ROWS=20

readonly NUMBER_OF_COLUMNS="${NUMBER_OF_COLUMNS:-"${DEFAULT_NUMBER_OF_COLUMNS}"}"
readonly NUMBER_OF_ROWS="${NUMBER_OF_ROWS:-"${DEFAULT_NUMBER_OF_ROWS}"}"

readonly ZSH="${HOME}/.antigen/bundles/robbyrussell/oh-my-zsh"
readonly THEMES_DIR="${ZSH}/themes"
readonly THEME_SUFFIX=".zsh-theme"

to_theme_path() {
  readonly theme_name="$1"
  echo "${THEMES_DIR}/${theme_name}${THEME_SUFFIX}"
}

to_theme_name() {
  readonly theme_path="$1"
  basename "${theme_path}" "${THEME_SUFFIX}"
}

do_the_thing() {
  readonly color_preset="$1"; shift
  readonly theme_name="$1"; shift
  readonly set_theme_command="source $(to_theme_path "${theme_name}") && clear"
  readonly commands=("${set_theme_command}" "$@")
  readonly window_name="boring-wozniak/termstagram        theme:'${theme_name}'  colors: '${color_preset}'"

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

    repeat with command in commands
      write theSession text command
      delay 0.5
    end repeat

    set name of theSession to "${window_name}"

    return id of theWindow
  end tell
end run
EOF
}

capture_window() {
  readonly window_id="$1"
  readonly output_path="${2:-""}"

  local arguments=("-o" "-r" "-w" "-l" "${window_id}")
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


list_all_themes() {
  for theme_path in "${THEMES_DIR}/"*"${THEME_SUFFIX}"; do
    basename "${theme_path}" "${THEME_SUFFIX}"
  done
}

epoch_now() {
  date +%s
}

# TODO: Spin up all the windows first :)
readonly IMAGES_DIR="${HOME}/Temporary/termstagram/images"

readonly number_of_color_presets="$(list_external_color_presets | wc -l)"
print "Found ${number_of_color_presets} color presets"

readonly number_of_themes="$(list_all_themes | wc -l)"
print "Found ${number_of_themes} themes"

readonly number_of_screenshots="$((number_of_color_presets * number_of_themes))"
print "Going to create ${number_of_screenshots} 😎"

list_color_presets() {
  echo "Dark Background"
  # echo "Light Background"
}

current_screenshot=0
mkdir -p "${IMAGES_DIR}"
list_color_presets | while read -r color_preset; do
  mkdir -p "${IMAGES_DIR}/${color_preset}"
  list_all_themes | while read -r theme_name; do
    echo -n "Taking the screenshot #$((++current_screenshot))/${number_of_screenshots}..."
    started_at="$(epoch_now)"
    window_id="$(do_the_thing "${color_preset}" "${theme_name}" "cd Sources/termstagram" "ll")"
    capture_window "${window_id}" "${IMAGES_DIR}/${color_preset}/${theme_name}.png"
    close_window "${window_id}"
    finished_at="$(epoch_now)"
    echo "took $((finished_at - started_at))s"
  done
done
