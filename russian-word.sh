#! /bin/bash

## USAGE: ./russian-word.sh WORD

echo "Search: $1"

echo -n $1 | pbcopy

open -a "/Applications/Firefox.app" \
    "https://ru.wiktionary.org/wiki/$1#Русский" \
    "https://forvo.com/word/$1" \
    "https://www.google.ru/search?site=&tbm=isch&source=hp&q=$1&oq=$1&gs_l=img.3..0l10.2298.3088.0.3176.5.5.0.0.0.0.60.218.4.4.0....0...1ac.1.64.img..1.4.216.JMP5u9OU3X8" \
    "http://en.bab.la/dictionary/russian-english/$1" \
    2>/dev/null
