#! /bin/bash

docker run --rm -it \
  --add-host=host.docker.internal:host-gateway \
  -v "$PWD:/stage" \
  -v "$HOME/.pi/agent:/root/.pi/agent" \
  -v "$GITHOME/dotfiles/pi/extensions:/root/.pi/agent/extensions" \
  -v "$GITHOME/dotfiles/pi/cursor/hooks.json:/root/.cursor/hooks.json:ro" \
  pi-sandbox
