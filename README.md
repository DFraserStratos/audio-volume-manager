# AudioSentry

A lightweight macOS app that automatically manages system volume based on audio device connections. The app monitors your selected audio devices and automatically adjusts volume when they connect or disconnect - perfect for seamless transitions between headphones, speakers, and other audio devices.

## Features

### Core Functionality
- 🎧 **Smart Device Monitoring**: Track any audio devices you choose (AirPods, Zone Vibe, etc.)
- 🔇 **Auto-Mute**: Automatically muts volume when all tracked devices disconnect
- 🔊 **Custom Volume Control**: Set individual volume levels for each tracked device
- 📊 **Background Operation**: Runs efficiently in the background as a menu bar app
- 🖥️ **Menu Bar Integration**: Clean headphones icon in your menu bar for easy access

### User Interface
- ⚙️ **Preferences Window**: Easy-to-use GUI to manage monitored devices
- 📱 **Device Discovery**: Shows all connected audio devices for easy selection
- ➕ **Add/Remove Devices**: Double-click to move devices between available and tracked lists
- 🎚️ **Volume Controls**: Individual volume sliders for each tracked device
- 📊 **Live Status**: Real-time connection status indicators for each device

### Smart Features
- 💾 **Persistent Settings**: Saves your device list and volume preferences between launches
- 📋 **Activity Log**: Shows recent device connect/disconnect events with timestamps
- 🔄 **Single Instance**: Automatically prevents multiple instances from running
- 🎯 **Smart Matching**: Flexible device name matching (partial names work)
- ⚡ **Quick Updates**: Real-time status updates every few seconds

### Visual Feedback
- 🟢 **Green Icon**: When tracked devices are connected
- 🔴 **Red Icon**: When all tracked devices are disconnected
- ⚪ **White Icon**: Default state
- 🔔 **Status Updates**: Clear visual indicators in preferences window

## Installation & Usage

### Quick Start

1. **Download or Build**:
   ```bash
   git clone https://github.com/DFraserStratos/audio-volume-manager.git
   cd audio-volume-manager
   make app
   ```

2. **Run the App**:
   - Double-click `AudioSentry.app` in Finder, or
   - Install to Applications: `make install` (requires sudo)

3. **Setup Your Devices**:
   - Click the headphones icon in your menu bar
   - Select "Preferences"
   - Double-click devices from the left list to add them to tracking
   - Adjust volume levels for each device using the +/- buttons
   - Close preferences - the app will remember your settings

### How It Works

The app continuously monitors your audio devices. When a tracked device:
- **Connects**: Volume is set to that device's custom level
- **Disconnects**: Volume is muted (if no other tracked devices are connected)

You can track multiple devices simultaneously, and each can have its own volume level.

## Building

### Requirements
- macOS 10.15 or later
- Xcode Command Line Tools (`xcode-select --install`)

### Build Commands
```bash
make build          # Build the executable
make run           # Build and run the app
make app           # Create .app bundle (double-clickable)
make install       # Install to /Applications (requires sudo)
make clean         # Clean build artifacts
make uninstall     # Remove from /Applications (requires sudo)
```

### Creating a Clickable App

The `make app` command creates `AudioSentry.app` - a proper macOS application bundle that you can:
- Double-click to launch
- Copy to `/Applications` 
- Add to your Dock
- Set to launch at login

## Auto-Start at Login

1. Run `make install` to copy the app to `/Applications`
2. Open **System Settings** → **Users & Groups** → **Login Items**
3. Click the **+** button
4. Navigate to `/Applications` and select **AudioSentry.app**
5. Click **Add**

## Customization

### Through the GUI
- Use the Preferences window to add/remove devices
- Adjust volume levels with the +/- buttons (5% increments)
- View recent activity in the activity log

### Manual Configuration
Edit `VolumeManager/AppDelegate.swift` to change:
- Default volume increments
- Activity log size
- Update intervals

## Architecture

Clean, modern AppKit architecture:
- **main.swift**: App entry point with singleton enforcement
- **AppDelegate.swift**: Core logic, audio monitoring, volume control
- **PreferencesViewController.swift**: Full-featured preferences UI
- **PreferencesWindowController.swift**: Window management

## Recent Improvements

This project has been refined to be:
- ✅ **Build-tool agnostic**: No Xcode required - just `make app`
- ✅ **User-friendly**: Complete GUI for all configuration
- ✅ **Reliable**: Robust device detection and singleton management
- ✅ **Modern**: Clean AppKit implementation with proper separation of concerns
- ✅ **Customizable**: Per-device volume settings and flexible device matching

## Troubleshooting

- **Permission Issues**: The app may request accessibility permissions on first run
- **Device Not Detected**: Try the exact device name from System Settings → Sound
- **Multiple Instances**: The app automatically prevents this, but you can manually quit existing instances

## License

MIT License - feel free to modify and distribute as needed.

## Contributing

Pull requests welcome! The codebase is clean and well-structured for easy contributions.

## Author

Created by DFraserStratos
