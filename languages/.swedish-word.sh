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

trash ~/Downloads/speechify_sv_*.mp3
curl -s -X POST https://api.sws.speechify.com/v1/audio/speech \
     -H "Authorization: Bearer $SPEECHIFY_API_KEY" \
     -H "Content-Type: application/json" \
     -d "{
  \"input\": \"$1\",
  \"voice_id\": \"asa\",
  \"audio_format\": \"mp3\",
  \"language\": \"sv-SE\",
  \"model\": \"simba-multilingual\"
}" |
jq '.audio_data' |
tr -d '"' |
base64 --decode > ~/Downloads/speechify_sv_$1.mp3

trans -b sv:en+fi $1
