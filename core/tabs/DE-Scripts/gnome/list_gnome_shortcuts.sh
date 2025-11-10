#!/bin/bash
# Lists all custom GNOME keyboard shortcuts currently configured and save them to a file.
output_file="output/gnome_shortcuts.md"
> "$output_file"  # Clear the file

for kb in $(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings | tr -d "[],'"); do
  echo "=== $kb ===" >> "$output_file"
  echo "Name:    $(gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$kb name)" >> "$output_file"
  echo "Command: $(gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$kb command)" >> "$output_file"
  echo "Binding: $(gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$kb binding)" >> "$output_file"
  echo >> "$output_file"
done

# Format the markdown file for better readability with colors and emojis
sed -i 's/=== \(.*\) ===/**\1**/g' "$output_file"
sed -i 's/Name:/📝 **Name:**/g' "$output_file"
sed -i 's/Command:/💻 **Command:**/g' "$output_file"
sed -i 's/Binding:/⌨️ **Binding:**/g' "$output_file"
sed -i 's/^\(.*\)$/\1  /g' "$output_file"  # Add two spaces at the end of each line for markdown line breaks
echo "Custom GNOME keyboard shortcuts have been saved to $output_file"