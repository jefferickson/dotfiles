#! /bin/bash

docker run --rm -it \
  -v "$PWD:/stage" \
  -v "$HOME/.pi/agent:/root/.pi/agent" \
  -v "$GITHOME/dotfiles/pi/extensions:/root/.pi/agent/extensions" \
  pi-sandbox
