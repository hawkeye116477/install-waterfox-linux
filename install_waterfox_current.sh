#!/bin/bash

# Installation and uninstallation script for Waterfox Current (based on Cyberfox's script)
# Version: 1.0.7

# Set current directory to script directory.
Dir=$(cd "$(dirname "$0")" && pwd)

# Enter current script directory.
cd "$Dir" || exit

# Count how many packages in the directory, If there is more then one the script may break or have undesired effect.
PackageCount=$(find . -name 'waterfox-current*.tar.bz2' | awk 'END { print NR }')

# Make package name editable in single place in the event of file naming change.
mapfile -t Package < <(find "$Dir" -type f -name 'waterfox-current*.tar.bz2' )

# Desktop shortcut path, Applications shortcut path, Waterfox install path.
# We need to know path to Desktop for not English operating systems

Desktop="$(xdg-user-dir DESKTOP)"
Applications=/usr/share/applications
InstallDirectory=$HOME/Apps

echo "Do you wish to install Waterfox Current now?"
select yn in "Install" "Uninstall" "Quit"; do
    case $yn in
    Install)

        # Check if more than 1 package exist.
        if [ "$PackageCount" -gt 1 ]; then
            echo "You have too many packages [$PackageCount] in this directory, I am unable to compute what package to install, Please remove the other packages so I no longer get confused!"
            notify-send "A error has occured"
            exit 0
        fi

        if [ -f "${Package[0]}" ]; then

            # Make directory if not already exist
            if ! [ -d "$InstallDirectory" ]; then
                echo "Making $InstallDirectory directory!"
                mkdir "$InstallDirectory"
            fi

            # Navigate into the apps directory
            echo "Entering $InstallDirectory directory"
            cd "$InstallDirectory" || exit

            # Unpack Waterfox Current into the apps directory, Remove existing waterfox-current folder.
            if [ -d "$InstallDirectory"/waterfox-current ]; then
                echo "Removing older install $InstallDirectory/waterfox-current"
                rm -rvf "$InstallDirectory"/waterfox-current
            fi

            echo "Unpacking ${Package[0]} into $InstallDirectory directory"
            mkdir -p "$InstallDirectory"/temp
            tar xjfv "${Package[0]}" -C "$InstallDirectory"/temp
            mv "$InstallDirectory"/temp/waterfox "$InstallDirectory"/waterfox-current
            rm -rf "$InstallDirectory"/temp

            # Install a wrapper
            echo "Creating desktop entry (Root priveleges are required)..."
            sudo install -Dm755 /dev/stdin "/usr/bin/waterfox-current" <<END
#!/bin/bash

if [ "$XDG_CURRENT_DESKTOP" == "KDE" ]; then
    export GTK_USE_PORTAL=1
fi

exec ~/Apps/waterfox-current/waterfox "\$@"

END

            # Create symlinks
            echo "Creating symlinks to icons (Root priveleges are required)..."
            sudo ln -sf "$InstallDirectory"/waterfox-current/browser/chrome/icons/default/default16.png /usr/share/icons/hicolor/16x16/apps/waterfox-current.png
            sudo ln -sf "$InstallDirectory"/waterfox-current/browser/chrome/icons/default/default32.png /usr/share/icons/hicolor/32x32/apps/waterfox-current.png
            sudo ln -sf "$InstallDirectory"/waterfox-current/browser/chrome/icons/default/default48.png /usr/share/icons/hicolor/48x48/apps/waterfox-current.png
            sudo ln -sf "$InstallDirectory"/waterfox-current/browser/chrome/icons/default/default64.png /usr/share/icons/hicolor/64x64/apps/waterfox-current.png
            sudo ln -sf "$InstallDirectory"/waterfox-current/browser/chrome/icons/default/default128.png /usr/share/icons/hicolor/128x128/apps/waterfox-current.png

            # Add vendor default settings
            echo "Adding useful settings for Waterfox Current"
            if [ -d "/usr/share/hunspell" ]; then
                dict_path="/usr/share/hunspell"
            else
                dict_path="/usr/share/myspell"
            fi

            install -Dm644 /dev/stdin "$InstallDirectory"/waterfox-current/browser/defaults/preferences/vendor.js<<EOF

// Disable default browser checking
pref("browser.shell.checkDefaultBrowser", false);

// Don't display the one-off addon selection dialog when
// upgrading from a version of Waterfox older than 8.0
pref("extensions.shownSelectionUI", true);

// Fall back to en-US search plugins if none exist for the current locale
pref("distribution.searchplugins.defaultLocale", "en-US");

// Use OS regional settings for date and time
pref("intl.regional_prefs.use_os_locales", true);

// Use system's dictionaries
pref("spellchecker.dictionary_path", "$dict_path");
EOF
            # Create start menu shortcut
            echo "Generating start menu shortcut..."
            sudo install -Dm644 /dev/stdin "$Applications/waterfox-current.desktop" <<EOF
