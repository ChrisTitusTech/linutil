#!/bin/sh

# Sort all tab_data.toml files in the core/tabs directory
# - Sorts [[data]] blocks alphabetically by name
# - Sorts [[data.entries]] within each block alphabetically by name
# - Places blocks with entries before blocks without entries

set -e

echo "Sorting all tab_data.toml files..."

find core/tabs -name "tab_data.toml" | while IFS= read -r file; do
    echo "Processing: $file"
    
    awk '
    BEGIN {
        in_data = 0
        in_entry = 0
        data_count = 0
        entry_count = 0
    }
    
    # Capture file header (lines before first [[data]])
    !in_data && !/^\[\[data\]\]$/ {
        header = header $0 "\n"
        next
    }
    
    # Start of new [[data]] block
    /^\[\[data\]\]$/ {
        save_entry_block()
        save_data_block()
        data_header = $0 "\n"
        in_data = 1
        in_entry = 0
        data_name = ""
        next
    }
    
    # Start of new [[data.entries]] block
    in_data && /^\[\[data\.entries\]\]$/ {
        save_entry_block()
        entry_block = $0 "\n"
        in_entry = 1
        entry_name = ""
        next
    }
    
    # Lines inside [[data.entries]]
    in_entry {
        entry_block = entry_block $0 "\n"
        if ($0 ~ /^name = / && !entry_name) {
            entry_name = extract_name($0)
        }
        next
    }
    
    # Lines inside [[data]] but outside [[data.entries]]
    in_data {
        data_header = data_header $0 "\n"
        if ($0 ~ /^name = / && !data_name) {
            data_name = extract_name($0)
        }
        next
    }
    
    END {
        save_entry_block()
        save_data_block()
        print_sorted_output()
    }
    
    # Helper function to extract and normalize name field
    function extract_name(line) {
        gsub(/^name = "/, "", line)
        gsub(/".*$/, "", line)
        return tolower(line)
    }
    
    # Save current entry block
    function save_entry_block() {
        if (entry_block && entry_name) {
            entry_blocks[entry_name] = entry_block
            entry_names[++entry_count] = entry_name
            entry_block = ""
            entry_name = ""
        }
    }
    
    # Save current data block with sorted entries
    function save_data_block() {
        if (data_name) {
            # Sort and append entries
            if (entry_count > 0) {
                n = asort(entry_names, sorted)
                for (i = 1; i <= n; i++) {
                    data_header = data_header entry_blocks[sorted[i]]
                }
                has_entries[data_name] = 1
            }
            
            data_blocks[data_name] = data_header
            data_names[++data_count] = data_name
            
            # Reset for next block
            entry_count = 0
            delete entry_blocks
            delete entry_names
            data_header = ""
            data_name = ""
        }
    }
    
    # Print sorted output
    function print_sorted_output() {
        printf "%s", header
        
        if (data_count > 0) {
            n = asort(data_names, sorted)
            
            # First: blocks with entries
            for (i = 1; i <= n; i++) {
                if (has_entries[sorted[i]]) {
                    printf "%s", data_blocks[sorted[i]]
                }
            }
            
            # Second: blocks without entries
            for (i = 1; i <= n; i++) {
                if (!has_entries[sorted[i]]) {
                    printf "%s", data_blocks[sorted[i]]
                }
            }
        }
    }
    ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
done

echo "Done!"