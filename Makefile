# AudioSentry Makefile

# Compiler and flags
SWIFT = swiftc
FRAMEWORKS = -framework Cocoa -framework CoreAudio -framework AVFoundation
OUTPUT = AudioSentry
SOURCES = VolumeManager/main.swift VolumeManager/AppDelegate.swift VolumeManager/PreferencesViewController.swift VolumeManager/PreferencesWindowController.swift

# Default target
all: build

# Build the application
build:
	@echo "Building AudioSentry..."
	$(SWIFT) -o $(OUTPUT) $(SOURCES) $(FRAMEWORKS)
	@echo "Build complete! Run with ./$(OUTPUT)"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -f $(OUTPUT)
	rm -rf $(OUTPUT).dSYM
	rm -rf AudioSentry.app
	@echo "Clean complete!"

# Run the application
run: build
	@echo "Starting AudioSentry..."
	./$(OUTPUT)

# Create an app bundle (for easier distribution)
app: build
	@echo "Creating AudioSentry app bundle..."
	mkdir -p AudioSentry.app/Contents/MacOS
	mkdir -p AudioSentry.app/Contents/Resources
	cp $(OUTPUT) AudioSentry.app/Contents/MacOS/
	echo '<?xml version="1.0" encoding="UTF-8"?>' > AudioSentry.app/Contents/Info.plist
	echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> AudioSentry.app/Contents/Info.plist
	echo '<plist version="1.0">' >> AudioSentry.app/Contents/Info.plist
	echo '<dict>' >> AudioSentry.app/Contents/Info.plist
	echo '    <key>CFBundleExecutable</key>' >> AudioSentry.app/Contents/Info.plist
	echo '    <string>AudioSentry</string>' >> AudioSentry.app/Contents/Info.plist
	echo '    <key>CFBundleIdentifier</key>' >> AudioSentry.app/Contents/Info.plist
	echo '    <string>com.github.audiosentry</string>' >> AudioSentry.app/Contents/Info.plist
	echo '    <key>CFBundleName</key>' >> AudioSentry.app/Contents/Info.plist
	echo '    <string>AudioSentry</string>' >> AudioSentry.app/Contents/Info.plist
	echo '    <key>CFBundleDisplayName</key>' >> AudioSentry.app/Contents/Info.plist
	echo '    <string>AudioSentry</string>' >> AudioSentry.app/Contents/Info.plist
	echo '    <key>CFBundleVersion</key>' >> AudioSentry.app/Contents/Info.plist
	echo '    <string>1.0</string>' >> AudioSentry.app/Contents/Info.plist
	echo '    <key>LSMinimumSystemVersion</key>' >> AudioSentry.app/Contents/Info.plist
	echo '    <string>10.15</string>' >> AudioSentry.app/Contents/Info.plist
	echo '    <key>LSUIElement</key>' >> AudioSentry.app/Contents/Info.plist
	echo '    <true/>' >> AudioSentry.app/Contents/Info.plist
	echo '    <key>CFBundleIconFile</key>' >> AudioSentry.app/Contents/Info.plist
	echo '    <string>AppIcon</string>' >> AudioSentry.app/Contents/Info.plist
	echo '</dict>' >> AudioSentry.app/Contents/Info.plist
	echo '</plist>' >> AudioSentry.app/Contents/Info.plist
	@echo "AudioSentry app bundle created at AudioSentry.app"
	@if [ -f "AppIcon.icns" ]; then \
		cp AppIcon.icns AudioSentry.app/Contents/Resources/; \
		echo "✅ Custom icon added to app bundle"; \
	else \
		echo "ℹ️  No AppIcon.icns found - add one to include custom icon"; \
	fi

# Install to Applications folder (requires sudo)
install: app
	@echo "Installing AudioSentry to /Applications..."
	sudo cp -R AudioSentry.app /Applications/
	@echo "AudioSentry installation complete!"

# Uninstall from Applications folder (requires sudo)
uninstall:
	@echo "Uninstalling AudioSentry from /Applications..."
	sudo rm -rf /Applications/AudioSentry.app
	@echo "AudioSentry uninstallation complete!"

.PHONY: all build clean run app install uninstall