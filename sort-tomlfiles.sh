#!/bin/sh

# Sort all tab_data.toml files in the core/tabs directory
set -e

echo "Sorting all tab_data.toml files..."

for file in $(find core/tabs -name "tab_data.toml"); do
    echo "Processing: $file"
    
    awk '
    BEGIN { 
        entry = ""
        in_entry = 0
        entry_count = 0
    }
    
    # Start of a new [[data]] section or [[data.preconditions]]
    /^\[\[data\]\]$/ || /^\[\[data\.preconditions\]\]$/ {
        # Flush any stored entries from previous section
        if (entry != "") {
            entries[entry_name] = entry
            entry_names[++entry_count] = entry_name
            entry = ""
        }
        if (entry_count > 0) {
            n = asort(entry_names, sorted_names)
            for (j = 1; j <= n; j++) {
                name = sorted_names[j]
                printf "%s", entries[name]
            }
            delete entries
            delete entry_names
            entry_count = 0
        }
        print
        in_entry = 0
        next
    }
    
    # Start of a [[data.entries]] block
    /^\[\[data\.entries\]\]$/ {
        # Save previous entry if exists
        if (entry != "") {
            entries[entry_name] = entry
            entry_names[++entry_count] = entry_name
        }
        entry = $0 "\n"
        in_entry = 1
        entry_name = ""
        next
    }
    
    # Inside a [[data.entries]] block
    in_entry {
        entry = entry $0 "\n"
        if ($0 ~ /^name = /) {
            gsub(/^name = "/, "", $0)
            gsub(/".*$/, "", $0)
            entry_name = tolower($0)
        }
        next
    }
    
    # Everything else (not in entry block)
    !in_entry {
        print
    }
    
    END {
        # Flush remaining entries at end of file
        if (entry != "") {
            entries[entry_name] = entry
            entry_names[++entry_count] = entry_name
        }
        if (entry_count > 0) {
            n = asort(entry_names, sorted_names)
            for (j = 1; j <= n; j++) {
                name = sorted_names[j]
                printf "%s", entries[name]
            }
        }
    }
    ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
done

echo "Done!"