#! /bin/bash

LOCATION=$(curl --silent http://ip-api.com/json)
CITY=$(echo "$LOCATION" | jq .city | tr -d '"')
LON=$(echo "$LOCATION" | jq .lon)
LAT=$(echo "$LOCATION" | jq .lat)

TEMP=$(curl -s "https://api.met.no/weatherapi/locationforecast/2.0/compact?lat=$LAT&lon=$LON" |
    jq '.properties.timeseries[0].data.instant.details.air_temperature')

echo "$CITY [${TEMP}°] ($LAT, $LON)"
