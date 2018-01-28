#!/bin/sh
${LBR_BOARD_DIR}/parent/build-image.sh "$1" final sun8i-h3-orangepi-plus
${LBR_BOARD_DIR}/parent/deploy.sh "$1" deploy_board opiplus sun8i-h3-orangepi-plus
