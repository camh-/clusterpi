#!/bin/sh
${LBR_BOARD_DIR}/parent/build-image.sh "$1" final sun7i-a20-pcduino3-nano
${LBR_BOARD_DIR}/parent/deploy.sh "$1" deploy_board pcd sun7i-a20-pcduino3-nano
