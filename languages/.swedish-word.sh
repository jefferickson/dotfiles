#! /bin/bash

## USAGE: ./.swedish-word.sh WORD
## Where WORD is the Swedish word you want to search.

echo "Sök: $1"

echo -n $1 | pbcopy

# replace Swedish vowels
cleaned_word=`echo $1 | sed -e 's/[åÅ]/\%C3\%A5/g' -e 's/[öÖ]/\%C3\%B6/g' -e 's/[äÄ]/\%C3\%A4/g'`

/Applications/Firefox.app/Contents/MacOS/firefox \
    --new-tab "https://sv.wiktionary.org/wiki/$cleaned_word#Svenska" \
    --new-tab "https://forvo.com/word/$cleaned_word/#sv" \
    --new-tab "https://www.google.se/search?site=&tbm=isch&source=hp&q=$cleaned_word&oq=$cleaned_word&gs_l=img.3..0l10.2298.3088.0.3176.5.5.0.0.0.0.60.218.4.4.0....0...1ac.1.64.img..1.4.216.JMP5u9OU3X8" \
    --new-tab "http://en.bab.la/dictionary/swedish-english/$cleaned_word" \
    --new-tab "https://svenska.se/tre/?sok=$cleaned_word&pz=1" \
    2>/dev/null

trash ~/Downloads/pronunciation_sv_*.mp3
curl -s https://apifree.forvo.com/action/word-pronunciations/format/json/word/$1/id_lang_speak/157/key/$FORVO_API_KEY |
    jq '[.items[] | select(.code == "sv")] | max_by(.hits) | .pathmp3' |
    xargs -L 1 curl -s --output ~/Downloads/pronunciation_sv_$1.mp3
