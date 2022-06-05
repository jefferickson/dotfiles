#! /bin/bash

## USAGE: ./.esperanto-word.sh VORTO WORD
## Where VORTO is the Esperanto word you want to search and WORD is the English translation (for image search).

echo "Search: $1 ($2)"

echo -n $1 | pbcopy

/Applications/Firefox.app/Contents/MacOS/firefox \
    --new-tab "https://eo.wiktionary.org/wiki/$1#Esperanto" \
    --new-tab "https://forvo.com/word/$1/#eo" \
    --new-tab "https://www.google.com/search?site=&tbm=isch&source=hp&q=$2&oq=$2&gs_l=img.3..0l10.2298.3088.0.3176.5.5.0.0.0.0.60.218.4.4.0....0...1ac.1.64.img..1.4.216.JMP5u9OU3X8" \
    --new-tab "http://en.bab.la/dictionary/english-esperanto/$1" \
    2>/dev/null
