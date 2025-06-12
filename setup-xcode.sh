#!/bin/bash

# Script to set up Xcode project for Volume Manager

echo "Setting up Volume Manager Xcode project..."

# Check if we're in the right directory
if [ ! -f "VolumeManager/AppDelegate.swift" ]; then
    echo "Error: Please run this script from the audio-volume-manager directory"
    exit 1
fi

# Method 1: Using XcodeGen (if installed)
if command -v xcodegen &> /dev/null; then
    echo "Found XcodeGen, generating project..."
    xcodegen generate
    echo "Project generated! Opening in Xcode..."
    open VolumeManager.xcodeproj
    exit 0
fi

# Method 2: Manual Xcode project creation
echo "XcodeGen not found. Here's how to create the project manually:"
echo ""
echo "1. Open Xcode"
echo "2. Create a new project (File → New → Project)"
echo "3. Choose 'macOS' → 'App'"
echo "4. Configure as follows:"
echo "   - Product Name: VolumeManager"
echo "   - Bundle Identifier: com.github.dfraserstratos.VolumeManager"
echo "   - Interface: SwiftUI (we'll remove it)"
echo "   - Language: Swift"
echo "   - Uncheck 'Use Core Data'"
echo "   - Uncheck 'Include Tests'"
echo ""
echo "5. After creation:"
echo "   a. Delete ContentView.swift and VolumeManagerApp.swift"
echo "   b. Delete Assets.xcassets if you don't need it"
echo "   c. Replace the contents with our files"
echo ""
echo "6. In project settings:"
echo "   - Set 'Application is agent (UIElement)' to YES in Info.plist"
echo "   - Set Deployment Target to macOS 10.15"
echo ""
echo "7. Add our AppDelegate.swift file to the project"
echo ""
echo "Would you like to install XcodeGen to automate this? (y/n)"
read -r response

if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    if command -v brew &> /dev/null; then
        echo "Installing XcodeGen via Homebrew..."
        brew install xcodegen
        echo "XcodeGen installed! Re-running setup..."
        xcodegen generate
        open VolumeManager.xcodeproj
    else
        echo "Homebrew not found. Please install Homebrew first:"
        echo "https://brew.sh"
    fi
fi