[Desktop Entry]
Version=1.0
Name=Waterfox Current
Comment=Browse the World Wide Web
Comment[ar]=تصفح الشبكة العنكبوتية العالمية
Comment[ast]=Restola pela Rede
Comment[bn]=ইন্টারনেট ব্রাউজ করুন
Comment[ca]=Navegueu per la web
Comment[cs]=Prohlížení stránek World Wide Webu
Comment[da]=Surf på internettet
Comment[de]=Im Internet surfen
Comment[el]=Μπορείτε να περιηγηθείτε στο διαδίκτυο (Web)
Comment[es]=Navegue por la web
Comment[et]=Lehitse veebi
Comment[fa]=صفحات شبکه جهانی اینترنت را مرور نمایید
Comment[fi]=Selaa Internetin WWW-sivuja
Comment[fr]=Naviguer sur le Web
Comment[gl]=Navegar pola rede
Comment[he]=גלישה ברחבי האינטרנט
Comment[hr]=Pretražite web
Comment[hu]=A világháló böngészése
Comment[it]=Esplora il web
Comment[ja]=ウェブを閲覧します
Comment[ko]=웹을 돌아 다닙니다
Comment[ku]=Li torê bigere
Comment[lt]=Naršykite internete
Comment[nb]=Surf på nettet
Comment[nl]=Verken het internet
Comment[nn]=Surf på nettet
Comment[no]=Surf på nettet
Comment[pl]=Przeglądaj strony WWW
Comment[pt]=Explorar a Internet com o Waterfox
Comment[pt_BR]=Navegue na Internet
Comment[ro]=Navigați pe Internet
Comment[ru]=Доступ в Интернет
Comment[sk]=Prehliadanie internetu
Comment[sl]=Brskajte po spletu
Comment[sv]=Surfa på webben
Comment[tr]=İnternet'te Gezinin
Comment[ug]=دۇنيادىكى توربەتلەرنى كۆرگىلى بولىدۇ
Comment[uk]=Перегляд сторінок Інтернету
Comment[vi]=Để duyệt các trang web
Comment[zh_CN]=浏览互联网
Comment[zh_TW]=瀏覽網際網路
GenericName=Web Browser
GenericName[ar]=متصفح ويب
GenericName[ast]=Restolador Web
GenericName[bn]=ওয়েব ব্রাউজার
GenericName[ca]=Navegador web
GenericName[cs]=Webový prohlížeč
GenericName[da]=Webbrowser
GenericName[el]=Περιηγητής διαδικτύου
GenericName[es]=Navegador web
GenericName[et]=Veebibrauser
GenericName[fa]=مرورگر اینترنتی
GenericName[fi]=WWW-selain
GenericName[fr]=Navigateur Web
GenericName[gl]=Navegador Web
GenericName[he]=דפדפן אינטרנט
GenericName[hr]=Web preglednik
GenericName[hu]=Webböngésző
GenericName[it]=Browser web
GenericName[ja]=ウェブ・ブラウザ
GenericName[ko]=웹 브라우저
GenericName[ku]=Geroka torê
GenericName[lt]=Interneto naršyklė
GenericName[nb]=Nettleser
GenericName[nl]=Webbrowser
GenericName[nn]=Nettlesar
GenericName[no]=Nettleser
GenericName[pl]=Przeglądarka WWW
GenericName[pt]=Navegador web
GenericName[pt_BR]=Navegador Web
GenericName[ro]=Navigator Internet
GenericName[ru]=Веб-браузер
GenericName[sk]=Internetový prehliadač
GenericName[sl]=Spletni brskalnik
GenericName[sv]=Webbläsare
GenericName[tr]=Web Tarayıcı
GenericName[ug]=توركۆرگۈ
GenericName[uk]=Веб-браузер
GenericName[vi]=Trình duyệt Web
GenericName[zh_CN]=网络浏览器
GenericName[zh_TW]=網路瀏覽器
Keywords=Internet;WWW;Browser;Web;Explorer;
Keywords[ar]=انترنت;إنترنت;متصفح;ويب;وب;
Keywords[ast]=Internet;WWW;Restolador;Web;Esplorador;
Keywords[ca]=Internet;WWW;Navegador;Web;Explorador;Explorer;
Keywords[cs]=Internet;WWW;Prohlížeč;Web;Explorer;
Keywords[da]=Internet;Internettet;WWW;Browser;Browse;Web;Surf;Nettet;
Keywords[de]=Internet;WWW;Browser;Web;Explorer;Webseite;Site;surfen;online;browsen;
Keywords[el]=Internet;WWW;Browser;Web;Explorer;Διαδίκτυο;Περιηγητής;Waterfox;Φιρεφοχ;Ιντερνετ;
Keywords[es]=Explorador;Internet;WWW;
Keywords[fi]=Internet;WWW;Browser;Web;Explorer;selain;Internet-selain;internetselain;verkkoselain;netti;surffaa;
Keywords[fr]=Internet;WWW;Browser;Web;Explorer;Fureteur;Surfer;Navigateur;
Keywords[he]=דפדפן;אינטרנט;רשת;אתרים;אתר;פיירפוקס;מוזילה;
Keywords[hr]=Internet;WWW;preglednik;Web;
Keywords[hu]=Internet;WWW;Böngésző;Web;Háló;Net;Explorer;
Keywords[it]=Internet;WWW;Browser;Web;Navigatore;
Keywords[is]=Internet;WWW;Vafri;Vefur;Netvafri;Flakk;
Keywords[ja]=Internet;WWW;Web;インターネット;ブラウザ;ウェブ;エクスプローラ;
Keywords[nb]=Internett;WWW;Nettleser;Explorer;Web;Browser;Nettside;
Keywords[nl]=Internet;WWW;Browser;Web;Explorer;Verkenner;Website;Surfen;Online;
Keywords[pl]=Internet;WWW;Przeglądarka;Sieć;Surfowanie;Strona internetowa;Strona;Przeglądanie;
Keywords[pt]=Internet;WWW;Browser;Web;Explorador;Navegador;
Keywords[pt_BR]=Internet;WWW;Browser;Web;Explorador;Navegador;
Keywords[ru]=Internet;WWW;Browser;Web;Explorer;интернет;браузер;веб;файрфокс;огнелис;
Keywords[sk]=Internet;WWW;Prehliadač;Web;Explorer;
Keywords[sl]=Internet;WWW;Browser;Web;Explorer;Brskalnik;Splet;
Keywords[tr]=İnternet;WWW;Tarayıcı;Web;Gezgin;Web sitesi;Site;sörf;çevrimiçi;tara;
Keywords[uk]=Internet;WWW;Browser;Web;Explorer;Інтернет;мережа;переглядач;оглядач;браузер;веб;файрфокс;вогнелис;перегляд;
Keywords[vi]=Internet;WWW;Browser;Web;Explorer;Trình duyệt;Trang web;
Keywords[zh_CN]=Internet;WWW;Browser;Web;Explorer;网页;浏览;上网;水狐;Waterfox;wf;互联网;网站;
Keywords[zh_TW]=Internet;WWW;Browser;Web;Explorer;網際網路;網路;瀏覽器;上網;網頁;水狐;
Exec=waterfox-current %u
Terminal=false
X-MuiltpleArgs=false
Type=Application
Icon=waterfox-current
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ftp;x-scheme-handler/chrome;video/webm;application/x-xpinstall;
StartupNotify=true
Actions=NewWindow;NewPrivateWindow;

