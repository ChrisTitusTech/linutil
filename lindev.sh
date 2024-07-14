#!/bin/bash

# Function to fetch the latest release tag from the GitHub API
get_latest_release() {
  local latest_release
  latest_release=$(curl -s https://api.github.com/repos/ChrisTitusTech/linutil/releases | jq -r 'map(select(.prerelease == true)) | .[0].tag_name')
  if [[ -z "$latest_release" ]]; then
    echo "Error fetching release data" >&2
    return 1
  fi
  echo "$latest_release"
}

# Function to redirect to the latest pre-release version
redirect_to_latest_pre_release() {
  local latest_release
  latest_release=$(get_latest_release)
  if [[ -n "$latest_release" ]]; then
    local url="https://raw.githubusercontent.com/ChrisTitusTech/linutil/$latest_release/start.sh"
  else
    echo 'Unable to determine latest pre-release version.' >&2
    echo "Using latest Full Release"
    local url="https://github.com/ChrisTitusTech/linutil/releases/latest/download/start.sh"
  fi
  curl -fsSL "$url" | sh
}

redirect_to_latest_pre_release
