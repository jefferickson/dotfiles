#!/bin/bash

TMUX_SESSION="base"
PROXY_SCRIPT="~/git-repos/daily-harvest/local_scripts/start_sql_proxy.sh"

if [ $# == 0 ]; then
    INSTANCE="dev"
else
    INSTANCE="$@"
fi

TAB_NAME="SQL Proxy: [$INSTANCE] "

tmux neww -t $TMUX_SESSION -n "$TAB_NAME" -d "$PROXY_SCRIPT $INSTANCE"
