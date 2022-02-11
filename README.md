# install-waterfox-linux
Installs and uninstalls official and AppImage Waterfox packages on every 64-bit Linux distribution.


**Tip: AppImage package doesn't require installing. It can be just launched by setting as executable and clicking into it, but when it's unpacked it may run faster and you can edit some files if you want.**

# Instructions
## a) GUI (graphical)
### Running application
To run this app you'll need `gettext`, `Python 3.5+`, `PyGObject (python3-gi/python-gobject)`, `Python 3 Cairo bindings for the GObject library (python3-gi-cairo/python-cairo)` and `GTK+ 3.22+ (libgtk-3-0/gtk3)` installed, but in most distributions they are already available by default.
Then after you extract zip archive, you need to launch `install_waterfox_GUI.py` file.

### Installing/uninstalling Waterfox
It's rather not necessary to describe that, cuz it's really easy to do that.

## b) CLI (command line)
### Running script
To run this script you'll need `gettext` and `Python 3.5+` installed, but in most distributions they are already available by default.
Then after you extract zip archive, you need to launch `install_waterfox_CLI.py` script in your console.

### Available options
You can launch script with flag `-h` to get list of available options.

### Installing Waterfox
If you have .tar.bz2 or AppImage file on same directory as script, then just run it, choose **Install** option.
Otherwise rerun it with flag `-sp=<path>`, where `<path>` is place where you have your tarballs or AppImages.

Script should ask you few questions about shortcuts, symlinks and then install Waterfox on **$HOME/.local/lib** (you can change installation directory with flag `-ip=<path>`, where `<path>` is place where will be folder with package name). It should display you message when installation completed.

### Uninstalling Waterfox
Just run this script and choose **Uninstall** option.
By default it looks for programs in last saved path. If you have apps in multiple paths, then you need to relauch it with flag `-ip=<path>`, where `<path>` is place where is folder with package name.

Script should ask you if you want to remove configuration file and display message when uninstallation completed.

## c) For translators
If you want to translate installer to your language, then you need `Poedit` installed. If you already have it, then go to `src/locales/GUI` directory and see if `yourLanguageCode.po` file is available. If not, then open `install_waterfox_GUI.pot` file in `Poedit` and press button to create new translation, otherwise just open `yourLanguageCode.po` file in `Poedit` and start translating. You should do that similarly with files on `src/locales/common` and `src/locales/CLI` directories. When you're done with it, just send **Pull Request** with these files.
