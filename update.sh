#!/usr/bin/env bash
# @file update.sh
# @brief Rebuild the Dynamo icon theme
# @description Regenerate `target/` from the Papirus icon theme, swap its
# folder and user icons for the Catppuccin ones of one accent color, and
# rename the theme to Dynamo.
#
# dybatpho is not vendored here; the shared checkout is used, and
# `DYBATPHO_DIR` points somewhere else when needed.

# COLOR and DRY_RUN are assigned by the option parser.
# shellcheck disable=SC2154
DYBATPHO_DIR="${DYBATPHO_DIR:-${HOME}/Working/personal/tools/dybatpho}"
if [[ ! -f "${DYBATPHO_DIR}/init.sh" ]]; then
  printf 'dybatpho not found in %s; set DYBATPHO_DIR to its checkout.\n' "${DYBATPHO_DIR}" >&2
  exit 1
fi
# shellcheck source=/dev/null
. "${DYBATPHO_DIR}/init.sh" --modules cli safety
dybatpho::register_common_handlers

ROOT_DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
TARGET_DIR="${ROOT_DIR}/target"
# Every guarded removal or copy below must stay inside this repository.
export DYBATPHO_SAFE_ROOTS="${ROOT_DIR}"

#######################################
# @description Spec of update.sh
# @noargs
#######################################
function _spec_main {
  dybatpho::opts::setup "Rebuild the Dynamo icon theme" MAIN_ARGS action:"_main"
  dybatpho::opts::param "Log level" LOG_LEVEL --log-level -l init:="info" \
    validate:"dybatpho::validate_log_level \$OPTARG"
  dybatpho::opts::param "Catppuccin folder color" COLOR --color -c init:="cat-macchiato-teal"
  dybatpho::opts::flag "Print the commands instead of running them" DRY_RUN --dry-run -n \
    on:true off:false init:="false"
  dybatpho::opts::disp "Show help" --help -h action:"dybatpho::generate_help _spec_main"
}

#######################################
# @description Recreate `target/` as a fresh copy of Papirus
# @env TARGET_DIR Output directory of the theme
# @noargs
#######################################
function _copy_papirus {
  local papirus_dir="${ROOT_DIR}/src/papirus/Papirus"
  dybatpho::is dir "${papirus_dir}" \
    || dybatpho::die "Papirus not found in ${papirus_dir}; run: git submodule update --init"

  dybatpho::info "Copying Papirus into ${TARGET_DIR}"
  # target/ is generated output only, so it is replaced without asking.
  dybatpho::safe_rm --force --recursive "${TARGET_DIR}"
  dybatpho::dry_run -- mkdir -p "${TARGET_DIR}"
  dybatpho::dry_run -- cp -r "${papirus_dir}/." "${TARGET_DIR}"
}

#######################################
# @description Overlay the Catppuccin folder and user icons of one color,
# dropping the color from their names so they replace the Papirus ones
# @env COLOR Catppuccin color, such as `cat-macchiato-teal`
# @noargs
#######################################
function _copy_catppuccin {
  local catppuccin_dir="${ROOT_DIR}/src/catppuccin/src"
  dybatpho::is dir "${catppuccin_dir}" \
    || dybatpho::die "Catppuccin not found in ${catppuccin_dir}; run: git submodule update --init"

  dybatpho::info "Overlaying Catppuccin icons in ${COLOR}"
  local -a sizes=(22x22 24x24 32x32 48x48 64x64)
  local -a prefixes=("folder-${COLOR}" "user-${COLOR}")
  local size prefix file_path file_name
  local -i copied=0
  for size in "${sizes[@]}"; do
    for prefix in "${prefixes[@]}"; do
      for file_path in "${catppuccin_dir}/${size}/places/${prefix}"{-*,}.svg; do
        dybatpho::is file "${file_path}" || continue
        dybatpho::is link "${file_path}" && continue

        file_name="${file_path##*/}"
        dybatpho::debug "${size}/${file_name} -> ${file_name/-${COLOR}/}"
        dybatpho::dry_run -- cp -f "${file_path}" \
          "${TARGET_DIR}/${size}/places/${file_name/-${COLOR}/}"
        copied+=1
      done
    done
  done
  dybatpho::info "Overlaid ${copied} icons"
}

#######################################
# @description Rename the theme from Papirus to Dynamo
# @env TARGET_DIR Output directory of the theme
# @noargs
#######################################
function _rename_theme {
  dybatpho::info "Renaming the theme to Dynamo"
  if dybatpho::is true "${DRY_RUN}"; then
    dybatpho::dry_run -- sed -i "s#Papirus#Dynamo#g" "${TARGET_DIR}/index.theme"
    return 0
  fi
  dybatpho::file_replace "${TARGET_DIR}/index.theme" "Papirus" "Dynamo"
}

#######################################
# @description Build the theme into `target/`
# @noargs
#######################################
function _main {
  # Checked before target/ is wiped, so a typo in the color keeps the old theme.
  dybatpho::is exist "${ROOT_DIR}/src/catppuccin/src/48x48/places/folder-${COLOR}.svg" \
    || dybatpho::die "Unknown Catppuccin color: ${COLOR}"
  _copy_papirus
  _copy_catppuccin
  _rename_theme
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  dybatpho::generate_from_spec _spec_main "$@"
fi
