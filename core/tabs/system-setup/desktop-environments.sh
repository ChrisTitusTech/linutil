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

installOxwmFromSource() {
  if ! command_exists zig; then
    printf "%s\n" "$RED OXWM source installation requires Zig 0.16.0 or newer. Install a suitable Zig compiler and try again. "
    exit 1
  fi

  zig_version=$(zig version)
  oldest_version=$(printf "%s\n" "$zig_version" "0.16.0" | sort -V | head -n 1)
  if [ "$oldest_version" != "0.16.0" ]; then
    printf "%s\n" "$RED OXWM requires Zig 0.16.0 or newer; found $zig_version. "
    exit 1
  fi

  case "$PACKAGER" in
  apt-get | nala)
    install_packages "$PACKAGER" git libx11-dev libxft-dev libfreetype-dev libfontconfig1-dev libxinerama-dev libinput-dev libsystemd-dev
    ;;
  dnf)
    install_packages "$PACKAGER" git libX11-devel libXft-devel freetype-devel fontconfig-devel libXinerama-devel libinput-devel systemd-devel
    ;;
  zypper)
    install_packages "$PACKAGER" git libX11-devel libXft-devel freetype2-devel fontconfig-devel libXinerama-devel libinput-devel systemd-devel
    ;;
  *)
    printf "%s\n" "$RED OXWM source installation is unsupported for package manager: $PACKAGER "
    exit 1
    ;;
  esac

  OXWM_BUILD_DIR=$(mktemp -d)
  trap 'rm -rf "$OXWM_BUILD_DIR"' 0
  git clone --depth 1 --branch v0.13.0 https://github.com/tonybanters/oxwm.git "$OXWM_BUILD_DIR/oxwm"
  cd "$OXWM_BUILD_DIR/oxwm"
  zig build -Doptimize=ReleaseSmall --prefix "$OXWM_BUILD_DIR/stage"

  if [ ! -x "$OXWM_BUILD_DIR/stage/bin/oxwm" ]; then
    printf "%s\n" "$RED OXWM build succeeded but did not produce the expected binary. "
    exit 1
  fi

  printf "%s\n" "[Desktop Entry]" "Name=OXWM" "Comment=OXWM window manager" "Exec=oxwm" "Type=Application" > "$OXWM_BUILD_DIR/oxwm.desktop"
  "$ESCALATION_TOOL" install -D -m 755 "$OXWM_BUILD_DIR/stage/bin/oxwm" /usr/bin/oxwm
  "$ESCALATION_TOOL" install -D -m 644 "$OXWM_BUILD_DIR/oxwm.desktop" /usr/share/xsessions/oxwm.desktop
}

installMiracleWmFromPpa() {
  case "$DTYPE:$VERSION_CODENAME" in
  ubuntu:questing | ubuntu:resolute) ;;
  *)
    printf "%s\n" "$RED Miracle-WM's Ubuntu PPA is only supported on Ubuntu questing and resolute. "
    exit 1
    ;;
  esac

  install_packages "$PACKAGER" software-properties-common
  if ! command_exists add-apt-repository; then
    printf "%s\n" "$RED Miracle-WM's Ubuntu PPA route requires add-apt-repository. "
    exit 1
  fi

  "$ESCALATION_TOOL" add-apt-repository -y ppa:mir-team/release
  "$ESCALATION_TOOL" "$PACKAGER" update
  "$ESCALATION_TOOL" add-apt-repository -y ppa:matthew-kosarek/miracle-wm
  "$ESCALATION_TOOL" "$PACKAGER" update
  install_packages "$PACKAGER" miracle-wm
}

