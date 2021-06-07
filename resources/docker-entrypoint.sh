#!/bin/sh
# Get options
keep_tex="0"
while getopts "k" "opt"; do
    case "$opt" in
        k)
            keep_tex=1
            ;;
    esac
done
shift "$(expr $OPTIND - 1)"

# The first argument must always be the path to the main paper
# file. The working directory is switched to the folder that the
# paper file is in.
input="$1"
shift

input_file="$(basename $input)"
cd "$(dirname $input)"

## Create LaTeX file.
if [ "$keep_tex" -ge 1 ]; then
    /usr/local/bin/pandoc \
        --defaults="$OPENJOURNALS_PATH"/docker-defaults.yaml \
        --defaults="$OPENJOURNALS_PATH"/"$JOURNAL"/defaults.yaml \
        --output=paper.tex \
        "$input_file" \
        "$@"
fi

## Create full PDF
/usr/local/bin/pandoc \
    --defaults="$OPENJOURNALS_PATH"/docker-defaults.yaml \
    --defaults="$OPENJOURNALS_PATH"/"$JOURNAL"/defaults.yaml \
    "$input_file" \
    "$@"
