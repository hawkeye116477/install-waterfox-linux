#!/usr/bin/env python3
# coding=utf-8
# pylint: disable=C0103
# pylint: disable=consider-using-f-string
# pylint: disable=wrong-import-position
"""
Installation and uninstallation app for Waterfox
Depends: Python 3.5+, PyGObject
"""
import os
import sys
import re
import threading
import gettext
import locale
import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, GLib
import install_waterfox_common as installcommon


appName = "GUI installer of Waterfox for Linux"
appVersion = "1.0.1"
pj = os.path.join

domain = "install_waterfox_GUI"
localeDir = pj(sys.path[0], 'locales')
locale.bindtextdomain(domain, localeDir)
gettext.bindtextdomain(domain, localeDir)
gettext.textdomain(domain)
_ = gettext.gettext


class Handler:
    def gtk_main_quit(self, *_args):
        Gtk.main_quit()

    def on_assistant_draw(self, assistant, _cr):
        assistant.set_title(appName + " " + appVersion)

    def on_assistant_prepare(self, _assistant, _page):
        currentPage = window.get_current_page()
        if currentPage == 0:
            backBtn.hide()
        else:
            backBtn.show()
        if currentPage != 2:
            installBtn.hide()
            nextBtn.show()
        else:
            installBtn.show()
            nextBtn.hide()
            progress.hide()
        mode = modeChooser.get_active_text()
        if mode == _("Installation"):
            installBtn.set_label(_("Install"))
            finalLabel.set_text(_("Click Install to begin the installation or click Close if you want to review or change any settings."))
        else:
            installBtn.set_label(_("Uninstall"))
            finalLabel.set_text(_("Click Uninstall to begin the uninstallation or click Close if you want to review or change any settings."))

    def on_installBtn_clicked(self, _button):
        cancelBtn.set_sensitive(False)
        backBtn.hide()
        installBtn.hide()
        thread = threading.Thread(target=finalize)
        thread.daemon = True
        thread.start()

    def on_acceptLicense_toggled(self, button):
        if button.get_active():
            nextBtn.set_sensitive(True)
        else:
            nextBtn.set_sensitive(False)

    def on_modeChooser_changed(self, comboboxtext):
        mode = comboboxtext.get_active_text()
        elementsToToggle = [fileChooseLabel,
                            fileChooseFB, installTasks]
        for element in elementsToToggle:
            if mode == _("Uninstallation"):
                element.hide()
            else:
                element.show()
        elementsToToggle = [uninstallTasks, packageLabel, packageChooser]
        for element in elementsToToggle:
            if mode == _("Installation"):
                element.hide()
            else:
                element.show()
        setPackageNames()

    def on_installPathField_changed(self, _entry):
        setPackageNames()

    def on_fileChooseBtn_clicked(self, _button):
        dialog = Gtk.FileChooserDialog(
            title=_("Choose a file"),
            parent=window,
            action=Gtk.FileChooserAction.OPEN,
        )
        dialog.add_buttons(Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL,
                           _("Select"), Gtk.ResponseType.OK)

        filterAppimage = Gtk.FileFilter()
        filterAppimage.set_name("AppImage")
        filterAppimage.add_pattern("waterfox-*.AppImage")
        dialog.add_filter(filterAppimage)

        filterTarball = Gtk.FileFilter()
        filterTarball.add_pattern("waterfox-*.tar.*")
        filterTarball.set_name("Tar")
        dialog.add_filter(filterTarball)

        response = dialog.run()
        if response == Gtk.ResponseType.OK:
            fileChooseField.set_text(dialog.get_filename())
        dialog.destroy()

    def on_installPathBtn_clicked(self, _button):
        dialog = Gtk.FileChooserDialog(
            title=_("Choose a folder"),
            parent=window,
            action=Gtk.FileChooserAction.SELECT_FOLDER,
        )
        dialog.add_buttons(Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL,
                           _("Select"), Gtk.ResponseType.OK)

        response = dialog.run()
        if response == Gtk.ResponseType.OK:
            installPathField.set_text(dialog.get_filename())
        dialog.destroy()
        setPackageNames()

    def on_nextBtn_clicked(self, _button):
        window.next_page()

    def on_backBtn_clicked(self, _button):
        window.previous_page()


