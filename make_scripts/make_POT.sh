#!/bin/bash
SCRIPT_PATH=$(dirname "$(realpath -s "$0")")

cd "$SCRIPT_PATH"/../src || exit

CLI_VERSION=$(./install_waterfox_CLI.py -v | sed 's/CLI installer of Waterfox for Linux //')
GUI_VERSION=$(grep -hr "appVersion" ./install_waterfox_GUI.py | head -1 | cut -d "=" -f2 | awk '{print $1}' | tr -d '"')
PYTHON_VERSION=$(python3 -V |  sed 's/Python //' | sed 's/\..$//')

xgettext /usr/lib/python"$PYTHON_VERSION"/argparse.py install_waterfox_CLI.py -o ./locales/CLI/install_waterfox_CLI.pot --package-name="install_waterfox_CLI" --package-version="$CLI_VERSION"

xgettext install_waterfox_common.py -o ./locales/common/install_waterfox_common.pot --package-name="install_waterfox_common" --package-version="$CLI_VERSION"

xgettext install_waterfox_GUI.py GUI.glade -o ./locales/GUI/install_waterfox_GUI.pot --package-name="install_waterfox_GUI" --package-version="$GUI_VERSION"
