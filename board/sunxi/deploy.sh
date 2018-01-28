#!/bin/bash
# vim: set ts=8 sw=2 sts=2 et sta fileencoding=utf-8:
#
#-----------------------------------------------------------------------------
TFTP_ROOT='/srv/tftp/clusterpi'
NFS_ROOT='/srv/nfs/root/clusterpi'

: ${dryrun=}

#-----------------------------------------------------------------------------
usage() {
  printf 'Usage: %s {<options>...} [cmd] {<options>...}\n' "${0##*/}"
  printf 'The default cmd is "deploy_images" if not specified\n'
  printf 'Available commands:\n'
  printf '  deploy_images: Deploy the kernel and nfsroot\n'
  printf '  nfs_rootfs: Extract the rootfs to nfs (usually done as root)\n'
  printf '  deploy_board <board> <dtb>:\n'
  printf '    Copy DTB to tftp and symlink kernel and DTB for board\n'
  printf 'Available options:\n'
  printf '  -n  Dry run. Print but dont execute commands\n'
}

#-----------------------------------------------------------------------------
main() {
  set -e -u
  checkenv LBR_LAYER LBR_OUTPUT_ROOT LBR_IMAGE_DIR
  parse_args "$@"
  case "${cmd}" in
    deploy_images)
      deploy_images "${args[@]}"
      ;;
    nfs_rootfs)
      root_nfs_rootfs "${args[@]}"
      ;;
    deploy_board)
      deploy_board "${args[@]}"
      ;;
    *)
      printf 'Unknown command: %s\n' "${cmd}" >&2
      ;;
  esac
}

#-----------------------------------------------------------------------------
checkenv() {
  for ev; do
    if [[ -z "${!ev:-}" ]]; then
      printf 'Envvar %s not set. Are you running from lbr?\n' "${ev}"
      exit 1
    fi
  done
}

#-----------------------------------------------------------------------------
parse_args() {
  OPTSTRING=':n'
  while getopts "${OPTSTRING}" opt; do
    case "${opt}" in
      n)
        dryrun=true
        ;;
      \?)
        printf 'Invalid option: -%s\n\n' "${OPTARG}" >&2
        usage >&2
        exit 1
        ;;
      :)
        printf 'Option -%s requires an argument\n\n' "${OPTARG}" >&2
        usage >&2
        exit 1
        ;;
    esac
  done
  shift $((OPTIND-1))

  # Process remaining in "$@"
  br_image_dir="$1"; shift
  cmd="${1:-deploy_images}"; shift || true
  args=("$@")
}

#-----------------------------------------------------------------------------
# deploy the kernel to tftp and the rootfs to nfs. nfs needs root privs so
# call this script with sudo to copy to nfs.
deploy_images() {
  run cp "${LBR_IMAGE_DIR}/zImage" "${TFTP_ROOT}/vmlinuz-sunxi"
  sudo -E "$0" ${dryrun:+-n} "${br_image_dir}" nfs_rootfs
}

#-----------------------------------------------------------------------------
# Untar the root filesystem image in the nfs root directory. To save on space,
# untar it to a tmp directory and if there is a directory for "latest", use
# rsync with --link-dest to copy into the final directory. This will
# deduplicate files that have the same name and content across all the deployed
# root directories.
root_nfs_rootfs() {
  tarfile="${LBR_IMAGE_DIR}/rootfs-${LBR_LAYER}.tar.bz2"
  if [[ ! -f "${tarfile}" ]]; then
    printf 'No tar file to extract: %s\n' "${tarfile}" >&2
    return
  fi

  imagedate=$(filedate "${tarfile}")
  tgtdir="${NFS_ROOT}/sunxi-${imagedate}"
  if [[ -d "${tgtdir}" ]]; then
    printf 'nfs root already present: %s\n' "${tgtdir}" >&2
    return
  fi

  tmpdir=$(mktemp -d ${dryrun:+-u} "${NFS_ROOT}/sunxi.XXXXXXXXX")
  run tar x -C "${tmpdir}" -f "${tarfile}"
  if [[ -d "${NFS_ROOT}/latest" ]]; then
    run rsync --archive --link-dest="${NFS_ROOT}/latest" "${tmpdir}/" "${tgtdir}"
    run rm -rf "${tmpdir}"
  else
    run mv "${tmpdir}" "${tgtdir}"
  fi
  [[ -L "${NFS_ROOT}/latest" ]] && ln -nsf "${tgtdir##*/}" "${NFS_ROOT}/latest"
  run chmod 0755 "${tgtdir}"
}

#-----------------------------------------------------------------------------
# Deploy a board by copying its DTB file from the sunxi images directory to
# the tftp root, and make symlinks in the tftp root for the kernel and dtb
# based on the board name.
deploy_board() {
  board="$1"
  dtb="$2"
  run cp "${LBR_OUTPUT_ROOT}/sunxi/images/${dtb}.dtb" "${TFTP_ROOT}"
  run ln -nsf "vmlinuz-sunxi" "${TFTP_ROOT}/vmlinuz-${board}"
  run ln -nsf "${dtb}.dtb" "${TFTP_ROOT}/vmlinuz-${board}.dtb"
}

#-----------------------------------------------------------------------------
filedate() {
  date -d "@$(stat -c %Y "$1")" '+%Y%m%d-%H%M%S'
}

#-----------------------------------------------------------------------------
run() {
  echo "$@"
  [[ -n "${dryrun}" ]] || "$@"
}

#-----------------------------------------------------------------------------
[[ "$(caller)" != 0\ * ]] || main "$@"

