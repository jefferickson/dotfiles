#! /bin/bash

docker run --rm -it \
  -v "$PWD:/stage" \
  -v "$HOME/.pi/agent:/root/.pi/agent" \
  pi-sandbox
