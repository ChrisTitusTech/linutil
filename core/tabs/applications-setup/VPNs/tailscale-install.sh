#!/bin/sh
# Sourced from the official Tailscale website: https://github.com/tailscale/tailscale/blob/main/scripts/installer.sh
# Copyright (c) Tailscale Inc & AUTHORS
# SPDX-License-Identifier: BSD-3-Clause
#
# This script detects the current operating system, and installs
# Tailscale according to that OS's conventions.

curl -fsSL https://tailscale.com/install.sh | sh