cleanupMiracleWmSourceInstall() {
  MIRACLE_BUILD_STATUS=$?
  if [ "$MIRACLE_BUILD_STATUS" -ne 0 ] && [ "$MIRACLE_INSTALL_STARTED" = 1 ]; then
    if ! "$ESCALATION_TOOL" rm -rf /opt/linutil/miracle-wm /var/lib/linutil/miracle-wm; then
      printf "%s\n" "$RED Failed to remove the partial Miracle-WM source installation. "
    fi
    if ! "$ESCALATION_TOOL" rm -f /etc/ld.so.conf.d/linutil-miracle-wm.conf \
      /usr/share/wayland-sessions/linutil-miracle-wm.desktop \
      /usr/local/lib/systemd/user/miracle-wm-session.target \
      /usr/local/lib/systemd/user/miracle-wm-session-shutdown.target \
      /usr/local/lib/systemd/user/miracle-wm-xdg-autostart.target; then
      printf "%s\n" "$RED Failed to remove partial Miracle-WM system integration files. "
    fi
    if ! "$ESCALATION_TOOL" ldconfig; then
      printf "%s\n" "$RED Failed to refresh the dynamic linker cache after rollback. "
    fi
  fi
  rm -rf "$MIRACLE_BUILD_DIR"
}

