#!/usr/bin/env python3
# coding=utf-8
# pylint: disable=C0103
# pylint: disable=consider-using-f-string
"""
Installation and uninstallation script for Waterfox
Depends: Python 3.5+

MIT License

Copyright (c) 2022 hawkeye116477

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""
import os
import sys
import argparse
import gettext
import re
import install_waterfox_common as installcommon

appName = "CLI installer of Waterfox for Linux"
appVersion = "1.5.0"
pj = os.path.join

domain = "install_waterfox_CLI"
localeDir = pj(sys.path[0], 'locales')
gettext.bindtextdomain(domain, localeDir)
gettext.textdomain(domain)
_ = gettext.gettext


def menu(message, options, exitName):
    """Create menu"""
    print(message)
    if not _("Yes") in options:
        options = sorted(options)
    if exitName and exitName not in options:
        options.append(exitName)
    for idx, option in enumerate(options, 1):
        print("{}) {}".format(idx, option))

    choice = input(_('Enter your choice: '))

    while not choice.isdigit() or choice == "0" or int(choice) > len(options):
        print(_("\nInvalid option. Please try again."))
        print("-----------------------------------")
        choice = input(_('Enter your choice: '))

    option = options[int(choice) - 1]

    if option == exitName:
        sys.exit(0)
    elif option:
        if option == _("Yes"):
            option = "yes"
        if option == _("No"):
            option = "no"
        print("-----------------------------------")
        return option


# Parse arguments
parser = argparse.ArgumentParser(
    description=_('Installation and uninstallation script for Waterfox'))
parser.add_argument("-v", "--version",
                    help=_("display script version"),
                    action='version', version=appName + ' ' + appVersion)
parser.add_argument("-sp", "--spath",
                    help=_("set path to directory of installable package(s)"),
                    default=os.path.dirname(os.path.realpath(__file__)))
parser.add_argument("-ip", "--ipath",
                    help=_("set installation path (folder with package name will be here)"))
parser.add_argument("-s", "--silent",
                    help=_("enable unattended installation mode" +
                           " (valid configuration file and full source path is required)"),
                    action='store_true')
args = parser.parse_args()

sourcePath = args.spath

conf = installcommon.settings()

if args.ipath is not None:
    installPath = args.ipath
else:
    installPath = conf.installPath

silent = bool(False)
if args.silent:
    silent = bool(True)


confPath = pj(os.getenv('XDG_CONFIG_HOME',
                        os.path.expanduser("~/.config")), "install_waterfox")
confFile = pj(confPath, "settings.conf")


# Create menu with actions
if not silent:
    actions = [_("Install"), _("Uninstall")]
    chosenAction = menu(
        _("What do you want to do with Waterfox?"), actions, _("Quit"))
else:
    chosenAction = _("Install")

if chosenAction == _("Install"):
    if os.geteuid() == 0:
        repoLink = "https://github.com/hawkeye116477/waterfox-deb-rpm-arch-AppImage"
        print(_("This program was created for installing Waterfox only for one user, "
              "because updater of this package doesn't work correctly for root user. "
                "If you wanted to install it for all users, "
                "then go to {URL} for more information, "
                "otherwise run this program again as normal user.").format(
            URL=repoLink))
        sys.exit(0)

    # Detect installable packages
    packages = []
    if not os.path.exists(sourcePath):
        print(_("The specified path does not exist!"))
        sys.exit(0)
    if os.path.isfile(sourcePath):
        packages.append(sourcePath)
    else:
        print(_("Detecting installable packages..."))
        for root, dirs, files in os.walk(sourcePath):
            for file in files:
                if re.match(r"waterfox-*.*(tar\.bz2|AppImage)$", file):
                    packages.append(pj(root, file))

    packageTypes = []
    if packages:
        for package in packages:
            package = os.path.basename(package)
            if re.match(r"^waterfox-classic", package):
                packageTypes.append("Classic")
            if re.match(r"^waterfox-current", package):
                packageTypes.append("Current")
            if re.match(r"^waterfox-(G3|g3)", package):
                packageTypes.append("G3")
            if re.match(r"^waterfox-(G4|g4)", package):
                packageTypes.append("G4")

    if packageTypes:
        packageTypes = list(sorted(set(packageTypes)))

    if len(packageTypes) < 1:
        print(_("No installable packages found."))
        print(_("Please place this script next to the tarball/AppImage packages " +
              "or launch it again with flag -sp=<path>."))
        sys.exit(0)

    # Create menu with package types
    if len(packageTypes) > 2:
        chosenPackageType = menu(_("Which package are you interested in?"),
                                 packageTypes, _("None"))
    else:
        chosenPackageType = packageTypes[0]

    if chosenPackageType == "G3":
        packageTypeName = "(G3|g3)"
    elif chosenPackageType == "G4":
        packageTypeName = "(G4|g4)"
    else:
        packageTypeName = chosenPackageType.lower()

    chosenPackages = []
    if packages and packageTypeName:
        for package in packages:
            if re.match(r"^waterfox\-" + packageTypeName, os.path.basename(package)):
                chosenPackages.append(package)

    if len(chosenPackages) > 1:
        chosenPackage = menu(
            _("Which package do you want to install?"), chosenPackages, _("None"))
    else:
        chosenPackage = chosenPackages[0]

    if silent:
        if conf.installDesktopShortcut is not None:
            installDesktopShortcut = conf.installDesktopShortcut
        if conf.useSystemDictionaries is not None:
            useSystemDictionaries = conf.useSystemDictionaries
        if conf.removeArchive is not None:
            removeArchive = conf.removeArchive

    if not 'installDesktopShortcut' in vars():
        installDesktopShortcut = menu(_("Do you want to add a desktop shortcut?"),
                                      [_("Yes"), _("No")], "")
    if not 'useSystemDictionaries' in vars():
        useSystemDictionaries = menu(_("Do you want to use system's dictionaries?"),
                                     [_("Yes"), _("No")], "")
    if not 'removeArchive' in vars():
        removeArchive = menu(_("Do you want to remove tarball/AppImage package "
                               "after completing the installation?"),
                             [_("Yes"), _("No")], "")

    installcommon.install(chosenPackage, installPath, chosenPackageType,
                          installDesktopShortcut, useSystemDictionaries,
                          removeArchive, confFile, print)
elif chosenAction == _("Uninstall"):
    # Detect installed packages
    packages = []
    if not os.path.exists(installPath):
        print(_("The specified path does not exist!"))
        sys.exit(0)
    print(_("Detecting installed packages..."))
    packageTypes = []
    for entry in os.scandir(installPath):
        if entry.is_dir() and re.match(r"^waterfox-(classic|current|g\d+)", entry.name):
            packageTypes.append(entry.name.replace("waterfox-", "").title())
    if packageTypes:
        packageTypes = list(sorted(set(packageTypes)))

    if len(packageTypes) < 1:
        print(_("No installed packages found."))
        print(_("Please launch script again with flag -ip=<path>."))
        sys.exit(0)

    chosenPackageType = ""
    if len(packageTypes) > 1:
        chosenPackageType = menu(
            _("Which package do you want to uninstall?"), packageTypes, _("None"))
    else:
        chosenPackageType = packageTypes[0]
        print(_("Detected Waterfox {chosenPackageType}.").format(**locals()))

    confirmed = menu(_("Are you sure that you want to uninstall Waterfox {chosenPackageType}?"
                       .format(**locals())),
                     [_("Yes"), _("No")], "")
    if confirmed == _("No"):
        sys.exit(0)

    removeConfFile = menu(_("Do you want to remove file with installer settings?"),
                          [_("Yes"), _("No")], "")
    installcommon.uninstall(
        installPath, chosenPackageType, confFile, removeConfFile, print)
elif chosenAction == _("Quit"):
    sys.exit(0)
