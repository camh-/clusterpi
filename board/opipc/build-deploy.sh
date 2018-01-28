#!/bin/sh
${LBR_BOARD_DIR}/parent/build-image.sh "$1" final sun8i-h3-orangepi-pc
${LBR_BOARD_DIR}/parent/deploy.sh "$1" deploy_board opipc sun8i-h3-orangepi-pc
