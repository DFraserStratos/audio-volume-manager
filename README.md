# Audio Volume Manager

A lightweight macOS app that automatically manages system volume based on audio device connections. When your AirPods or Logitech Zone Vibe headset disconnects, the volume is muted. When they reconnect, volume is set to 50%.

## Features

- 🎧 Monitors AirPods and Logitech Zone Vibe connections
- 🔇 Automatically mutes when headphones disconnect
- 🔊 Sets volume to 50% when headphones reconnect
- 📊 Runs efficiently in the background
- 🖥️ Menu bar icon for easy access
- 🔔 System notifications for volume changes

## Installation

### Option 1: Build from source

1. Clone this repository:
```bash
git clone https://github.com/DFraserStratos/audio-volume-manager.git
cd audio-volume-manager
```

2. Build the app:
```bash
make build
```

3. Run the app:
```bash
./VolumeManager
```

### Option 2: Download release

Download the latest release from the [Releases](https://github.com/DFraserStratos/audio-volume-manager/releases) page.

## Usage

1. Launch the app - you'll see a headphones icon in your menu bar
2. Connect/disconnect your AirPods or Logitech Zone Vibe
3. Volume will automatically adjust

To quit the app, click the menu bar icon and select "Quit".

## Auto-start at login

1. Open System Settings → Users & Groups → Login Items
2. Click the + button
3. Navigate to and select the VolumeManager app
4. Click Add

## Building

Requirements:
- macOS 10.15 or later
- Xcode Command Line Tools

Build command:
```bash
swiftc -o VolumeManager VolumeManager.swift -framework Cocoa -framework CoreAudio -framework AVFoundation
```

Or use the included Makefile:
```bash
make build
```

## Customization

To add more devices to monitor, edit the `targetDevices` array in `VolumeManager.swift`:

```swift
var targetDevices = ["AirPods", "Zone Vibe", "Your Device Name"]
```

To change volume levels, modify these lines:
```swift
setSystemVolume(0.5) // 50% when connected
setSystemVolume(0.0) // 0% when disconnected
```

## License

MIT License - feel free to modify and distribute as needed.

## Contributing

Pull requests are welcome! Please feel free to submit a PR if you'd like to add features or fix bugs.

## Known Issues

- Requires macOS 10.15 or later
- May need accessibility permissions on first run

## Author

Created by DFraserStratos