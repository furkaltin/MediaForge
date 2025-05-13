#!/bin/bash

# MediaForge Localization Setup Script
# This script sets up the localization structure for MediaForge

# Create localization directories if they don't exist
echo "Creating localization directories..."
mkdir -p "${SRCROOT}/MediaForge/Localization/en.lproj"
mkdir -p "${SRCROOT}/MediaForge/Localization/tr.lproj"

# Setup bundle structure for localized resources
echo "Setting up localization bundle structure..."

# Create symbolic links for localization resources in main bundle
if [ ! -L "${BUILT_PRODUCTS_DIR}/${CONTENTS_FOLDER_PATH}/Resources/en.lproj" ]; then
  ln -sfh "${SRCROOT}/MediaForge/Localization/en.lproj" "${BUILT_PRODUCTS_DIR}/${CONTENTS_FOLDER_PATH}/Resources/en.lproj"
fi

if [ ! -L "${BUILT_PRODUCTS_DIR}/${CONTENTS_FOLDER_PATH}/Resources/tr.lproj" ]; then
  ln -sfh "${SRCROOT}/MediaForge/Localization/tr.lproj" "${BUILT_PRODUCTS_DIR}/${CONTENTS_FOLDER_PATH}/Resources/tr.lproj"
fi

echo "Localization setup complete!"