[Desktop Action NewWindow]
Name=Open a New Window
Name[ar]=افتح نافذة جديدة
Name[ast]=Abrir una ventana nueva
Name[bn]=Abrir una ventana nueva
Name[ca]=Obre una finestra nova
Name[cs]=Otevřít nové okno
Name[da]=Åbn et nyt vindue
Name[de]=Ein neues Fenster öffnen
Name[el]=Άνοιγμα νέου παραθύρου
Name[es]=Abrir una ventana nueva
Name[fi]=Avaa uusi ikkuna
Name[fr]=Ouvrir une nouvelle fenêtre
Name[gl]=Abrir unha nova xanela
Name[he]=פתיחת חלון חדש
Name[hr]=Otvori novi prozor
Name[hu]=Új ablak nyitása
Name[it]=Apri una nuova finestra
Name[ja]=新しいウィンドウを開く
Name[ko]=새 창 열기
Name[ku]=Paceyeke nû veke
Name[lt]=Atverti naują langą
Name[nb]=Åpne et nytt vindu
Name[nl]=Nieuw venster openen
Name[pl]=Otwórz nowe okno
Name[pt]=Abrir uma nova janela
Name[pt_BR]=Abrir nova janela
Name[ro]=Deschide o fereastră nouă
Name[ru]=Новое окно
Name[sk]=Otvoriť nové okno
Name[sl]=Odpri novo okno
Name[sv]=Öppna ett nytt fönster
Name[tr]=Yeni pencere aç
Name[ug]=يېڭى كۆزنەك ئېچىش
Name[uk]=Відкрити нове вікно
Name[vi]=Mở cửa sổ mới
Name[zh_CN]=新建窗口
Name[zh_TW]=開啟新視窗
Exec=waterfox-current -new-window

