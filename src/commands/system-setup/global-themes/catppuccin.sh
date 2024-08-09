#!/bin/sh
set_qt(){
printf "${YELLOW}Configuring qt6ct...${RC}\n"
mkdir -p "$HOME/.config/qt6ct/"
wget -O "${HOME}"/.config/qt6ct/"$1".conf https://raw.githubusercontent.com/catppuccin/qt5ct/main/themes/Catppuccin-"$1".conf

cat <<EOF > "$HOME/.config/qt6ct/qt6ct.conf"
[Appearance]
style=kvantum
color_scheme_path="$HOME/.config/qt6ct/$1.conf"
icon_theme=breeze
EOF
printf "${YELLOW}Configured qt6ct...${RC}\n"
}
set_k(){
 printf "${YELLOW}Configuring kvantum...${RC}\n"
 wget -P "$HOME/.config/Kvantum/catppuccin-$1-$2/"  https://raw.githubusercontent.com/catppuccin/Kvantum/main/themes/catppuccin-"$1"-"$2"/catppuccin-"$1"-"$2".svg
 wget -P "$HOME/.config/Kvantum/catppuccin-$1-$2/"  https://raw.githubusercontent.com/catppuccin/Kvantum/main/themes/catppuccin-"$1"-"$2"/catppuccin-"$1"-"$2".kvconfig
cat <<EOF > "$HOME/.config/Kvantum/kvantum.kvconfig"
[General]
theme=catppuccin-$1-$2
EOF
printf "${YELLOW}Configured kvantum...${RC}\n"
echo "Theme set to catppuccin-$1-$2."
}
set_accent(){
     cat <<EOF
Choose an accent -
    1. Rosewater
    2. Flamingo
    3. Pink
    4. Mauve
    5. Red
    6. Maroon
    7. Peach
    8. Yellow
    9. Green
    10. Teal
    11. Sky
    12. Sapphire
    13. Blue
    14. Lavender
EOF
    while true; do
    read -rp "Enter your choice (the number): " accent
   case "$accent" in
    1)
        ACCENTNAME="rosewater"
        ;;
    2)
        ACCENTNAME="flamingo"
        ;;
    3)
        ACCENTNAME="pink"
        ;;
    4)
        ACCENTNAME="mauve"
        ;;
    5)
        ACCENTNAME="red"
        ;;
    6)
        ACCENTNAME="maroon"
        ;;
    7)
        ACCENTNAME="peach"
        ;;
    8)
        ACCENTNAME="yellow"
        ;;
    9)
        ACCENTNAME="green"
        ;;
    10)
        ACCENTNAME="teal"
        ;;
    11)
        ACCENTNAME="sky"
        ;;
    12)
        ACCENTNAME="sapphire"
        ;;
    13)
        ACCENTNAME="blue"
        ;;
    14)
        ACCENTNAME="lavender"
        ;;
    *)
    echo "write a valid accent bro :(" ;;
esac

    set_k ${1,,} $ACCENTNAME
    break
    done
}
set_theme() {
  set_qt $1
  set_accent $1
  echo "Catppuccin theme is set:)"
  exit 0
}
configure_flavour() {
    while true; do
     cat <<EOF
  Choose flavor out of -
      1. Mocha
      2. Macchiato
      3. Frappé
      4. Latte
      (Type the number corresponding to said flavour)
EOF
      read -rp flavour
        case $flavour in
          1 ) set_theme "Mocha"   ;;
          2 ) set_theme "Latte"   ;;
          3 ) set_theme  "Macchiato"  ;;
          4 ) set_theme "Frappe" ;;
            * ) printf "Write a valid flavour"  ;;
        esac
    done
  }
. ./system-setup/3-global-theme.sh
configure_flavour
