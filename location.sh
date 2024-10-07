#! /bin/bash

LOCATION=$(curl --silent http://ip-api.com/json)
CITY=$(echo "$LOCATION" | jq .city | tr -d '"')
LON=$(echo "$LOCATION" | jq .lon)
LAT=$(echo "$LOCATION" | jq .lat)

# I'm rarely in Kuopio
if [[ "$CITY" == "Kuopio" ]]; then
    CITY="Tampere"
    LON=23.7637
    LAT=61.4980
fi

TEMP=$(curl -s "https://api.met.no/weatherapi/locationforecast/2.0/compact?lat=$LAT&lon=$LON" |
    jq '.properties.timeseries[0].data.instant.details.air_temperature')

echo "$CITY [${TEMP}°] ($LAT, $LON)"
