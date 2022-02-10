#!/bin/bash
SCRIPT_PATH=$(dirname "$(realpath -s "$0")")
MAIN_PATH=$(git -C "$SCRIPT_PATH" rev-parse --show-toplevel)
TEMP_PATH="$MAIN_PATH"/install_waterfox_"$1"

if [ -d "$TEMP_PATH" ]; then
    rm -rf "$TEMP_PATH"
fi

mkdir -p "$TEMP_PATH"
cd "$MAIN_PATH/src" || exit
cp ./{install_waterfox_"$1".py,install_waterfox_common.py,install_waterfox_desktop_entry} "$TEMP_PATH"
if [ "$1" == "GUI" ]; then
    cp ./GUI.glade "$TEMP_PATH"
fi

mkdir -p "$TEMP_PATH"/locales
cp ./locales/"$1"/* "$TEMP_PATH"/locales

cd "$TEMP_PATH"/locales || exit

for file in *.po
do
    mkdir -p "$(basename "$file" .po)"/LC_MESSAGES
    msgfmt "$file" -o ./"$(basename "$file" .po)"/LC_MESSAGES/install_waterfox_"$1".mo
    rm -rf "$file"
done
rm -rf ./install_waterfox_"$1".pot

cp "$MAIN_PATH"/src/locales/common/* "$TEMP_PATH"/locales
for file in *.po
do
    mkdir -p "$(basename "$file" .po)"/LC_MESSAGES
    msgfmt "$file" -o ./"$(basename "$file" .po)"/LC_MESSAGES/install_waterfox_common.mo
    rm -rf "$file"
done
rm -rf ./install_waterfox_common.pot

cd "$MAIN_PATH" || exit

if [ ! -d "./artifacts" ]; then
    mkdir ./artifacts
fi

if [ "$1" == "GUI" ]; then
    VERSION=$(grep -hr "appVersion" ./src/install_waterfox_GUI.py | head -1 | cut -d "=" -f2 | awk '{print $1}' | tr -d '"')
else
    VERSION=$(./install_waterfox_CLI.py -v | sed 's/CLI installer of Waterfox for Linux //')
fi

zipFile="./artifacts/install_waterfox_$1-$VERSION.zip"
if [ -f "$zipFile" ]; then
    rm -rf "$zipFile"
fi
zip -r9 "$zipFile" ./install_waterfox_"$1"
rm -rf ./install_waterfox_"$1"
./make_scripts/make_checksum.py "$zipFile"
