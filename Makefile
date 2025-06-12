# Audio Volume Manager Makefile

# Compiler and flags
SWIFT = swiftc
FRAMEWORKS = -framework Cocoa -framework CoreAudio -framework AVFoundation
OUTPUT = VolumeManagerApp
SOURCES = VolumeManager/main.swift VolumeManager/AppDelegate.swift VolumeManager/PreferencesViewController.swift VolumeManager/PreferencesWindowController.swift

# Default target
all: build

# Build the application
build:
	@echo "Building Volume Manager..."
	$(SWIFT) -o $(OUTPUT) $(SOURCES) $(FRAMEWORKS)
	@echo "Build complete! Run with ./$(OUTPUT)"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -f $(OUTPUT)
	rm -rf $(OUTPUT).dSYM
	@echo "Clean complete!"

# Run the application
run: build
	@echo "Starting Volume Manager..."
	./$(OUTPUT)

# Create an app bundle (for easier distribution)
app: build
	@echo "Creating app bundle..."
	mkdir -p VolumeManager.app/Contents/MacOS
	mkdir -p VolumeManager.app/Contents/Resources
	cp $(OUTPUT) VolumeManager.app/Contents/MacOS/
	echo '<?xml version="1.0" encoding="UTF-8"?>' > VolumeManager.app/Contents/Info.plist
	echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> VolumeManager.app/Contents/Info.plist
	echo '<plist version="1.0">' >> VolumeManager.app/Contents/Info.plist
	echo '<dict>' >> VolumeManager.app/Contents/Info.plist
	echo '    <key>CFBundleExecutable</key>' >> VolumeManager.app/Contents/Info.plist
	echo '    <string>VolumeManager</string>' >> VolumeManager.app/Contents/Info.plist
	echo '    <key>CFBundleIdentifier</key>' >> VolumeManager.app/Contents/Info.plist
	echo '    <string>com.github.audio-volume-manager</string>' >> VolumeManager.app/Contents/Info.plist
	echo '    <key>CFBundleName</key>' >> VolumeManager.app/Contents/Info.plist
	echo '    <string>Volume Manager</string>' >> VolumeManager.app/Contents/Info.plist
	echo '    <key>CFBundleVersion</key>' >> VolumeManager.app/Contents/Info.plist
	echo '    <string>1.0</string>' >> VolumeManager.app/Contents/Info.plist
	echo '    <key>LSMinimumSystemVersion</key>' >> VolumeManager.app/Contents/Info.plist
	echo '    <string>10.15</string>' >> VolumeManager.app/Contents/Info.plist
	echo '    <key>LSUIElement</key>' >> VolumeManager.app/Contents/Info.plist
	echo '    <true/>' >> VolumeManager.app/Contents/Info.plist
	echo '</dict>' >> VolumeManager.app/Contents/Info.plist
	echo '</plist>' >> VolumeManager.app/Contents/Info.plist
	@echo "App bundle created at VolumeManager.app"

# Install to Applications folder (requires sudo)
install: app
	@echo "Installing to /Applications..."
	sudo cp -R VolumeManager.app /Applications/
	@echo "Installation complete!"

# Uninstall from Applications folder (requires sudo)
uninstall:
	@echo "Uninstalling from /Applications..."
	sudo rm -rf /Applications/VolumeManager.app
	@echo "Uninstallation complete!"

.PHONY: all build clean run app install uninstall