#!/bin/sh

RC='\033[0m'
RED='\033[0;31m'

# Function to fetch the latest release tag from the GitHub API
get_latest_release() {
  local latest_release
  latest_release=$(curl -s https://api.github.com/repos/ChrisTitusTech/linutil/releases | jq -r 'map(select(.prerelease == true)) | .tag_name')
  if [ -z "$latest_release" ]; then
    echo "Error fetching release data" >&2
    return 1
  fi
  echo "$latest_release"
}

# Function to redirect to the latest pre-release version
redirect_to_latest_pre_release() {
  local latest_release
  latest_release=$(get_latest_release)
  if [ -n "$latest_release" ]; then
    url="https://raw.githubusercontent.com/ChrisTitusTech/linutil/$latest_release/linutil"
  else
    echo 'Unable to determine latest pre-release version.' >&2
    echo "Using latest Full Release"
    url="https://github.com/ChrisTitusTech/linutil/releases/latest/download/linutil"
  fi
  echo "Using URL: $url"  # Log the URL being used
}

check() {
    local exit_code=$1
    local message=$2

    if [ $exit_code -ne 0 ]; then
        echo "${RED}ERROR: $message${RC}"
        exit 1
    fi
}

redirect_to_latest_pre_release

TMPFILE=$(mktemp)
check $? "Creating the temporary file"

echo "Downloading linutil from $url"  # Log the download attempt
curl -fsL $url -o $TMPFILE
check $? "Downloading linutil"

chmod +x $TMPFILE
check $? "Making linutil executable"

"$TMPFILE"
check $? "Executing linutil"

rm -f $TMPFILE
check $? "Deleting the temporary file"