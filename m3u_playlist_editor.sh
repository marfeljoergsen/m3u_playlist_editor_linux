#!/usr/bin/env bash

which dialog &>/dev/null
[ $? -eq 0 ] || { echo "dialog command not found, cannot continue..."; exit 1; }

# Temporary file and trap-stuff:
tmpdir=$(mktemp -d)
trap "rm -rf $tmpdir" EXIT
fname="$tmpdir/$(basename "$0").txt"
groups="$tmpdir/groups.txt"


# Define the dialog exit status codes
: ${DIALOG_OK=0}
: ${DIALOG_CANCEL=1}
: ${DIALOG_ESC=255}

outputFile='selected_groups_only.m3u'

if [ "$#" -eq 0 ]; then
	echo "No input file provided (optionally provide as argument)"
	#inputFile='./m3u_orig.m3u'
else
	inputFile="$1"
fi

if [ -z "$inputFile" ]; then
   inputFile=$(dialog --clear --title "File Viewer" --stdout \
	--backtitle "Space to select file/dir (change directory with space + \"/\"):" \
	--title "Select m3u input file followed by enter:"\
	--fselect ./ 24 85)
fi
[ -d "$inputFile" ] && {
	echo "You choose the directory \"$inputFile\", instead of a file.";
	echo "Please try again (use the spacebar to select a file, then the ENTER-key)...";
        exit 1;}
if [ -s "$inputFile" ]; then
   head -n 1 < "$inputFile" | grep -q '^#EXTM3U' || { \
        echo "Invalid file: \"$inputFile\" ; file must begin with \"#EXTM3U\"..."; \
          exit 2; }
else
   echo "File \"$inputFile\" does not exist, or is empty - cannot continue."; exit 1;
fi

grep -in 'tvg-name' "$inputFile" > "$groups"


#lineRegExp='^\d+(?=:)' # positive lookahead doesn't seem to work?
lineRegExp='^([0-9]*)' # <== This is probably always ok, probably don't touch it
tvgNameRegExp='\"#+ ([^"]*) #+\"' # <== This probably needs to be changed, for different providers!
together="$lineRegExp:.*$tvgNameRegExp"

# Find all lines where the combined regexp matches ("together"): 
#fullRegxp=$(grep -Eo '^([0-9]*):.*tvg-name=\"#+ ([^"]*) #+\"' "$groups")
#fullRegxp=$(grep -Eo '^\d+(?=:).*tvg-name=\"#+ ([^"]*) #+\"' "$groups")
#fullRegxp=$(grep -Eo "$together" "$groups")
#echo "fullRegxp="
#echo "$fullRegxp"

#if fullRegxp=$(grep -Eo "'"$lineRegExp.*$tvgNameRegExp"'" "$groups"); then
#if fullRegxp=$(grep -Eo "hi" "$groups"); then
if fullRegxp=$(grep -Eo "$together" "$groups"); then
  echo "Regular expression for "group"-matching seems valid..."
else
  echo "Regular expression seems invalid - check return code and parameters..."
  exit 1
fi

lines=$(echo "$fullRegxp" | grep -oP "$lineRegExp")
tvgname=$(echo "$fullRegxp" | grep -oP "$tvgNameRegExp")
# For debugging:
#echo -e "lines=\n$lines"
#echo -e "\ntvgname=\n$tvgname"
#exit 0

[ -z "$lines" ] && (echo "No line-markers found: Please fix \"tvgNameRegExp\" - or ensure \"fullRegxp\" finds m3u search groups!"; exit 1)
    echo -e "lines=\n$lines"
    echo -e "\ntvgname=\n$tvgname"
# === Verifying that the numbers match ===
nlines=$(echo "$lines" | wc -l)
ntvgname=$(echo "$tvgname" | wc -l)
if [ "$nlines" != "$ntvgname" ]; then
    echo "--- ERROR: Regexp expression is incorrect, number of lines *must* match..."
    echo "    *** nlines=$nlines"
    echo "    *** ntvgname=$ntvgname"
    echo "--- Please deal with this and consider reporting improvements..."
    exit 1
fi

collected=$(paste <(echo "$lines") <(echo "$tvgname") -d ' ')
#echo " *** collected="

# Append "off", needed by dialog --checklist
echo "$collected" >"$fname"
sed -e 's/$/ off/' -i "$fname"

#awk '{ print $0 " off" }' < $(echo "$collected") > $fname

# open fd
exec 3>&1
#dialog --menu "Choose groups to include:" 65 55 0 --file "$fname"
result=$(dialog --checklist "Choose groups to include (numbering corresponds to input line in file: \"$inputFile\"):" 65 55 0 --file "$fname" 2>&1 1>&3)

# Return value
return_value=$?
# close fd
exec 3>&-

case $return_value in
  $DIALOG_CANCEL)
    echo "Cancel pressed."
    exit 1;;
  $DIALOG_ESC)
    echo "ESC pressed."
    exit 1;;
esac

if [ -z "$result" ]
then
    echo "No groups selected, nothing to do..."; exit 0;
fi

numLines=$(wc -l < "$inputFile")
# Last line does not contain a new line, so compensate:
lastlinenum="$(($numLines + 1))"
lineBeginnings=$(cat "$fname" | cut -d " " -f1)

#echo "result=$result"
#echo "numLines=$numLines"
#echo "lastlinum=$lastlinenum"
#echo "lineBeginnings=$lineBeginnings"

argStr="1"
totLines=1
for lnum in $(echo "$result"); do
  #echo "Processing: $lnum"
  lastLine=$(echo "$lineBeginnings" | grep -A1 "$lnum" | sed -n '2 p')
  if [ -z "$lastLine" ]; then
      lastLine=$lastlinenum
      fixLastLineCount=true
  else
      lastLine=$(($lastLine - 1))
  fi
  #echo "  lastLine=$lastLine"
  argStr="$argStr,$lnum-$lastLine"
  totLines=$(($totLines + 1 - $lnum + $lastLine))
done

echo "Extracting the following lines: $argStr"
echo "Saving the result to the file: \"$outputFile\""
./sedExtractLines.pl "$argStr" "$inputFile" > "$outputFile"

writtenLines=$(wc -l < "$outputFile")
if [ "$fixLastLineCount" ]; then
  writtenLines="$(($writtenLines + 1))";
fi

if [ "$writtenLines" = "$totLines" ]; then
    echo "--- All done ($totLines lines was written to \"$outputFile\"), enjoy! ---"
else
    echo "--- WARNING: Output file: \"$outputFile\" does not have expected lines in it."
    echo "--- Written: $writtenLines ; expected: $totLines"
    echo "--- Consider reporting this issue, to be fixed..."
    exit 1
fi
