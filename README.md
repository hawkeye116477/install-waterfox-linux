# install-waterfox-linux
Installs and uninstalls official and AppImage Waterfox packages on every 64-bit Linux distribution.


**Tip: AppImage package doesn't require installing. It can be just launched by setting as executable and clicking into it, but when it's unpacked it may run faster and you can edit some files if you want.**

# How to use it?
## Available options
You can launch script with flag `-h` to get list of available options.

## Installing Waterfox
If you have .tar.bz2 or AppImage file on same directy as script, then just run it, choose **Install** option.
Otherwise you can move script to another directory or rerun it with flag `-sp=<path>`, where `<path>` is place where you have your tarballs or AppImages.

Script should ask you few questions about shortcuts, symlinks and then install Waterfox on **$HOME/Apps** (you can change installation directory with flag `-ip=<path>`, where `<path>` is place where will be folder with package name). It should display you message when installation completed.

## Uninstalling Waterfox
Just run this script and choose **Uninstall** option.
By default it looks for programs in last saved path. If you have apps in multiple paths, then you need to relauch it with flag `-ip=<path>`, where `<path>` is place where is folder with package name.

Script should display you message when uninstallation completed.
