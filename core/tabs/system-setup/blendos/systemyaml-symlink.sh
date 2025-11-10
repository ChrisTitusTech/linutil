#!/usr/bin/env bash
# scripts/blendos/systemyaml-ymlink.sh

# Exit silently if not blendOS
grep -qi 'blend' /etc/os-release || exit 0

# Force symlink config/system.yaml to /system.yaml
ln -sf "$(realpath "$(dirname "$0")/../../config/system.yaml")" /system.yaml