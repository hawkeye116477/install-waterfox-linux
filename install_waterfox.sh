#!/bin/bash

# Installation and uninstallation script for Waterfox (based on Cyberfox's script)
# Version: 1.3.5

# Script directory
Dir=$(cd "$(dirname "$0")" && pwd)

# Desktop shortcut path, Applications shortcut path, Waterfox install path, Config path.
ConfDir=${XDG_CONFIG_HOME:-$HOME/.config}/install_waterfox
ConfFile="$ConfDir"/settings.conf
Desktop="$(xdg-user-dir DESKTOP)"
Applications=/usr/share/applications
InstallDirectory=$HOME/Apps

# Read saved installation path
if [ -f "$ConfFile" ]; then
    InstallDirectory=$(grep -oP -m 1 'InstallPath=\K.*' "$ConfFile")
fi

# Parse arguments
usage() {
    echo "Usage: $0  [ options ... ]"
    echo ""
    echo "  -v or --version              : Print script version"
    echo "  -sp=<path> or --spath=<path> : Set path to directory of installable package(s)"
    echo "  -ip=<path> or --ipath=<path> : Set installation path (folder with package name will be here)"
    echo "  -h                           : Print this screen"
    echo ""
}

for i in "$@"; do
    case $i in
    -sp=* | --spath=*)
        Dir="${i#*=}"
        ;;
    -v | --version)
        printf "%-10s %-10s\n" "Script version: " "$(awk -F': ' '/^# Version:/ {print $2; exit}' "$0")"
        exit 0
        ;;
    -ip=* | --ipath=*)
        InstallDirectory="${i#*=}"
        ;;
    -h | --help)
        usage
        exit 0
        ;;
    esac
done

# Enter current script directory.
cd "$Dir" || exit

# Detect installable packages
echo "Detecting installable packages..."
mapfile -t Packages < <(find "$Dir" -type f -regextype posix-extended -regex ".*waterfox-(classic|current|G3|g3|G4|g4).*(tar\.bz2|AppImage)")

if [ "${#Packages[@]}" ]; then
    PackageTypes=()

    if [[ ${Packages[*]} =~ "waterfox-classic" ]]; then
        PackageTypes+=("Classic")
    fi

    if [[ ${Packages[*]} =~ "waterfox-current" ]]; then
        PackageTypes+=("Current")
    fi

    if [[ ${Packages[*]} =~ waterfox-(G3|g3) ]]; then
        PackageTypes+=("G3")
    fi

    if [[ ${Packages[*]} =~ waterfox-(G4|g4) ]]; then
        PackageTypes+=("G4")
    fi
fi

if [[ "${PackageTypes[*]}" ]]; then
    echo "Which package are you interested in?"
    select chosenPackageType in "${PackageTypes[@]}" "None"; do
        case $chosenPackageType in
        "None")
            exit 0
            break
            ;;
        *)
            break
            ;;
        esac
    done
else
    echo "No packages detected. Please place this script next to the tarball/AppImage packages or rerun it with flag -sp=<path>."
    exit 0
fi

echo "What do you want to do with Waterfox $chosenPackageType now?"

lowerChosenPackageType=$(echo "$chosenPackageType" | tr "[:upper:]" "[:lower:]")

if [[ "$lowerChosenPackageType" == "g3" ]]; then
    packageTypeName="(G3|g3)"
elif [[ "$lowerChosenPackageType" == "g4" ]]; then
    packageTypeName="(G4|g4)"
else
    packageTypeName=$(echo "$chosenPackageType" | tr "[:upper:]" "[:lower:]")
fi

chosenPackages=()
for package in "${Packages[@]}"; do
    if [[ "$(basename -- "$package")" =~ ^waterfox-"$packageTypeName".*(tar\.bz2|AppImage) ]]; then
        chosenPackages+=("$package")
    fi
done
Packages=("${chosenPackages[@]}")