def str2Bool(string):
    if string == "yes":
        string = bool(True)
    else:
        string = bool(False)
    return string


def bool2Str(boolean):
    if boolean is True:
        boolean = "yes"
    else:
        boolean = "no"
    return boolean


def displayMsg(text):
    GLib.idle_add(progress.pulse)
    if log.get_text() != "":
        GLib.idle_add(log.set_text, log.get_text() + "\n" + text)
    else:
        GLib.idle_add(log.set_text, text)


def setPackageNames():
    mode = modeChooser.get_active_text()
    if mode == _("Uninstallation"):
        packageChooser.remove_all()
        if os.path.exists(installPathField.get_text()):
            packageTypes = []
            for entry in os.scandir(installPathField.get_text()):
                if entry.is_dir() and re.match(r"^waterfox-(classic|current|g\d+)", entry.name):
                    packageTypes.append(
                        entry.name.replace("waterfox-", "").title())
            if packageTypes:
                i = 0
                for packageType in list(sorted(set(packageTypes))):
                    packageChooser.insert_text(i, packageType)
                    i += 1
                packageChooser.set_active(0)


def finalize():
    mode = modeChooser.get_active_text()
    installPath = installPathField.get_text()
    confPath = pj(os.getenv('XDG_CONFIG_HOME',
                            os.path.expanduser("~/.config")), "install_waterfox")
    confFile = pj(confPath, "settings.conf")
    finalLabel.hide()
    progress.show()
    if mode == _("Installation"):
        chosenPackage = fileChooseField.get_text()
        packageFile = os.path.basename(chosenPackage)
        if re.match(r"^waterfox-", packageFile):
            chosenPackageType = str(os.path.splitext(packageFile)[0]).replace("waterfox-", "").capitalize().split(".", 1)[0].split("-", 1)[0]
        installcommon.install(chosenPackage, installPath, chosenPackageType,
                              bool2Str(createDesktopShortcut.get_active()),
                              bool2Str(systemDictionaries.get_active()),
                              bool2Str(removePackage.get_active()), confFile, displayMsg)
    else:
        installcommon.uninstall(installPath, packageChooser.get_active_text(), confFile,
                                bool2Str(removeConf.get_active()), displayMsg)
    cancelBtn.set_sensitive(True)
    progress.hide()

scriptPath = os.path.dirname(os.path.realpath(__file__))
builder = Gtk.Builder()
builder.add_from_file(pj(scriptPath, "GUI.glade"))
builder.connect_signals(Handler())

window = builder.get_object("assistant")
backBtn = builder.get_object("backBtn")
nextBtn = builder.get_object("nextBtn")
cancelBtn = builder.get_object("cancelBtn")
installBtn = builder.get_object("installBtn")
firstPage = builder.get_object("page1")
modeChooser = builder.get_object("modeChooser")
fileChooseLabel = builder.get_object("fileChooseLabel")
fileChooseField = builder.get_object("fileChooseField")
fileChooseFB = builder.get_object("fileChooseFB")
installTasks = builder.get_object("installTasks")
uninstallTasks = builder.get_object("uninstallTasks")
installPathField = builder.get_object("installPathField")
createDesktopShortcut = builder.get_object("createDesktopShortcut")
systemDictionaries = builder.get_object("systemDictionaries")
removePackage = builder.get_object("removePackage")
removeConf = builder.get_object("removeConf")
packageLabel = builder.get_object("packageLabel")
packageChooser = builder.get_object("packageChooser")
finalLabel = builder.get_object("finalLabel")
log = builder.get_object("log")
progress = builder.get_object("progress")

conf = installcommon.settings()
installPathField.set_text(conf.installPath)
if hasattr(conf, "installDesktopShortcut"):
    createDesktopShortcut.set_active(str2Bool(conf.installDesktopShortcut))
if hasattr(conf, "useSystemDictionaries"):
    systemDictionaries.set_active(str2Bool(conf.useSystemDictionaries))
if hasattr(conf, "removeArchive"):
    removePackage.set_active(str2Bool(conf.removeArchive))

window.show_all()
widgetsToHide = [uninstallTasks, packageLabel, packageChooser]
for widget in widgetsToHide:
    widget.hide()

Gtk.main()
