#! /bin/bash

LOCATION=$(curl --silent http://ip-api.com/json)
CITY=$(echo "$LOCATION" | jq .city | tr -d '"')
LON=$(echo "$LOCATION" | jq .lon)
LAT=$(echo "$LOCATION" | jq .lat)

echo "$CITY ($LAT, $LON)"
