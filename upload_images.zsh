#!/usr/bin/env bash

set -xueo pipefail

export TOKEN=""
export URL=""

upload_image() {
  set -x
  local -r image_path="$1"

  prefix="$(basename "$(dirname "${image_path}")")"
  file_name="$(basename "${image_path}")"
  escaped_file_name="${file_name// /%20}"
  escaped_file_name="${escaped_file_name//\+/_plus_}"

  curl \
    --header "Authorization: Bearer ${TOKEN}" \
    --header "Content-Type: image/png" \
    --data-binary "@${image_path}" \
    "${URL}?name=${prefix}.${escaped_file_name}"
  set +x
}
export -f upload_image

parallel --jobs 20 --eta upload_image ::: images/*/*.png
