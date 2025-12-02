#!/bin/sh -e

. ../common-script.sh

# Install packages with privilege handling
install_packages() {
  pkg_manager=$1
  shift
  case "$pkg_manager" in
  paru | yay)
    $pkg_manager -S --needed --noconfirm "$@"
    ;;
  pacman)
    $ESCALATION_TOOL "$pkg_manager" -S --needed --noconfirm "$@"
    ;;
  apt-get | nala | dnf | zypper)
    $ESCALATION_TOOL "$pkg_manager" install -y "$@"
    ;;
  esac
}

installDesktopEnvironment() {
  printf "%s\n" " Installing Desktop Environment... "
  case "$PACKAGER" in
  pacman)
    case "$1" in
    gnome) install_packages "$AUR_HELPER" gnome gnome-extra ;;
    kde) install_packages "$AUR_HELPER" plasma kde-applications ;;
    xfce) install_packages "$AUR_HELPER" xfce4 xfce4-goodies ;;
    cinnamon) install_packages "$AUR_HELPER" cinnamon cinnamon-translations ;;
    mate) install_packages "$AUR_HELPER" mate mate-extra ;;
    budgie) install_packages "$AUR_HELPER" budgie-desktop ;;
    lxqt) install_packages "$AUR_HELPER" lxqt ;;
    lxde) install_packages "$AUR_HELPER" lxde ;;
    *)
      printf "%s\n" "$RED Unsupported desktop environment: $1 "
      exit 1
      ;;
    esac
    ;;
  apt-get | nala)
    case "$1" in
    gnome) install_packages "$PACKAGER" ubuntu-gnome-desktop ;;
    kde) install_packages "$PACKAGER" kde-plasma-desktop ;;
    xfce) install_packages "$PACKAGER" xfce4 xfce4-goodies ;;
    cinnamon) install_packages "$PACKAGER" cinnamon-desktop-environment ;;
    mate) install_packages "$PACKAGER" ubuntu-mate-desktop ;;
    budgie) install_packages "$PACKAGER" ubuntu-budgie-desktop ;;
    lxqt) install_packages "$PACKAGER" lubuntu-desktop ;;
    lxde) install_packages "$PACKAGER" lxde ;;
    *)
      printf "%s\n" "$RED Unsupported desktop environment: $1 "
      exit 1
      ;;
    esac
    ;;
  dnf)
    case "$1" in
    gnome) install_packages "$PACKAGER" @gnome-desktop ;;
    kde) install_packages "$PACKAGER" @kde-desktop ;;
    xfce) install_packages "$PACKAGER" @xfce-desktop-environment ;;
    cinnamon) install_packages "$PACKAGER" @cinnamon-desktop-environment ;;
    mate) install_packages "$PACKAGER" @mate-desktop-environment ;;
    budgie) install_packages "$PACKAGER" @budgie-desktop-environment ;;
    lxqt) install_packages "$PACKAGER" @lxqt-desktop-environment ;;
    lxde) install_packages "$PACKAGER" @lxde-desktop-environment ;;
    *)
      printf "%s\n" "$RED Unsupported desktop environment: $1 "
      exit 1
      ;;
    esac
    ;;
  zypper)
    case "$1" in
    gnome) install_packages "$PACKAGER" patterns-gnome-gnome ;;
    kde) install_packages "$PACKAGER" patterns-kde-kde_plasma ;;
    xfce) install_packages "$PACKAGER" patterns-xfce-xfce ;;
    cinnamon) install_packages "$PACKAGER" patterns-cinnamon-cinnamon ;;
    mate) install_packages "$PACKAGER" patterns-mate-mate ;;
    budgie) install_packages "$PACKAGER" patterns-budgie-budgie ;;
    lxqt) install_packages "$PACKAGER" patterns-lxqt-lxqt ;;
    lxde) install_packages "$PACKAGER" patterns-lxde-lxde ;;
    *)
      printf "%s\n" "$RED Unsupported desktop environment: $1 "
      exit 1
      ;;
    esac
    ;;
  *)
    printf "%s\n" "$RED Unsupported package manager: $PACKAGER "
    exit 1
    ;;
  esac
}

