#!/usr/bin/env bash

set -xueo pipefail

escape_url() {
  local image_path="$1"
  image_path="${image_path// /%20}"

  echo "${image_path}"
}

readonly ZSH="${HOME}/.antigen/bundles/robbyrussell/oh-my-zsh"
readonly THEMES_DIR="${ZSH}/themes"
readonly THEME_SUFFIX=".zsh-theme"

to_theme_name() {
    local -r theme_path="$1"
    basename "${theme_path}" "${THEME_SUFFIX}"
}

list_themes() {
    for theme_path in "${THEMES_DIR}/"*"${THEME_SUFFIX}"; do
        to_theme_name "${theme_path}"
    done
}

echo "## By color preset" > README.md
for color_preset_dir in images/*; do
    color_preset="$(basename "${color_preset_dir}")"
    page_path="pages/presets/${color_preset}.md"
    for screenshot in "${color_preset_dir}"/*.png; do
        theme="$(basename "${screenshot}" .png)"
        echo "# \`ZSH_THEME=\"${theme}\"\`"
        echo "![Had to be an image :(](/$(escape_url "${screenshot}"))"
    done > "${page_path}"
    echo "* [${color_preset}]($(escape_url "/${page_path}"))" >> README.md
done

echo "## By theme" >> README.md
list_themes | while read -r theme_name; do
    page_path="pages/themes/${theme_name}.md"

    for color_preset_dir in "images/"*; do
        color_preset="$(basename "${color_preset_dir}")"
        screenshot="${color_preset_dir}/${theme_name}.png"

        echo "# ${color_preset}"
        echo "![Had to be an image :(](/$(escape_url "${screenshot}"))"
    done > "${page_path}"
    echo "* [${theme_name}]($(escape_url "/${page_path}"))" >> README.md
done
