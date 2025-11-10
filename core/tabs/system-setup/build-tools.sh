#!/bin/sh -e

# shellcheck disable=SC2086

# Tools and packages required for building software from source
# Installs common compilers and build systems across supported distros.

. ../common-script.sh

installBuildTools() {
	printf "%b\n" "${YELLOW}Installing build toolchain...${RC}"

	case "$PACKAGER" in
		pacman)
			# base-devel provides gcc, make, binutils, autoconf/automake/libtool, m4, patch, etc.
			# Add popular extras: clang/llvm/lld, cmake, ninja, meson, pkgconf, ccache, mold
			"$ESCALATION_TOOL" "$PACKAGER" -Syu --noconfirm
			$AUR_HELPER -S --needed --noconfirm \
				base-devel \
				cmake \
				ninja \
				meson \
				pkgconf \
				clang \
				llvm \
				lld \
				ccache \
				mold
			;;
		apt-get|nala)
			# Ubuntu/Debian
			"$ESCALATION_TOOL" "$PACKAGER" update
			"$ESCALATION_TOOL" "$PACKAGER" install -y \
				build-essential \
				cmake \
				ninja-build \
				meson \
				pkg-config \
				clang \
				lld \
				ccache \
				autoconf automake libtool m4 patch \
				git curl wget
			# mold is available on newer Debian/Ubuntu; install if present.
			if apt-cache show mold >/dev/null 2>&1; then
				"$ESCALATION_TOOL" "$PACKAGER" install -y mold || true
			fi
			;;
		dnf)
			# Fedora/RHEL-like
			"$ESCALATION_TOOL" "$PACKAGER" -y update
			# Enable needed repos for devel content (CRB on newer Fedora/RHEL)
			"$ESCALATION_TOOL" "$PACKAGER" config-manager --enable powertools 2>/dev/null || \
			"$ESCALATION_TOOL" "$PACKAGER" config-manager --enable crb 2>/dev/null || true
			# Core development tools
			if ! "$ESCALATION_TOOL" "$PACKAGER" -y group install "Development Tools" 2>/dev/null; then
				"$ESCALATION_TOOL" "$PACKAGER" -y group install development-tools || true
			fi
			"$ESCALATION_TOOL" "$PACKAGER" -y install \
				cmake \
				ninja-build \
				meson \
				pkgconf-pkg-config \
				clang \
				llvm \
				lld \
				ccache \
				autoconf automake libtool m4 patch \
				git curl wget
			# mold exists in Fedora repos; best-effort install
			"$ESCALATION_TOOL" "$PACKAGER" -y install mold || true
			;;
		zypper)
			# openSUSE
			"$ESCALATION_TOOL" "$PACKAGER" refresh
			# devel_basis pattern includes GCC toolchain and common autotools
			"$ESCALATION_TOOL" "$PACKAGER" --non-interactive install patterns-devel-base-devel_basis || true
			"$ESCALATION_TOOL" "$PACKAGER" --non-interactive install \
				gcc gcc-c++ \
				cmake \
				ninja \
				meson \
				pkg-config \
				clang \
				lld \
				ccache \
				autoconf automake libtool m4 patch \
				git curl wget
			# mold may be available; try without failing the run
			"$ESCALATION_TOOL" "$PACKAGER" --non-interactive install mold || true
			;;
		apk)
			# Alpine Linux
			"$ESCALATION_TOOL" "$PACKAGER" update
			"$ESCALATION_TOOL" "$PACKAGER" add \
				build-base \
				cmake \
				ninja \
				meson \
				pkgconf \
				clang \
				lld \
				ccache \
				autoconf automake libtool m4 patch \
				git curl wget
			# mold exists in community for newer Alpine
			"$ESCALATION_TOOL" "$PACKAGER" add mold || true
			;;
		xbps-install)
			# Void Linux
			"$ESCALATION_TOOL" "$PACKAGER" -Syu
			"$ESCALATION_TOOL" "$PACKAGER" -Sy \
				base-devel \
				cmake \
				ninja \
				meson \
				pkgconf \
				clang \
				lld \
				ccache \
				autoconf automake libtool m4 patch \
				git curl wget
			"$ESCALATION_TOOL" "$PACKAGER" -Sy mold || true
			;;
		eopkg)
			# Solus
			"$ESCALATION_TOOL" "$PACKAGER" update-repo
			"$ESCALATION_TOOL" "$PACKAGER" install -y -c system.devel || true
			"$ESCALATION_TOOL" "$PACKAGER" install -y \
				cmake \
				ninja \
				meson \
				pkg-config \
				clang \
				ccache \
				autoconf automake libtool m4 patch \
				git curl wget
			# mold availability on Solus is uncertain; skip by default
			;;
		*)
			printf "%b\n" "${RED}Unsupported package manager ${PACKAGER}${RC}"
			exit 1
			;;
	esac

	printf "%b\n" "${GREEN}Build toolchain installation complete.${RC}"
}

checkEnv
checkAURHelper
checkEscalationTool
installBuildTools
