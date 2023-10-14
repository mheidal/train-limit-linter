#!/bin/bash

# Get the parent folder's path
parentFolder=$(dirname "$0")

# Define the subfolder to exclude
excludeSubfolder="releases"

# Load version from info.json
jsonPath="$parentFolder/info.json"
if [ -f "$jsonPath" ]; then
    version=$(jq -r .version "$jsonPath")
else
    echo "Error: info.json not found or does not contain 'version' information."
    exit 1
fi

# Define the name of the zip file
zipFileName="train-limit-linter_$version.zip"

# Define the path to the output zip file
zipFilePath="$parentFolder/releases/$zipFileName"

# Check if the zip file already exists
if [ ! -f "$zipFilePath" ]; then
    # Create the zip file
    zip -r "$zipFilePath" "$parentFolder" -x "$parentFolder/$excludeSubfolder/*" -x "$parentFolder/$zipFileName"
    echo "Successfully created $zipFileName in the 'releases' subfolder."
else
    echo "Error: $zipFileName already exists in the 'releases' subfolder."
fi
