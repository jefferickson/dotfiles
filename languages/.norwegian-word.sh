#! /bin/bash

## USAGE: ./.norwegian-word.sh WORD
## Where WORD is the Norwegian word you want to search.

echo "Søk: $1"

echo -n $1 | pbcopy

/Applications/Firefox.app/Contents/MacOS/firefox \
    --new-tab "https://forvo.com/word/$1/#no" \
    --new-tab "http://en.bab.la/dictionary/norwegian-english/$1" \
    --new-tab "https://ordbokene.no/bm,nn/search?q=$1&scope=ei" \
    --new-tab "https://no.wiktionary.org/wiki/$1#Norsk" \
    --new-tab "https://www.google.no/search?sca_esv=568147601&q=$1&tbm=isch" \
    --new-tab "https://sv.bab.la/lexikon/norsk-svensk/$1" \
    2>/dev/null

trash ~/Downloads/pronunciation_no_*.mp3
curl -s https://apifree.forvo.com/action/word-pronunciations/format/json/word/$1/id_lang_speak/120/key/$FORVO_API_KEY |
    jq '[.items[] | select(.code == "no")] | max_by(.hits) | .pathmp3' |
    xargs -L 1 curl -s --output ~/Downloads/pronunciation_no_$1.mp3

trans -b no:en+sv $1
