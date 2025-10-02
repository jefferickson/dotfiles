#! /bin/bash

LOCATION=$(curl --silent http://ip-api.com/json)
COUNTRY=$(echo "$LOCATION" | jq .country | tr -d '"')
LON=$(echo "$LOCATION" | jq .lon)
LAT=$(echo "$LOCATION" | jq .lat)

# If Finland, just go with Borgå
if [[ "$COUNTRY" == "Finland" ]]; then
    CITY="Borgå"
    LON=25.6645
    LAT=60.3929
fi

TEMP=$(curl -s "https://api.met.no/weatherapi/locationforecast/2.0/compact?lat=$LAT&lon=$LON" |
    jq '.properties.timeseries[0].data.instant.details.air_temperature')

echo "$CITY [${TEMP}°] ($LAT, $LON)"