installMiracleWmFromSource() {
  MIRACLE_PREFIX=/opt/linutil/miracle-wm
  MIRACLE_STATE_DIR=/var/lib/linutil/miracle-wm
  MIRACLE_BUILD_DIR=$(mktemp -d)
  MIRACLE_INSTALL_STARTED=0
  trap 'cleanupMiracleWmSourceInstall' 0

  if [ -e "$MIRACLE_PREFIX" ] || [ -e "$MIRACLE_STATE_DIR" ] ||
    [ -e /etc/ld.so.conf.d/linutil-miracle-wm.conf ] ||
    [ -e /usr/share/wayland-sessions/linutil-miracle-wm.desktop ] ||
    [ -e /usr/local/lib/systemd/user/miracle-wm-session.target ] ||
    [ -e /usr/local/lib/systemd/user/miracle-wm-session-shutdown.target ] ||
    [ -e /usr/local/lib/systemd/user/miracle-wm-xdg-autostart.target ]; then
    printf "%s\n" "$RED A Miracle-WM source installation or one of its reserved paths already exists. "
    exit 1
  fi

  install_packages "$PACKAGER" build-essential cmake git pkg-config dpkg-dev \
    libyaml-cpp-dev libglib2.0-dev libevdev-dev nlohmann-json3-dev \
    libnotify-dev libgles2-mesa-dev libxkbcommon-dev libjson-c-dev \
    libpcre2-dev libboost-filesystem-dev libboost-system-dev \
    libgtk-4-dev libgtk4-layer-shell-dev gettext python3-tenacity python3-dbus-next

  MIRACLE_STAGE="$MIRACLE_BUILD_DIR/stage"
  MIR_SOURCE_DIR="$MIRACLE_BUILD_DIR/mir"
  MIR_BUILD_DIR="$MIRACLE_BUILD_DIR/mir-build"
  MIRACLE_SOURCE_DIR="$MIRACLE_BUILD_DIR/miracle-wm"
  MIRACLE_CMAKE_BUILD_DIR="$MIRACLE_BUILD_DIR/miracle-wm-build"
  MIRACLE_PKGCONFIG_DIR="$MIRACLE_BUILD_DIR/mir-pkgconfig"
  git clone --depth 1 --branch v2.18.0 https://github.com/canonical/mir.git "$MIR_SOURCE_DIR"
  git clone --depth 1 --branch v0.11.2 https://github.com/miracle-wm-org/miracle-wm.git "$MIRACLE_SOURCE_DIR"

  cd "$MIR_SOURCE_DIR"
  if ! "$ESCALATION_TOOL" apt-get build-dep -y ./; then
    printf "%s\n" "$RED Failed to install Mir build dependencies. Enable Debian source repositories (deb-src) and retry. "
    exit 1
  fi
  cmake -S "$MIR_SOURCE_DIR" -B "$MIR_BUILD_DIR" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$MIRACLE_PREFIX" \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DMIR_ENABLE_TESTS=OFF
  cmake --build "$MIR_BUILD_DIR" --parallel 2
  DESTDIR="$MIRACLE_STAGE" cmake --install "$MIR_BUILD_DIR"

  mkdir -p "$MIRACLE_PKGCONFIG_DIR"
  for mir_pc_file in "$MIRACLE_STAGE$MIRACLE_PREFIX"/lib/pkgconfig/*.pc; do
    [ -f "$mir_pc_file" ] || continue
    sed "s|^prefix=.*|prefix=$MIRACLE_STAGE$MIRACLE_PREFIX|" "$mir_pc_file" \
      > "$MIRACLE_PKGCONFIG_DIR/$(basename "$mir_pc_file")"
  done

  printf "%s\n" "Building Miracle-WM without its optional WasmEdge plugin system. "
  PKG_CONFIG_PATH="$MIRACLE_PKGCONFIG_DIR${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}" \
    cmake -S "$MIRACLE_SOURCE_DIR" -B "$MIRACLE_CMAKE_BUILD_DIR" \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX="$MIRACLE_PREFIX" \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DCMAKE_PREFIX_PATH="$MIRACLE_STAGE$MIRACLE_PREFIX" \
      -DFEATURE_PLUGIN_SYSTEM=OFF \
      -DSYSTEMD_INTEGRATION=ON \
      -DENABLE_TESTS=OFF
  cmake --build "$MIRACLE_CMAKE_BUILD_DIR" --parallel 2
  DESTDIR="$MIRACLE_STAGE" cmake --install "$MIRACLE_CMAKE_BUILD_DIR"

  if [ ! -x "$MIRACLE_STAGE$MIRACLE_PREFIX/bin/miracle-wm-session" ] ||
    [ ! -f "$MIRACLE_STAGE$MIRACLE_PREFIX/share/wayland-sessions/miracle-wm.desktop" ] ||
    [ ! -f "$MIRACLE_STAGE$MIRACLE_PREFIX/lib/systemd/user/miracle-wm-session.target" ] ||
    [ ! -f "$MIRACLE_STAGE$MIRACLE_PREFIX/lib/systemd/user/miracle-wm-session-shutdown.target" ] ||
    [ ! -f "$MIRACLE_STAGE$MIRACLE_PREFIX/lib/systemd/user/miracle-wm-xdg-autostart.target" ]; then
    printf "%s\n" "$RED Miracle-WM source build did not produce its session files. "
    exit 1
  fi

  printf "%s\n" "$MIRACLE_PREFIX/lib" > "$MIRACLE_BUILD_DIR/ld.so.conf"
  printf "%s\n" "Miracle-WM source build v0.11.2 with Mir v2.18.0" > "$MIRACLE_BUILD_DIR/source-install"
  MIRACLE_INSTALL_STARTED=1
  "$ESCALATION_TOOL" install -d "$MIRACLE_PREFIX" "$MIRACLE_STATE_DIR"
  "$ESCALATION_TOOL" install -D -m 644 "$MIRACLE_BUILD_DIR/source-install" \
    "$MIRACLE_STATE_DIR/source-install"
  "$ESCALATION_TOOL" cp -a "$MIRACLE_STAGE$MIRACLE_PREFIX/." "$MIRACLE_PREFIX/"
  "$ESCALATION_TOOL" install -D -m 644 "$MIRACLE_BUILD_DIR/ld.so.conf" /etc/ld.so.conf.d/linutil-miracle-wm.conf
  "$ESCALATION_TOOL" install -D -m 644 \
    "$MIRACLE_STAGE$MIRACLE_PREFIX/share/wayland-sessions/miracle-wm.desktop" \
    /usr/share/wayland-sessions/linutil-miracle-wm.desktop
  for systemd_target in miracle-wm-session.target miracle-wm-session-shutdown.target miracle-wm-xdg-autostart.target; do
    "$ESCALATION_TOOL" install -D -m 644 \
      "$MIRACLE_STAGE$MIRACLE_PREFIX/lib/systemd/user/$systemd_target" \
      "/usr/local/lib/systemd/user/$systemd_target"
  done
  "$ESCALATION_TOOL" ldconfig
}

installSomewmFromSource() {
  case "$PACKAGER" in
  apt-get | nala)
    install_packages "$PACKAGER" build-essential git meson ninja-build pkg-config \
      luajit libluajit-5.1-dev lua-lgi libcairo2-dev libpango1.0-dev \
      libgdk-pixbuf-2.0-dev librsvg2-dev libglib2.0-dev libdbus-1-dev \
      libwayland-dev libwayland-bin wayland-protocols libdrm-dev \
      libinput-dev libxkbcommon-dev libgbm-dev libegl-dev libgles-dev \
      libpixman-1-dev libudev-dev libseat-dev libdisplay-info-dev \
      libliftoff-dev liblcms2-dev hwdata libffi-dev libexpat1-dev \
      xwayland libxcb1-dev libxcb-util-dev libxcb-icccm4-dev \
      libxcb-composite0-dev libxcb-ewmh-dev libxcb-res0-dev \
      libxcb-render0-dev libxcb-render-util0-dev libxcb-errors-dev \
      libxcb-xfixes0-dev libxcb-xinput-dev libxcb-dri3-dev \
      libxcb-present-dev libxcb-shm0-dev
    ;;
  dnf)
    install_packages "$PACKAGER" gcc make git meson ninja-build pkgconf-pkg-config \
      luajit luajit-devel lua-lgi-compat cairo-devel pango-devel gdk-pixbuf2-devel \
      librsvg2-devel glib2-devel dbus-devel wayland-devel wayland-protocols-devel \
      libdrm-devel libinput-devel libxkbcommon-devel mesa-libgbm-devel \
      libglvnd-egl-devel libglvnd-gles-devel pixman-devel systemd-devel \
      libseat-devel libdisplay-info-devel libliftoff-devel lcms2-devel hwdata \
      xorg-x11-server-Xwayland xorg-x11-server-Xwayland-devel \
      libxcb-devel xcb-util-devel xcb-util-wm-devel \
      xcb-util-renderutil-devel xcb-util-errors-devel
    ;;
  *)
    printf "%s\n" "$RED SomeWM source installation is unsupported for package manager: $PACKAGER "
    exit 1
    ;;
  esac

  SOMEWM_BUILD_DIR=$(mktemp -d)
  trap 'rm -rf "$SOMEWM_BUILD_DIR"' 0
  git clone --depth 1 --branch v2.1.0 https://github.com/trip-zip/somewm.git "$SOMEWM_BUILD_DIR/somewm"
  cd "$SOMEWM_BUILD_DIR/somewm"
  MESON_OPTS=-Dprefix=/usr make
  "$ESCALATION_TOOL" make install
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
    oxwm) install_packages "$AUR_HELPER" oxwm-git ;;
    somewm) install_packages "$AUR_HELPER" somewm ;;
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
    miracle-wm)
      case "$PACKAGER:$DTYPE" in
      apt-get:ubuntu | nala:ubuntu)
        installMiracleWmFromPpa
        ;;
      apt-get:* | nala:*)
        case "$DTYPE $ID_LIKE" in
        *debian* | *ubuntu*) installMiracleWmFromSource ;;
        *)
          printf "%s\n" "$RED Miracle-WM source installation is unsupported for distribution: $DTYPE "
          exit 1
          ;;
        esac
        ;;
      dnf:fedora)
        install_packages "$PACKAGER" miracle-wm
        ;;
      *)
        printf "%s\n" "$RED Miracle-WM is unsupported for package manager and distribution: $PACKAGER ($DTYPE). "
        exit 1
        ;;
      esac
      ;;
    oxwm) installOxwmFromSource ;;
    # must build from source on debian
    somewm) installSomewmFromSource ;;
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
  choice=''
  readMenuChoice choice
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
    de_choice=''
    readMenuChoice de_choice
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
    printf "%s\n" " 10. Miracle-WM "
    printf "%s\n" " 11. OXWM "
    printf "%s\n" " 12. SomeWM "
    printf "%s" " Please select a window manager (1-12): "
    wm_choice=''
    readMenuChoice wm_choice
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
    10) installWindowManager miracle-wm ;;
    11) installWindowManager oxwm ;;
    12) installWindowManager somewm ;;
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
