#! /bin/bash

## USAGE: ./svenskt-ord.sh ORD
## Where ORD is the swedish word you want to search.

echo "Sök: $1"

echo -n $1 | pbcopy

# replace Swedish vowels for antonym.se
cleaned_word=`echo $1 | sed -e 's/[åÅ]/aa/g' -e 's/[öÖ]/oe/g' -e 's/[äÄ]/ae/g'`

open -a "/Applications/Firefox.app" \
    "https://sv.wiktionary.org/wiki/$1#Svenska" \
    "https://forvo.com/word/$1" \
    "https://www.google.se/search?site=&tbm=isch&source=hp&q=$1&oq=$1&gs_l=img.3..0l10.2298.3088.0.3176.5.5.0.0.0.0.60.218.4.4.0....0...1ac.1.64.img..1.4.216.JMP5u9OU3X8" \
    "http://antonym.se/$cleaned_word" \
    "http://en.bab.la/dictionary/swedish-english/$1" \
    2>/dev/null
