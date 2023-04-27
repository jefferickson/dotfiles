#! /bin/bash

## USAGE: ./.finnish-word.sh WORD
## Where WORD is the Finnish word you want to search.

clear
echo "Search: $1"

echo -n $1 | pbcopy

# replace Finnish vowels
cleaned_word=`echo $1 | sed -e 's/[åÅ]/\%C3\%A5/g' -e 's/[öÖ]/\%C3\%B6/g' -e 's/[äÄ]/\%C3\%A4/g'`

/Applications/Firefox.app/Contents/MacOS/firefox \
    --new-tab "https://forvo.com/word/$cleaned_word/#fi" \
    --new-tab "https://www.google.fi/search?site=&tbm=isch&source=hp&q=$cleaned_word&oq=$cleaned_word&gs_l=img.3..0l10.2298.3088.0.3176.5.5.0.0.0.0.60.218.4.4.0....0...1ac.1.64.img..1.4.216.JMP5u9OU3X8" \
    --new-tab "https://kuvapankki.papunet.net/haku/$1" \
    --new-tab "https://kieli.net/sana/$1" \
    --new-tab "https://fi.wiktionary.org/wiki/$cleaned_word#Suomi" \
    --new-tab "http://en.bab.la/dictionary/finnish-english/$cleaned_word" \
    2>/dev/null

trash ~/Downloads/pronunciation_fi_*.mp3
curl -s https://apifree.forvo.com/action/word-pronunciations/format/json/word/$1/id_lang_speak/46/key/$FORVO_API_KEY |
    jq '[.items[] | select(.code == "fi")] | max_by(.hits) | .pathmp3' |
    xargs -L 1 curl -s --output ~/Downloads/pronunciation_fi_$1.mp3

cat ~/git-repos/lennu/output/$1
