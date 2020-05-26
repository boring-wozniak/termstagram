#!/usr/bin/env bash

set -xueo pipefail

escape_url() {
  local image_path="$1"
  image_path="${image_path// /%20}"

  echo "${image_path}"
}

for color_preset_dir in images/*; do
    color_preset="$(basename "${color_preset_dir}")"
    for screenshot in "${color_preset_dir}"/*.png; do
        theme="$(basename "${screenshot}" .png)"
        echo "## \`ZSH_THEME=\"${theme}\"\`"
        echo "![Had to be an image :(]($(escape_url "${screenshot}"))"
    done > "${color_preset}.md"
    echo "# [${color_preset}]($(escape_url "${color_preset}.md"))" >> README.md
done
