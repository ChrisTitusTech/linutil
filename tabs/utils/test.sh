#!/bin/sh

# Initialize an empty string to hold the group names
group_list=""

# Read each group name and accumulate them in the list
cut -d: -f1 /etc/group | while read -r group; do
  if [ -n "$group_list" ]; then
    group_list="$group_list, $group"
  else
    group_list="$group"
  fi
done

# Print the comma-separated list
echo "Available groups: $group_list"

