# m3u_playlist_editor_linux
Extractor (editor) for m3u-file groups (extracts 
m3u-groups from a larger file and saves the 
result in a smaller m3u-file).

## Instructions and UI
This is an m3u (playlist) editor for Linux.
You need your own m3u file to use as input.
Start the program by running the
"./m3u_playlist_editor.sh"-script and it'll
automatically ask you for an m3u-input file
to use. The output file is currently named
"selected_groups_only.m3u" and fixed. The
script allows one to easily extract the groups,
to be used from the input file (see screenshot).
The selected groups will be saved in a new
m3u-file, which is simpler (smaller and loads
faster).
![alt text](group_selection.png?raw=true "Example UI")

## Bugs
The script uses perl, grep, wc, regexp, sed,
dialog and similar *NIX-tools. Do not expect
the script to work, if these are not installed.
I do not promise I'll fix/resolve all reported
issues - but would like it to work on most (or
all) Linux-systems ; if you make improvements
that could benefit others, please notify
and I shall update the code.
