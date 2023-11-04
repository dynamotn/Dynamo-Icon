#!/bin/bash
set -Eeou pipefail

ROOT_DIR=$(dirname "$(readlink -f "$0")")

_main() {
  mkdir -p $ROOT_DIR/target
  cp -r $ROOT_DIR/src/papirus/Papirus/* $ROOT_DIR/target

  local color="cat-macchiato-lavender"
  local -a sizes=(22x22 24x24 32x32 48x48 64x64)
  local -a prefixes=("folder-$color" "user-$color")
  for size in "${sizes[@]}"; do
    for prefix in "${prefixes[@]}"; do
      for file_path in "$ROOT_DIR/src/catppuccin/src/$size/places/$prefix"{-*,}.svg; do
        [ -f "$file_path" ] || continue  # is a file
        [ -L "$file_path" ] && continue  # is not a symlink

        file_name="${file_path##*/}"
        cp -f "$file_path" "$ROOT_DIR/target/$size/places/${file_name/-$color/}"
      done
    done
  done

  sed -i "s#Papirus#Dynamo#g" $ROOT_DIR/target/index.theme
}
_main
