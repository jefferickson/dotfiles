#! /bin/bash

LOCATION=$(curl --silent http://ip-api.com/json)
CITY=$(echo "$LOCATION" | jq .city | tr -d '"')
LON=$(echo "$LOCATION" | jq .lon)
LAT=$(echo "$LOCATION" | jq .lat)

# I'm more likely in Tampere than Turku or Kuopio
if [[ "$CITY" == "Turku" ]] || [[ "$CITY" == "Kuopio" ]]; then
    CITY="Tampere"
    LON=23.7637
    LAT=61.4980
fi

# And I'm more likely in Helsinki than Vantaa
if [[ "$CITY" == "Vantaa" ]]; then
    CITY="Helsinki"
    LON=24.9521
    LAT=60.1704
fi

TEMP=$(curl -s "https://api.met.no/weatherapi/locationforecast/2.0/compact?lat=$LAT&lon=$LON" |
    jq '.properties.timeseries[0].data.instant.details.air_temperature')

echo "$CITY [${TEMP}°] ($LAT, $LON)"
