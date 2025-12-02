#!/bin/sh

# Sort all tab_data.toml files in the core/tabs directory
set -e

echo "Sorting all tab_data.toml files..."

find core/tabs -name "tab_data.toml" | while IFS= read -r file; do
    echo "Processing: $file"
    
    awk '
    BEGIN { 
        data_block = ""
        data_name = ""
        data_count = 0
        in_data = 0
        header = ""
    }
    
    # Capture header (lines before first [[data]])
    !in_data && !/^\[\[data\]\]$/ {
        header = header $0 "\n"
        next
    }
    
    # Start of a new [[data]] section
    /^\[\[data\]\]$/ {
        # Save previous data block if exists
        if (data_block != "") {
            data_blocks[data_name] = data_block
            data_names[++data_count] = data_name
            # Check if block has entries
            if (data_block ~ /\[\[data\.entries\]\]/) {
                has_entries[data_name] = 1
            }
        }
        # Start new data block
        data_block = $0 "\n"
        in_data = 1
        data_name = ""
        next
    }
    
    # Inside a [[data]] block - collect everything until next [[data]]
    in_data {
        data_block = data_block $0 "\n"
        # Extract the name field from [[data]] section
        if ($0 ~ /^name = / && data_name == "") {
            gsub(/^name = "/, "", $0)
            gsub(/".*$/, "", $0)
            data_name = tolower($0)
        }
        next
    }
    
    END {
        # Save last data block
        if (data_block != "") {
            data_blocks[data_name] = data_block
            data_names[++data_count] = data_name
            # Check if block has entries
            if (data_block ~ /\[\[data\.entries\]\]/) {
                has_entries[data_name] = 1
            }
        }
        
        # Print header
        printf "%s", header
        
        # Sort and print data blocks - first those with entries, then those without
        if (data_count > 0) {
            n = asort(data_names, sorted_names)
            # First pass: blocks with entries
            for (i = 1; i <= n; i++) {
                name = sorted_names[i]
                if (has_entries[name]) {
                    printf "%s", data_blocks[name]
                }
            }
            # Second pass: blocks without entries
            for (i = 1; i <= n; i++) {
                name = sorted_names[i]
                if (!has_entries[name]) {
                    printf "%s", data_blocks[name]
                }
            }
        }
    }
    ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
done

echo "Done!"