installWindowManager() {
  printf "%s\n" " Installing Window Manager... "
  case "$PACKAGER" in
  pacman)
    case "$1" in
    i3) install_packages "$AUR_HELPER" i3-wm i3status i3lock ;;
    sway) install_packages "$AUR_HELPER" sway swaylock swayidle ;;
    dwm) install_packages "$AUR_HELPER" dwm ;;
    awesome) install_packages "$AUR_HELPER" awesome ;;
    bspwm) install_packages "$AUR_HELPER" bspwm sxhkd ;;
    openbox) install_packages "$AUR_HELPER" openbox ;;
    fluxbox) install_packages "$AUR_HELPER" fluxbox ;;
    niri) install_packages "$AUR_HELPER" niri ;;
    river) install_packages "$AUR_HELPER" river ;;
    hyde) install_packages "$AUR_HELPER" hyde ;;
    miracle-wm) install_packages "$AUR_HELPER" miracle-wm ;;
    *)
      printf "%s\n" "$RED Unsupported window manager: $1 "
      exit 1
      ;;
    esac
    ;;
  apt-get | nala | dnf | zypper)
    case "$1" in
    i3) install_packages "$PACKAGER" i3 i3status i3lock ;;
    sway) install_packages "$PACKAGER" sway swaylock swayidle ;;
    dwm) install_packages "$PACKAGER" dwm ;;
    awesome) install_packages "$PACKAGER" awesome ;;
    bspwm) install_packages "$PACKAGER" bspwm sxhkd ;;
    openbox) install_packages "$PACKAGER" openbox ;;
    fluxbox) install_packages "$PACKAGER" fluxbox ;;
    *)
      printf "%s\n" "$RED Unsupported window manager: $1 "
      exit 1
      ;;
    esac
    ;;
  *)
    printf "%s\n" "$RED Unsupported package manager: $PACKAGER "
    exit 1
    ;;
  esac
}

main() {
  printf "%s\n" " Desktop Environment and Window Manager Installation "
  printf "%s\n" " ============================================= "
  printf "%s\n" " 1. Install Desktop Environment "
  printf "%s\n" " 2. Install Window Manager "
  printf "%s\n" " 3. Exit "
  printf "%s" " Please select an option (1-3): "
  read -r choice

  case "$choice" in
  1)
    printf "%s\n" " Available Desktop Environments: "
    printf "%s\n" " 1. GNOME "
    printf "%s\n" " 2. KDE Plasma "
    printf "%s\n" " 3. XFCE "
    printf "%s\n" " 4. Cinnamon "
    printf "%s\n" " 5. MATE "
    printf "%s\n" " 6. Budgie "
    printf "%s\n" " 7. LXQt "
    printf "%s\n" " 8. LXDE "
    printf "%s" " Please select a desktop environment (1-8): "
    read -r de_choice
    case "$de_choice" in
    1) installDesktopEnvironment gnome ;;
    2) installDesktopEnvironment kde ;;
    3) installDesktopEnvironment xfce ;;
    4) installDesktopEnvironment cinnamon ;;
    5) installDesktopEnvironment mate ;;
    6) installDesktopEnvironment budgie ;;
    7) installDesktopEnvironment lxqt ;;
    8) installDesktopEnvironment lxde ;;
    *) printf "%s\n" "$RED Invalid selection " ;;
    esac
    ;;
  2)
    printf "%s\n" " Available Window Managers: "
    printf "%s\n" " 1. i3 "
    printf "%s\n" " 2. Sway "
    printf "%s\n" " 3. DWM "
    printf "%s\n" " 4. Awesome "
    printf "%s\n" " 5. BSPWM "
    printf "%s\n" " 6. Openbox "
    printf "%s\n" " 7. Fluxbox "
    printf "%s\n" " 8. Niri "
    printf "%s\n" " 9. HyDE "
    printf "%s" " Please select a window manager (1-9): "
    read -r wm_choice
    case "$wm_choice" in
    1) installWindowManager i3 ;;
    2) installWindowManager sway ;;
    3) installWindowManager dwm ;;
    4) installWindowManager awesome ;;
    5) installWindowManager bspwm ;;
    6) installWindowManager openbox ;;
    7) installWindowManager fluxbox ;;
    8) installWindowManager niri ;;
    9) installWindowManager hyde ;;
    *) printf "%s\n" "$RED Invalid selection " ;;
    esac
    ;;
  3)
    exit 0
    ;;
  *)
    printf "%s\n" "$RED Invalid selection "
    ;;
  esac
}

checkEnv
main
