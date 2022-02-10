#!/usr/bin/env python3
# coding=utf-8
# pylint: disable=C0103
# pylint: disable=consider-using-f-string
"""
Common functions for CLI and GUI installer scripts for Waterfox
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
import shutil
import subprocess
import configparser
import re
import stat
import gettext

pj = os.path.join
t = gettext.translation('install_waterfox_common', pj(
    sys.path[0], 'locales'), fallback=True)
_ = t.gettext


class settings:
    def __init__(self):
        self.installPath = os.path.expanduser("~/.local/lib")
        confPath = pj(os.getenv('XDG_CONFIG_HOME',
                                os.path.expanduser("~/.config")), "install_waterfox")
        confFile = pj(confPath, "settings.conf")
        conf = configparser.ConfigParser()

        if os.path.isfile(confFile):
            with open(confFile, "r", encoding='utf-8') as conf_f:
                confFileContent = conf_f.read()
                if confFileContent.split('\n', 1)[0] == "[global]":
                    conf.read_string(confFileContent)
                else:
                    conf.read_string('[global]\n' + confFileContent)
                if conf.has_option("global", "InstallPath"):
                    self.installPath = conf["global"]["InstallPath"]
                if conf.has_option("global", "InstallDesktopShortcut"):
                    self.installDesktopShortcut = conf["global"]["InstallDesktopShortcut"]
                if conf.has_option("global", "UseSystemDictionaries"):
                    self.useSystemDictionaries = conf["global"]["UseSystemDictionaries"]
                if conf.has_option("global", "RemoveArchive"):
                    self.removeArchive = conf["global"]["RemoveArchive"]


def install(sourcePath, installPath, chosenPackageType, installDesktopShortcut,
            useSystemDictionaries, removeArchive, configFilePath, printDef):
    # Make install directory if not already exist
    if not os.path.exists(installPath):
        printDef(_("Making {installPath} directory...").format(**locals()))
        os.makedirs(installPath)

    # Remove older version
    lowerChosenPackageType = chosenPackageType.lower()
    packagePath = pj(installPath, "waterfox-" + lowerChosenPackageType)
    if os.path.isdir(packagePath):
        printDef(_("Removing older installed version..."))
        shutil.rmtree(packagePath)

    # Unpack Waterfox into the install directory
    printDef(_("Unpackaging {package} into {installPath} directory...")
          .format(package=os.path.basename(sourcePath), installPath=installPath))
    tempPath = pj(installPath, "temp")
    if os.path.exists(tempPath):
        shutil.rmtree(tempPath)
    os.makedirs(tempPath)
    if re.match(r".*\.AppImage$", sourcePath):
        os.chmod(sourcePath, os.stat(sourcePath).st_mode | stat.S_IEXEC | stat.S_IXUSR |
                 stat.S_IXGRP | stat.S_IXOTH)
        os.chdir(tempPath)
        subprocess.run([sourcePath, '--appimage-extract'], check=True)
        shutil.move("./squashfs-root/usr/bin/waterfox-" + lowerChosenPackageType,
                    "./squashfs-root/usr/bin/waterfox")
        oldPackagePath = "./squashfs-root/usr/bin"
        for f in os.listdir(oldPackagePath):
            shutil.move(pj(oldPackagePath, f), "./")
        shutil.rmtree("./squashfs-root")
        os.makedirs(packagePath)
    else:
        shutil.unpack_archive(sourcePath, tempPath)

    for f in os.listdir(tempPath):
        shutil.move(pj(tempPath, f), packagePath)

    if os.path.exists(tempPath):
        shutil.rmtree(tempPath)

    # Install a wrapper to avoid confusion about binary path
    printDef(_("Creating executable file..."))
    binPath = os.path.expanduser("~/.local/bin")
    if not os.path.exists(binPath):
        os.makedirs(binPath)
    wrapperTxt = '''\
#!/bin/bash
if [ "$XDG_CURRENT_DESKTOP" == "KDE" ]; then
    export GTK_USE_PORTAL=1
fi
exec {installPath}/waterfox-{lowerChosenPackageType}/waterfox "$@"
'''.format(installPath=installPath, lowerChosenPackageType=lowerChosenPackageType)
    with open(pj(binPath, "waterfox-" + lowerChosenPackageType), "w+", encoding='utf-8') as wrapper:
        wrapper.write(wrapperTxt)
    os.chmod(pj(binPath, "waterfox-" + lowerChosenPackageType), 0o755)

    # Create start menu shortcut
    printDef(_("Generating start menu shortcut..."))
    desktopEntryPath = os.path.expanduser("~/.local/share/applications")
    if not os.path.exists(desktopEntryPath):
        os.makedirs(desktopEntryPath)
    desktopEntryPath = pj(desktopEntryPath, "waterfox-" +
                          lowerChosenPackageType + ".desktop")
    scriptPath = os.path.dirname(os.path.realpath(__file__))
    shutil.copy(pj(scriptPath, "install_waterfox_desktop_entry"),
                desktopEntryPath)
    with open(desktopEntryPath, 'r', encoding='utf-8') as desktopEntry:
        data = desktopEntry.read()
    data = data.replace("{lowerChosenPackageType}", lowerChosenPackageType)
    data = data.replace("{chosenPackageType}", chosenPackageType)
    data = data.replace("{binAppPath}", os.path.join(
        binPath, "waterfox-" + lowerChosenPackageType))
    with open(desktopEntryPath, 'w', encoding='utf-8') as desktopEntry:
        desktopEntry.write(data)
    os.chmod(desktopEntryPath, 0o644)

    # Create symlinks
    sizes = ["16", "22", "24", "32", "48", "128", "256"]
    printDef(_("Creating symlinks to icons..."))
    iconsPath = os.path.expanduser("~/.local/share/icons/hicolor")
    for size in sizes:
        if not os.path.exists(pj(iconsPath, size + "x" + size, "apps")):
            os.makedirs(pj(iconsPath, size + "x" + size, "apps"))
        if not os.path.islink(pj(iconsPath, size + "x" + size,
                                 "apps/waterfox-" + lowerChosenPackageType + ".png")):
            os.symlink(pj(installPath, "waterfox-" + lowerChosenPackageType,
                          "browser/chrome/icons/default/default" + size + ".png"),
                       pj(iconsPath, size + "x" + size, "apps/waterfox-" + lowerChosenPackageType + ".png"))

    # Refresh icons cache
    printDef(_("Refreshing icons cache..."))
    subprocess.run(["gtk-update-icon-cache", '-q',
                   '-t', '-f', iconsPath], check=True)

    # Install optional desktop shortcut
    if installDesktopShortcut == "yes":
        desktopPath = subprocess.run(['xdg-user-dir', 'DESKTOP'], check=True,
                                     universal_newlines=True, stdout=subprocess.PIPE).stdout.strip()
        printDef(_("Installing desktop shortcut..."))
        if not os.path.islink(pj(desktopPath, "waterfox-" + lowerChosenPackageType + ".desktop")):
            os.symlink(desktopEntryPath,
                       pj(desktopPath, "waterfox-" + lowerChosenPackageType + ".desktop"))

    # Add vendor default settings
    if useSystemDictionaries == "yes":
        printDef(_("Adding path to system's dictionaries..."))
        dictPath = "/usr/share/myspell"
        if os.path.exists("/usr/share/hunspell"):
            dictPath = "/usr/share/hunspell"
        if not os.path.exists(pj(installPath, "waterfox-" + lowerChosenPackageType,
                                 "browser/defaults/preferences")):
            os.makedirs(pj(installPath, "waterfox-" +
                        lowerChosenPackageType, "browser/defaults/preferences"))
        with open(pj(installPath, "waterfox-" + lowerChosenPackageType,
                     "browser/defaults/preferences/spellcheck.js"),
                  'w+', encoding='utf-8') as spellcheckPref:
            spellcheckPref.write(
                'pref("spellchecker.dictionary_path", "{}");'.format(dictPath))
        shutil.rmtree(pj(installPath, "waterfox-" +
                      lowerChosenPackageType, "dictionaries"))

    # Remove installed archive file
    if removeArchive == "yes":
        printDef(_("Removing {sourcePath} ...").format(**locals()))
        os.remove(sourcePath)

    # Save settings
    printDef(_("Saving settings..."))
    conf = configparser.ConfigParser()
    conf["global"] = {}
    confG = conf["global"]
    confG["InstallPath"] = installPath
    confG["InstallDesktopShortcut"] = installDesktopShortcut
    confG["UseSystemDictionaries"] = useSystemDictionaries
    confG["RemoveArchive"] = removeArchive
    with open(configFilePath, 'w+', encoding='utf-8') as confFile:
        conf.write(confFile)

    # Finish
    printDef("-----------------------------------")
    grinningFace = "\N{grinning face}"
    printDef(_("Waterfox {chosenPackageType} has been installed in {installPath} {grinningFace}!")
          .format(chosenPackageType=chosenPackageType,
          installPath=installPath,
          grinningFace=grinningFace))


def uninstall(installPath, chosenPackageType, configFilePath, removeConfigFile, printDef):
    lowerChosenPackageType = chosenPackageType.lower()

    # Remove main app directory
    appPath = pj(installPath, "waterfox-" + lowerChosenPackageType)
    printDef(_("Removing {appPath} directory...").format(**locals()))
    shutil.rmtree(appPath)

    # Remove executable file
    binPath = [pj("/usr/bin", "waterfox-" + lowerChosenPackageType),
               os.path.expanduser("~/.local/bin/" + "waterfox-" + lowerChosenPackageType)]
    if os.path.exists(binPath[0]) or os.path.exists(binPath[1]):
        printDef(_("Removing executable file..."))
    if os.path.exists(binPath[0]):
        printDef(_("Root priveleges are required to remove {execFile}!").format(
            execFile=binPath[0]))
        subprocess.run(["sudo", 'rm', "-vrf", binPath[0]], check=True)
    if os.path.exists(binPath[1]):
        os.remove(binPath[1])

    # Remove start menu shortcut
    desktopEntryPath = [pj("/usr/share/applications",
                           "waterfox-" + lowerChosenPackageType + ".desktop"),
                        pj(os.path.expanduser("~/.local/share/applications"),
                           "waterfox-" + lowerChosenPackageType + ".desktop")]
    if os.path.exists(desktopEntryPath[0]) or os.path.exists(desktopEntryPath[1]):
        printDef(_("Removing start menu shortcut..."))
    if os.path.exists(desktopEntryPath[0]):
        printDef(_("Root priveleges are required to remove {path}!").format(
            path=desktopEntryPath[0]))
        subprocess.run(["sudo", 'rm', "-vrf", desktopEntryPath[0]], check=True)
    if os.path.exists(desktopEntryPath[1]):
        os.remove(desktopEntryPath[1])

    # Remove desktop shortcut
    desktopPath = subprocess.run(['xdg-user-dir', 'DESKTOP'], check=True,
                                 universal_newlines=True, stdout=subprocess.PIPE).stdout.strip()
    if os.path.exists(pj(desktopPath, "waterfox-" + lowerChosenPackageType + ".desktop")):
        printDef(_("Removing desktop shortcut..."))
        os.remove(pj(desktopPath, "waterfox-" +
                  lowerChosenPackageType + ".desktop"))

    # Remove symlinks to icons
    sizes = ["16", "22", "24", "32", "48", "128", "256"]
    iconsPath = ["/usr/share/icons/hicolor",
                 "~/.local/share/icons/hicolor"]
    for size in sizes:
        fileToRemove = [pj(iconsPath[0], size + "x" + size,
                           "apps/waterfox-" + lowerChosenPackageType + ".png"),
                        pj(iconsPath[1], size + "x" + size,
                        "apps/waterfox-" + lowerChosenPackageType + ".png")]
        if os.path.islink(fileToRemove[0]):
            printDef(_("Removing {file} ...").format(file=fileToRemove[0]))
            printDef(_("Root priveleges are required to remove symlinks to icons!"))
            subprocess.run(["sudo", 'rm', "-vrf", fileToRemove[0]], check=True)
        if os.path.islink(fileToRemove[1]):
            printDef(_("Removing {file} ...").format(file=fileToRemove[1]))
            os.remove(fileToRemove[1])

    # Remove install directory if empty
    if not os.listdir(installPath):
        printDef(
            _("Removing empty {installPath} directory...").format(**locals()))
        os.rmdir(installPath)

    # Remove config file
    if removeConfigFile == "yes" and os.path.isfile(configFilePath):
        printDef(_("Removing file with installer settings..."))
        os.remove(configFilePath)

    # Finish
    printDef("-----------------------------------")
    disappointedFace = "\N{disappointed face}"
    printDef(_("Waterfox {chosenPackageType} has been uninstalled {disappointedFace}.")
          .format(chosenPackageType=chosenPackageType, disappointedFace=disappointedFace))