# Count how many packages in the directory
PackageCount=${#Packages[@]}

select yn in "Install" "Uninstall" "Quit"; do
    case $yn in
    Install)

        # Check if more than 1 package exist.
        if [ "$PackageCount" -gt 1 ]; then
            echo "Which package do you want to install?"
            select Package in "${Packages[@]}" "None"; do
                case $Package in
                "None")
                    exit 0
                    break
                    ;;
                *)
                    mapfile -t Packages < <(echo "$Package")
                    break
                    ;;
                esac
            done
        fi

        # Make directory if not already exist
        if ! [ -d "$InstallDirectory" ]; then
            echo "Making $InstallDirectory directory!"
            mkdir "$InstallDirectory"
        fi

        # Navigate into the install directory
        echo "Entering $InstallDirectory directory"
        cd "$InstallDirectory" || exit

        if [ ! -f "${Packages[0]}" ]; then
            echo "No installable packages found. Maybe you wanted to uninstall Waterfox $chosenPackageType."
            exit 0
        fi

        # Remove existing waterfox folder.
        if [ -d "$InstallDirectory"/waterfox-"$lowerChosenPackageType" ]; then
            echo "Removing older installed version..."
            rm -rvf "$InstallDirectory"/waterfox-"$lowerChosenPackageType"
        fi

        # Unpack waterfox into the install directory
        echo "Unpacking ${Packages[0]} into $InstallDirectory directory"
        mkdir -p "$InstallDirectory"/temp
        if [[ "${Packages[0]}" =~ "AppImage" ]]; then
            chmod +x "${Packages[0]}"
            cd "$InstallDirectory"/temp || exit
            "${Packages[0]}" --appimage-extract
            mv "$InstallDirectory"/temp/squashfs-root/usr/bin/waterfox-"$lowerChosenPackageType" "$InstallDirectory"/temp/squashfs-root/usr/bin/waterfox
            mv "$InstallDirectory"/temp/squashfs-root/usr/bin/* "$InstallDirectory"/temp
            rm -rf "$InstallDirectory"/temp/squashfs-root/
            mkdir -p "$InstallDirectory"/waterfox-"$lowerChosenPackageType"
        else
            tar xjfv "${Packages[0]}" -C "$InstallDirectory"/temp
        fi

        mv "$InstallDirectory"/temp/* "$InstallDirectory"/waterfox-"$lowerChosenPackageType"
        rm -rf "$InstallDirectory"/temp

        # Install a wrapper to avoid confusion about binary path
        echo "Creating desktop entry (Root priveleges are required)..."
        sudo install -Dm755 /dev/stdin "/usr/bin/waterfox-$lowerChosenPackageType" <<END
#!/bin/bash
if [ "$XDG_CURRENT_DESKTOP" == "KDE" ]; then
    export GTK_USE_PORTAL=1
fi
exec $InstallDirectory/waterfox-$lowerChosenPackageType/waterfox "\$@"
END

        # Create symlinks
        echo "Creating symlinks to icons..."
        sudo ln -sf "$InstallDirectory"/waterfox-"$lowerChosenPackageType"/browser/chrome/icons/default/default16.png /usr/share/icons/hicolor/16x16/apps/waterfox-"$lowerChosenPackageType".png
        sudo ln -sf "$InstallDirectory"/waterfox-"$lowerChosenPackageType"/browser/chrome/icons/default/default22.png /usr/share/icons/hicolor/22x22/apps/waterfox-"$lowerChosenPackageType".png
        sudo ln -sf "$InstallDirectory"/waterfox-"$lowerChosenPackageType"/browser/chrome/icons/default/default24.png /usr/share/icons/hicolor/24x24/apps/waterfox-"$lowerChosenPackageType".png
        sudo ln -sf "$InstallDirectory"/waterfox-"$lowerChosenPackageType"/browser/chrome/icons/default/default32.png /usr/share/icons/hicolor/32x32/apps/waterfox-"$lowerChosenPackageType".png
        sudo ln -sf "$InstallDirectory"/waterfox-"$lowerChosenPackageType"/browser/chrome/icons/default/default48.png /usr/share/icons/hicolor/48x48/apps/waterfox-"$lowerChosenPackageType".png
        sudo ln -sf "$InstallDirectory"/waterfox-"$lowerChosenPackageType"/browser/chrome/icons/default/default128.png /usr/share/icons/hicolor/128x128/apps/waterfox-"$lowerChosenPackageType".png
        sudo ln -sf "$InstallDirectory"/waterfox-"$lowerChosenPackageType"/browser/chrome/icons/default/default256.png /usr/share/icons/hicolor/256x256/apps/waterfox-"$lowerChosenPackageType".png

        # Add vendor default settings
        echo "Do you wish to use system's dictionaries for Waterfox $chosenPackageType?"
        select yn in "Yes" "No"; do
            case $yn in
            Yes)
                echo "Adding path to system's dictionaries..."
                if [ -d /usr/share/hunspell ]; then
                    dict_path="/usr/share/hunspell"
                else
                    dict_path="/usr/share/myspell"
                fi

                install -Dm644 /dev/stdin "$InstallDirectory"/waterfox-"$lowerChosenPackageType"/browser/defaults/preferences/spellcheck.js <<END
pref("spellchecker.dictionary_path", "$dict_path");
END
                rm -rf "$InstallDirectory"/waterfox-"$lowerChosenPackageType"/dictionaries
                break
                ;;
            No) break ;;
            esac
        done

        # Create start menu shortcut
        echo "Generating start menu shortcut..."
        sudo install -Dm644 /dev/stdin "$Applications/waterfox-$lowerChosenPackageType.desktop" <<EOF
[Desktop Entry]
Version=1.0
Name=Waterfox $chosenPackageType
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
Exec=waterfox-$lowerChosenPackageType %u
Terminal=false
X-MuiltpleArgs=false
Type=Application
Icon=waterfox-$lowerChosenPackageType
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ftp;x-scheme-handler/chrome;video/webm;application/x-xpinstall;
StartupNotify=true
Actions=NewWindow;NewPrivateWindow;ProfileManagerWindow;

[Desktop Action NewWindow]
Name=Open a New Window
Name[ach]=Dirica manyen
Name[af]=Nuwe venster
Name[an]=Nueva finestra
Name[ar]=نافذة جديدة
Name[as]=নতুন উইন্ডো
Name[ast]=Ventana nueva
Name[az]=Yeni Pəncərə
Name[be]=Новае акно
Name[bg]=Нов прозорец
Name[bn_BD]=নতুন উইন্ডো (N)
Name[bn_IN]=নতুন উইন্ডো
Name[br]=Prenestr nevez
Name[brx]=गोदान उइन्ड'(N)
Name[bs]=Novi prozor
Name[ca]=Finestra nova
Name[cak]=K'ak'a' tzuwäch
Name[cs]=Nové okno
Name[cy]=Ffenestr Newydd
Name[da]=Nyt vindue
Name[de]=Neues Fenster
Name[dsb]=Nowe wokno
Name[el]=Νέο παράθυρο
Name[en_GB]=New Window
Name[en_US]=New Window
Name[en_ZA]=New Window
Name[eo]=Nova fenestro
Name[es_AR]=Nueva ventana
Name[es_CL]=Nueva ventana
Name[es_ES]=Nueva ventana
Name[es_MX]=Nueva ventana
Name[et]=Uus aken
Name[eu]=Leiho berria
Name[fa]=پنجره جدید‌
Name[ff]=Henorde Hesere
Name[fi]=Uusi ikkuna
Name[fr]=Nouvelle fenêtre
Name[fy_NL]=Nij finster
Name[ga_IE]=Fuinneog Nua
Name[gd]=Uinneag ùr
Name[gl]=Nova xanela
Name[gn]=Ovetã pyahu
Name[gu_IN]=નવી વિન્ડો
Name[he]=חלון חדש
Name[hi_IN]=नया विंडो
Name[hr]=Novi prozor
Name[hsb]=Nowe wokno
Name[hu]=Új ablak
Name[hy_AM]=Նոր Պատուհան
Name[id]=Jendela Baru
Name[is]=Nýr gluggi
Name[it]=Nuova finestra
Name[ja]=新しいウィンドウ
Name[ja_JP-mac]=新規ウインドウ
Name[ka]=ახალი ფანჯარა
Name[kk]=Жаңа терезе
Name[km]=បង្អួច​​​ថ្មី
Name[kn]=ಹೊಸ ಕಿಟಕಿ
Name[ko]=새 창
Name[kok]=नवें जनेल
Name[ks]=نئئ وِنڈو
Name[lij]=Neuvo barcon
Name[lo]=ຫນ້າຕ່າງໃຫມ່
Name[lt]=Naujas langas
Name[ltg]=Jauns lūgs
Name[lv]=Jauns logs
Name[mai]=नव विंडो
Name[mk]=Нов прозорец
Name[ml]=പുതിയ ജാലകം
Name[mr]=नवीन पटल
Name[ms]=Tetingkap Baru
Name[my]=ဝင်းဒိုးအသစ်
Name[nb_NO]=Nytt vindu
Name[ne_NP]=नयाँ सञ्झ्याल
Name[nl]=Nieuw venster
Name[nn_NO]=Nytt vindauge
Name[or]=ନୂତନ ୱିଣ୍ଡୋ
Name[pa_IN]=ਨਵੀਂ ਵਿੰਡੋ
Name[pl]=Nowe okno
Name[pt_BR]=Nova janela
Name[pt_PT]=Nova janela
Name[rm]=Nova fanestra
Name[ro]=Fereastră nouă
Name[ru]=Новое окно
Name[sat]=नावा विंडो (N)
Name[si]=නව කවුළුවක්
Name[sk]=Nové okno
Name[sl]=Novo okno
Name[son]=Zanfun taaga
Name[sq]=Dritare e Re
Name[sr]=Нови прозор
Name[sv_SE]=Nytt fönster
Name[ta]=புதிய சாளரம்
Name[te]=కొత్త విండో
Name[th]=หน้าต่างใหม่
Name[tr]=Yeni pencere
Name[tsz]=Eraatarakua jimpani
Name[uk]=Нове вікно
Name[ur]=نیا دریچہ
Name[uz]=Yangi oyna
Name[vi]=Cửa sổ mới
Name[wo]=Palanteer bu bees
Name[xh]=Ifestile entsha
Name[zh_CN]=新建窗口
Name[zh_TW]=開新視窗
Exec=waterfox-$lowerChosenPackageType --new-window

[Desktop Action NewPrivateWindow]
Name=Open a New Private Window
Name[ach]=Dirica manyen me mung
Name[af]=Nuwe privaatvenster
Name[an]=Nueva finestra privada
Name[ar]=نافذة خاصة جديدة
Name[as]=নতুন ব্যক্তিগত উইন্ডো
Name[ast]=Ventana privada nueva
Name[az]=Yeni Məxfi Pəncərə
Name[be]=Новае акно адасаблення
Name[bg]=Нов прозорец за поверително сърфиране
Name[bn_BD]=নতুন ব্যক্তিগত উইন্ডো
Name[bn_IN]=নতুন ব্যক্তিগত উইন্ডো
Name[br]=Prenestr merdeiñ prevez nevez
Name[brx]=गोदान प्राइभेट उइन्ड'
Name[bs]=Novi privatni prozor
Name[ca]=Finestra privada nova
Name[cak]=K'ak'a' ichinan tzuwäch
Name[cs]=Nové anonymní okno
Name[cy]=Ffenestr Breifat Newydd
Name[da]=Nyt privat vindue
Name[de]=Neues privates Fenster
Name[dsb]=Nowe priwatne wokno
Name[el]=Νέο παράθυρο ιδιωτικής περιήγησης
Name[en_GB]=New Private Window
Name[en_US]=New Private Window
Name[en_ZA]=New Private Window
Name[eo]=Nova privata fenestro
Name[es_AR]=Nueva ventana privada
Name[es_CL]=Nueva ventana privada
Name[es_ES]=Nueva ventana privada
Name[es_MX]=Nueva ventana privada
Name[et]=Uus privaatne aken
Name[eu]=Leiho pribatu berria
Name[fa]=پنجره ناشناس جدید
Name[ff]=Henorde Suturo Hesere
Name[fi]=Uusi yksityinen ikkuna
Name[fr]=Nouvelle fenêtre de navigation privée
Name[fy_NL]=Nij priveefinster
Name[ga_IE]=Fuinneog Nua Phríobháideach
Name[gd]=Uinneag phrìobhaideach ùr
Name[gl]=Nova xanela privada
Name[gn]=Ovetã ñemi pyahu
Name[gu_IN]=નવી ખાનગી વિન્ડો
Name[he]=חלון פרטי חדש
Name[hi_IN]=नयी निजी विंडो
Name[hr]=Novi privatni prozor
Name[hsb]=Nowe priwatne wokno
Name[hu]=Új privát ablak
Name[hy_AM]=Սկսել Գաղտնի դիտարկում
Name[id]=Jendela Mode Pribadi Baru
Name[is]=Nýr huliðsgluggi
Name[it]=Nuova finestra anonima
Name[ja]=新しいプライベートウィンドウ
Name[ja_JP-mac]=新規プライベートウインドウ
Name[ka]=ახალი პირადი ფანჯარა
Name[kk]=Жаңа жекелік терезе
Name[km]=បង្អួច​ឯកជន​ថ្មី
Name[kn]=ಹೊಸ ಖಾಸಗಿ ಕಿಟಕಿ
Name[ko]=새 사생활 보호 모드
Name[kok]=नवो खाजगी विंडो
Name[ks]=نْو پرایوٹ وینڈو&amp;
Name[lij]=Neuvo barcon privou
Name[lo]=ເປີດຫນ້າຕ່າງສວນຕົວຂື້ນມາໃຫມ່
Name[lt]=Naujas privataus naršymo langas
Name[ltg]=Jauns privatais lūgs
Name[lv]=Jauns privātais logs
Name[mai]=नया निज विंडो (W)
Name[mk]=Нов приватен прозорец
Name[ml]=പുതിയ സ്വകാര്യ ജാലകം
Name[mr]=नवीन वैयक्तिक पटल
Name[ms]=Tetingkap Persendirian Baharu
Name[my]=New Private Window
Name[nb_NO]=Nytt privat vindu
Name[ne_NP]=नयाँ निजी सञ्झ्याल
Name[nl]=Nieuw privévenster
Name[nn_NO]=Nytt privat vindauge
Name[or]=ନୂତନ ବ୍ୟକ୍ତିଗତ ୱିଣ୍ଡୋ
Name[pa_IN]=ਨਵੀਂ ਪ੍ਰਾਈਵੇਟ ਵਿੰਡੋ
Name[pl]=Nowe okno prywatne
Name[pt_BR]=Nova janela privativa
Name[pt_PT]=Nova janela privada
Name[rm]=Nova fanestra privata
Name[ro]=Fereastră privată nouă
Name[ru]=Новое приватное окно
Name[sat]=नावा निजेराक् विंडो (W )
Name[si]=නව පුද්ගලික කවුළුව (W)
Name[sk]=Nové okno v režime Súkromné prehliadanie
Name[sl]=Novo zasebno okno
Name[son]=Sutura zanfun taaga
Name[sq]=Dritare e Re Private
Name[sr]=Нови приватан прозор
Name[sv_SE]=Nytt privat fönster
Name[ta]=புதிய தனிப்பட்ட சாளரம்
Name[te]=కొత్త ఆంతరంగిక విండో
Name[th]=หน้าต่างส่วนตัวใหม่
Name[tr]=Yeni gizli pencere
Name[tsz]=Juchiiti eraatarakua jimpani
Name[uk]=Приватне вікно
Name[ur]=نیا نجی دریچہ
Name[uz]=Yangi maxfiy oyna
Name[vi]=Cửa sổ riêng tư mới
Name[wo]=Panlanteeru biir bu bees
Name[xh]=Ifestile yangasese entsha
Name[zh_CN]=新建隐私浏览窗口
Name[zh_TW]=新增隱私視窗
Exec=waterfox-$lowerChosenPackageType --private-window

[Desktop Action ProfileManagerWindow]
Name=Open the Profile Manager
Name[cs]=Správa profilů
Name[en_GB]=Profile Manager
Name[en_US]=Profile Manager
Name[pl]=Menedżer Profili
Exec=waterfox-$lowerChosenPackageType --ProfileManager
EOF

        # Refresh icons cache
        echo "Refreshing icons cache..."
        sudo gtk-update-icon-cache -q -t -f /usr/share/icons/hicolor

        # Install optional desktop shortcut
        echo "Do you wish to add a desktop shortcut?"
        select yn in "Yes" "No"; do
            case $yn in
            Yes)
                echo "Generating desktop shortcut..."
                sudo ln -sf $Applications/waterfox-"$lowerChosenPackageType".desktop "$Desktop"/waterfox-"$lowerChosenPackageType".desktop
                break
                ;;
            No) break ;;
            esac
        done

        # Remove installed archive file
        echo "Do you wish to remove installed tarball/AppImage package?"
        select yn in "Yes" "No"; do
            case $yn in
            Yes)
                echo "Removing package..."
                rm -rf "${Packages[0]}"
                break
                ;;
            No) break ;;
            esac
        done

        # Save install path
        mkdir -p "$ConfDir"
        install -Dm644 /dev/stdin "$ConfDir/settings.conf" <<END
InstallPath=$InstallDirectory
END

        # Finish
        echo "Waterfox $chosenPackageType is now ready for use!"
        notify-send "Waterfox $chosenPackageType has been installed in $InstallDirectory!"
        break
        ;;
    Uninstall)
        if [ ! -d "$InstallDirectory/waterfox-$lowerChosenPackageType" ]; then
            echo "Waterfox $chosenPackageType isn't installed in $InstallDirectory."
            exit 0
        fi

        # Navigate into the install directory
        echo "Entering $InstallDirectory directory"
        cd "$InstallDirectory" || exit

        # Remove waterfox installation folder
        if [ -d "$InstallDirectory"/waterfox-"$lowerChosenPackageType" ]; then
            echo "Removing older install $InstallDirectory/waterfox-$lowerChosenPackageType"
            rm -rvf "$InstallDirectory"/waterfox-"$lowerChosenPackageType"
        fi

        # Remove waterfox desktop icon if exists.
        if [ -f "$Desktop"/waterfox-"$lowerChosenPackageType".desktop ]; then
            rm -vrf "$Desktop"/waterfox-"$lowerChosenPackageType".desktop
        fi

        # Remove menu icon if exists.
        # Requires admin permissions to write the file to /usr/share/applications directory.
        # This should only prompt if the user installed it, Meaning if the check for the file returns true.
        echo "Root priveleges are required to remove some files."
        if [ -f $Applications/waterfox-"$lowerChosenPackageType".desktop ]; then
            sudo rm -vrf $Applications/waterfox-"$lowerChosenPackageType".desktop
        fi

        # Remove wrapper
        if [ -f /usr/bin/waterfox-"$lowerChosenPackageType" ]; then
            sudo rm -vrf /usr/bin/waterfox-"$lowerChosenPackageType"
        fi

        # Remove symlinks
        if [ -L /usr/share/pixmaps/waterfox-"$lowerChosenPackageType".png ]; then
            sudo rm -vrf /usr/share/pixmaps/waterfox-"$lowerChosenPackageType".png
        fi

        if [ -L /usr/share/icons/hicolor/16x16/apps/waterfox-"$lowerChosenPackageType".png ]; then
            sudo rm -vrf /usr/share/icons/hicolor/16x16/apps/waterfox-"$lowerChosenPackageType".png
        fi

        if [ -L /usr/share/icons/hicolor/22x22/apps/waterfox-"$lowerChosenPackageType".png ]; then
            sudo rm -vrf /usr/share/icons/hicolor/22x22/apps/waterfox-"$lowerChosenPackageType".png
        fi

        if [ -L /usr/share/icons/hicolor/24x24/apps/waterfox-"$lowerChosenPackageType".png ]; then
            sudo rm -vrf /usr/share/icons/hicolor/24x24/apps/waterfox-"$lowerChosenPackageType".png
        fi

        if [ -L /usr/share/icons/hicolor/32x32/apps/waterfox-"$lowerChosenPackageType".png ]; then
            sudo rm -vrf /usr/share/icons/hicolor/32x32/apps/waterfox-"$lowerChosenPackageType".png
        fi

        if [ -L /usr/share/icons/hicolor/48x48/apps/waterfox-"$lowerChosenPackageType".png ]; then
            sudo rm -vrf /usr/share/icons/hicolor/48x48/apps/waterfox-"$lowerChosenPackageType".png
        fi

        if [ -L /usr/share/icons/hicolor/256x256/apps/waterfox-"$lowerChosenPackageType".png ]; then
            sudo rm -vrf /usr/share/icons/hicolor/256x256/apps/waterfox-"$lowerChosenPackageType".png
        fi

        if [ -L /usr/share/icons/hicolor/128x128/apps/waterfox-"$lowerChosenPackageType".png ]; then
            sudo rm -vrf /usr/share/icons/hicolor/128x128/apps/waterfox-"$lowerChosenPackageType".png
        fi

        # Remove install directory if is empty
        if [ ! "$(ls -A "$InstallDirectory")" ]; then
            rmdir "$InstallDirectory"
            rm -rf "$ConfDir"
        fi
        notify-send "Uninstall of Waterfox $chosenPackageType is complete!"
        break
        ;;
    "Quit")
        echo "If I'm not back in five minutes, just wait longer."
        exit 0
        break
        ;;
    esac
done
