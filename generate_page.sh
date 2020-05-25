#!/usr/bin/env bash

set -xueo pipefail

escape_url() {
  local image_path="$1"
  image_path="${image_path// /%20}"

  echo "${image_path}"
}

for image in images/dark/*.png; do
    echo "## \`ZSH_THEME=\"$(basename "${image}" ".png")\"\`"
    echo "![Had to be an image :(]($(escape_url "${image}"))"
done > dark.md

for image in images/light/*.png; do
    echo "## \`ZSH_THEME=\"$(basename "${image}" ".png")\"\`"
    echo "![Had to be an image :(]($(escape_url "${image}"))"
done > light.md

for image in images/iterm2/*.png; do
    scheme_name="$(basename "${image}" ".png")"
    escaped_scheme_name="$(escape_url "${scheme_name}")"
    echo "# [${scheme_name}](https://github.com/mbadolato/iTerm2-Color-Schemes/raw/master/schemes/${escaped_scheme_name}.itermcolors)"
    echo "![Had to be an image :(]($(escape_url "${image}"))"
done > iterm2.md