[Desktop Action NewPrivateWindow]
Name=Open a New Private Window
Name[ar]=افتح نافذة جديدة للتصفح الخاص
Name[ca]=Obre una finestra nova en mode d'incògnit
Name[de]=Ein neues privates Fenster öffnen
Name[es]=Abrir una ventana privada nueva
Name[fi]=Avaa uusi yksityinen ikkuna
Name[fr]=Ouvrir une nouvelle fenêtre de navigation privée
Name[he]=פתיחת חלון גלישה פרטית חדש
Name[hu]=Új privát ablak nyitása
Name[it]=Apri una nuova finestra anonima
Name[nb]=Åpne et nytt privat vindu
Name[pl]=Otwórz nowe okno prywatne
Name[pt]=Abrir uma nova janela privada
Name[ru]=Новое приватное окно
Name[sl]=Odpri novo okno zasebnega brskanja
Name[tr]=Yeni bir pencere aç
Name[uk]=Відкрити нове вікно у потайливому режимі
Name[zh_TW]=開啟新隱私瀏覽視窗
Exec=waterfox-current -private-window
EOF

            # Install optional desktop shortcut
            echo "Do you wish to add a desktop shortcut (Root priveleges are required)?"
            select yn in "Yes" "No"; do
                case $yn in
                Yes)
                    echo "Generating desktop shortcut..."
                    sudo ln -sf $Applications/waterfox-current.desktop "$Desktop"/waterfox-current.desktop
                    break
                    ;;
                No) break ;;
                esac
            done
            echo "Waterfox Current is now ready for use!"
            notify-send "Installation Complete!"
        else
            echo "You must place this script next to the 'waterfox-current' tar.bz2 package."
        fi
        break
        ;;
    Uninstall)

        # Navigate into the apps directory
        echo "Entering $InstallDirectory directory"
        cd "$InstallDirectory" || exit

        # Remove waterfox installation folder
        if [ -d "$InstallDirectory"/waterfox-current ]; then
            echo "Removing older install $InstallDirectory/waterfox-current"
            rm -rvf "$InstallDirectory"/waterfox-current
        fi

        # Remove waterfox desktop icon if exists.
        if [ -f "$Desktop"/waterfox-current.desktop ]; then
            rm -vrf "$Desktop"/waterfox-current.desktop
        fi

        # Remove menu icon if exists.
        # Requires admin permissions to write the file to /usr/share/applications directory.
        # This should only prompt if the user installed it, Meaning if the check for the file returns true.
        if [ -f $Applications/waterfox-current.desktop ]; then
            sudo rm -vrf $Applications/waterfox-current.desktop
        fi

        # Remove wrapper
        if [ -f /usr/bin/waterfox-current ]; then
            sudo rm -vrf /usr/bin/waterfox-current
        fi

        # Remove symlinks
        if [ -L /usr/share/pixmaps/waterfox-current.png ]; then
            sudo rm -vrf /usr/share/pixmaps/waterfox-current.png
        fi

        if [ -L /usr/share/icons/hicolor/16x16/apps/waterfox-current.png ]; then
            sudo rm -vrf /usr/share/icons/hicolor/16x16/apps/waterfox-current.png
        fi

        if [ -L /usr/share/icons/hicolor/22x22/apps/waterfox-current.png ]; then
            sudo rm -vrf /usr/share/icons/hicolor/22x22/apps/waterfox-current.png
        fi

        if [ -L /usr/share/icons/hicolor/24x24/apps/waterfox-current.png ]; then
            sudo rm -vrf /usr/share/icons/hicolor/24x24/apps/waterfox-current.png
        fi

        if [ -L /usr/share/icons/hicolor/32x32/apps/waterfox-current.png ]; then
            sudo rm -vrf /usr/share/icons/hicolor/32x32/apps/waterfox-current.png
        fi

        if [ -L /usr/share/icons/hicolor/48x48/apps/waterfox-current.png ]; then
            sudo rm -vrf /usr/share/icons/hicolor/48x48/apps/waterfox-current.png
        fi

        if [ -L /usr/share/icons/hicolor/64x64/apps/waterfox-current.png ]; then
            sudo rm -vrf /usr/share/icons/hicolor/64x64/apps/waterfox-current.png
        fi

        if [ -L /usr/share/icons/hicolor/256x256/apps/waterfox-current.png ]; then
            sudo rm -vrf /usr/share/icons/hicolor/256x256/apps/waterfox-current.png
        fi

        if [ -L /usr/share/icons/hicolor/128x128/apps/waterfox-current.png ]; then
            sudo rm -vrf /usr/share/icons/hicolor/128x128/apps/waterfox-current.png
        fi

        # Remove ~/Apps if is empty
        if [ ! "$(ls -A "$InstallDirectory")" ]; then
            rmdir "$InstallDirectory"
        fi

        notify-send "Uninstall Complete"
        break
        ;;
    "Quit")
        echo "If I’m not back in five minutes, just wait longer."
        exit 0
        break
        ;;
    esac
done
