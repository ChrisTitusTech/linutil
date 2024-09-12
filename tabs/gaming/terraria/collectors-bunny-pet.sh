#!/bin/bash

# Define the path to the Terraria registry directory
TERRARIA_DIR="$HOME/.mono/registry/CurrentUser/software/terraria"

# Check if the directory exists, if not, create it
if [ ! -d "$TERRARIA_DIR" ]; then
    echo "Directory $TERRARIA_DIR does not exist, creating it..."
    mkdir -p "$TERRARIA_DIR"
else
    echo "Directory $TERRARIA_DIR already exists."
fi

# Define the path to the values.xml file
VALUES_FILE="$TERRARIA_DIR/values.xml"

# Check if the values.xml file exists
if [ ! -f "$VALUES_FILE" ]; then
    echo "Creating values.xml..."
    # Write the XML content to values.xml
    cat <<EOL > "$VALUES_FILE"
<values>
    <value name="Bunny" type="string">1</value>
</values>
EOL
else
    echo "values.xml already exists."
fi

echo "Completed. Please restart Terraria to apply the changes."
echo "Create a new character, then the Bunny Pet will automatically be added to your inventory."


