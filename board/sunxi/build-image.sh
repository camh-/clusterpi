#!/bin/bash
# vim: set ts=8 sw=2 sts=2 et sta fileencoding=utf-8:
#
#-----------------------------------------------------------------------------
# Generate images from build artefacts:
#   sd card image. Requires uboot, uboot environment, DTB, kernel and rootfs
#     as ext image.
#   A FEL boot script image. Requires felboot.cmd or felboot-nfs.cmd
#
# Args:
# $1: Path to images directory
# $2: dtb file
#
# CWD is the board image directory ($LBR_IMAGE_DIR)
#
# lbr defines:
# LBR_BOARD_DIR: The directory contain the board files in the source tree
# LBR_IMAGE_DIR: The directory containing all the image outputs from each phase
# LBR_OUTPUT_ROOT: The root output directory containing the output dirs
#   for board.
#
# TODO(camh): rewrite this as a makefile

# shellcheck disable=SC2034
# Unused vars are used via indirection
init() {
  sdcard_req=("${LBR_IMAGE_DIR}"/{zImage,board.dtb})
  sdcard_sdroot_req=("${LBR_IMAGE_DIR}"/{rootfs.ext4,sdroot/uboot-env.bin})
  sdcard_nfsroot_req=("${LBR_IMAGE_DIR}"/nfsroot/uboot-env.bin)
  : ${dryrun:=}
}

main() {
  checkenv LBR_IMAGE_DIR LBR_BOARD_DIR LBR_OUTPUT_ROOT
  init
  link_images "$2" "$3"
  make_images sdroot nfsroot uboot tftpboot
  make_uboot_env_image rdroot
  copy_felboot
}

link_images() {
  # $1 is the name of the layer with the root fs to put in the image,
  # $2 is the name of the device tree.
  # We search for these through the image dirs of us and our parents
  # and if we find them, link them into our image dir with a generic
  # name, so the genimage.cfg file can use generic names.
  local rootfs dtb kernel

  rootfs=$(locate_image "rootfs-$1.ext4")
  if [[ -n "${rootfs}" ]]; then
    run ln -nsf "$(realpath --relative-to="${LBR_IMAGE_DIR}" "${rootfs}")" \
      "${LBR_IMAGE_DIR}/rootfs.ext4"
  fi

  dtb=$(locate_image "$2.dtb")
  if [[ -n "${dtb}" ]]; then
    run ln -nsf "$(realpath --relative-to="${LBR_IMAGE_DIR}" "${dtb}")" \
      "${LBR_IMAGE_DIR}/board.dtb"
  fi

  kernel=$(locate_image 'zImage')
  if [[ -n "${kernel}" ]]; then
    run ln -nsf "$(realpath --relative-to="${LBR_IMAGE_DIR}" "${kernel}")" \
      "${LBR_IMAGE_DIR}/zImage"
  fi
}

make_images() {
  for image; do
    message "Building ${image} image"
    make_uboot_env_image "${image}"
    make_sdcard_image "${image}"
  done
}

make_uboot_env_image() {
  local env missing
  env="$(locate "${1}/uboot-env.txt")"
  if ! missing=$(req "${env}"); then
    echo "Not making ${1} uboot env image. Missing: $missing"
    return
  fi

  local bootdir="${LBR_IMAGE_DIR}/$1"
  local txtenv="${bootdir}/uboot-env.txt"
  local binenv="${bootdir}/uboot-env.bin"

  mkdir -p "${bootdir}"
  run cat - $(collate uboot-env.txt) "${env}" <<<'#=uEnv' >"${txtenv}"
  run mkenvimage -s 0x20000 -o "${binenv}" "${txtenv}"
}

make_sdcard_image() {
  local v="sdcard_${1}_req[@]"
  if ! missing=$(req "${sdcard_req[@]}" "${!v}"); then
    echo "Not making ${1} SD card image. Missing: $missing"
    return
  fi

  local GENIMAGE_CFG GENIMAGE_TMP ROOTPATH_TMP
  GENIMAGE_CFG=$(locate "${1}/genimage.cfg")
  GENIMAGE_TMP=$(mktemp -d "${LBR_IMAGE_DIR}/genimage.XXXXXXXXX")
  ROOTPATH_TMP=$(mktemp -d -t "genimage.root.XXXXXXXXX")

  cleanup() { rm -rf "${GENIMAGE_TMP}" "${ROOTPATH_TMP}"; }

  trap cleanup EXIT

  mkdir -p "${LBR_IMAGE_DIR}/${1}"
  run genimage \
    --rootpath "${ROOTPATH_TMP}" \
    --tmppath "${GENIMAGE_TMP}" \
    --inputpath "${LBR_IMAGE_DIR}" \
    --outputpath "${LBR_IMAGE_DIR}/${1}" \
    --config "${GENIMAGE_CFG}"

  cleanup
  trap - EXIT
}

copy_felboot() {
  checkenv HOST_DIR
  run cp "$(locate "felboot")" "${LBR_IMAGE_DIR}"
  if [[ -x "${HOST_DIR}/bin/sunxi-fel" ]]; then
    run sed -i '/: ${HOST_DIR:=}/s|.*|: ${HOST_DIR:='"${HOST_DIR}"'}|' \
      "${LBR_IMAGE_DIR}/felboot"
  fi
}

#-----------------------------------------------------------------------------
run() {
  echo "$@"
  [[ -n "${dryrun}" ]] || "$@"
}

req() {
  for arg; do
    [[ -e "$arg" ]] || { echo "$arg"; return 1; }
  done
  return 0
}

collate() {
  _collate "${LBR_BOARD_DIR}" "$1"
}

_collate() {
  if [[ -L "$1/parent" ]] ; then
    _collate "$1/parent" "$2"
  fi
  if [[ -e "$1/$2" ]] ; then
    readlink -f "$1/$2"
  fi
}

locate() {
  _locate "${LBR_BOARD_DIR}" "$1"
}

_locate() {
  if [[ -e "$1/$2" ]] ; then
    readlink -f "$1/$2"
  elif [[ -L "$1/parent" ]] ; then
    _locate "$1/parent" "$2"
  else
    return 1
  fi
}

locate_image() {
  _locate_image "${LBR_BOARD_DIR}" "$1"
}

_locate_image() {
  local image_dir="${LBR_OUTPUT_ROOT}/${1##*/}/images"
  if [[ -e "${image_dir}/$2" ]]; then
    printf '%s/%s\n' "${image_dir}" "$2"
  elif [[ -L "$1/parent" ]]; then
    _locate_image "$(realpath "$1/parent")" "$2"
  else
    return 1
  fi
}

message() {
  tput smso   # bold
  printf '>>> build-image %s\n' "$*"
  tput rmso   # normal
}

checkenv() {
  for ev; do
    if [[ -z "${!ev:-}" ]]; then
      printf 'Envvar %s not set. Are you running from lbr?\n' "${ev}"
      exit 1
    fi
  done
}

#-----------------------------------------------------------------------------
[[ "$(caller)" != "0 "* ]] || main "$@"
