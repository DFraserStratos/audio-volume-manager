import Cocoa
import CoreAudio
import AVFoundation

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var audioDeviceIDs: [AudioDeviceID] = []
    var targetDevices = ["AirPods", "Zone Vibe"]
    var isMonitoring = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBar()
        startMonitoring()
    }
    
    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "headphones", accessibilityDescription: "Volume Manager")
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Volume Manager Active", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(self)
    }
    
    func startMonitoring() {
        // Register for audio device notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioDeviceChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
        
        // Also monitor CoreAudio property changes
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        AudioObjectAddPropertyListener(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            audioPropertyListener,
            Unmanaged.passUnretained(self).toOpaque()
        )
        
        // Check current state
        checkAudioDevices()
    }
    
    @objc func handleAudioDeviceChange(_ notification: Notification) {
        checkAudioDevices()
    }
    
    func checkAudioDevices() {
        let connectedDevices = getConnectedAudioDevices()
        let hasTargetDevice = connectedDevices.contains { deviceName in
            targetDevices.contains { target in
                deviceName.localizedCaseInsensitiveContains(target)
            }
        }
        
        if hasTargetDevice {
            setSystemVolume(0.5) // 50%
            showNotification(title: "Headphones Connected", message: "Volume set to 50%")
        } else {
            setSystemVolume(0.0) // 0%
            showNotification(title: "Headphones Disconnected", message: "Volume muted")
        }
    }
    
    func getConnectedAudioDevices() -> [String] {
        var devices: [String] = []
        
        var propSize: UInt32 = 0
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &propSize
        )
        
        let deviceCount = Int(propSize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)
        
        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &propSize,
            &deviceIDs
        )
        
        for deviceID in deviceIDs {
            if let name = getDeviceName(deviceID: deviceID) {
                devices.append(name)
            }
        }
        
        return devices
    }
    
    func getDeviceName(deviceID: AudioDeviceID) -> String? {
        var name: CFString = "" as CFString
        var propSize = UInt32(MemoryLayout<CFString>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let result = AudioObjectGetPropertyData(
            deviceID,
            &address,
            0,
            nil,
            &propSize,
            &name
        )
        
        return result == noErr ? name as String : nil
    }
    
    func setSystemVolume(_ volume: Float) {
        var defaultOutputID = AudioDeviceID(0)
        var propSize = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &propSize,
            &defaultOutputID
        )
        
        var volumeToSet = volume
        address.mSelector = kAudioHardwareServiceDeviceProperty_VirtualMainVolume
        address.mScope = kAudioDevicePropertyScopeOutput
        
        AudioObjectSetPropertyData(
            defaultOutputID,
            &address,
            0,
            nil,
            UInt32(MemoryLayout<Float>.size),
            &volumeToSet
        )
    }
    
    func showNotification(title: String, message: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = message
        NSUserNotificationCenter.default.deliver(notification)
    }
}

// C callback function for CoreAudio
func audioPropertyListener(
    inObjectID: AudioObjectID,
    inNumberAddresses: UInt32,
    inAddresses: UnsafePointer<AudioObjectPropertyAddress>,
    inClientData: UnsafeMutableRawPointer?
) -> OSStatus {
    if let appDelegate = inClientData {
        let delegate = Unmanaged<AppDelegate>.fromOpaque(appDelegate).takeUnretainedValue()
        DispatchQueue.main.async {
            delegate.checkAudioDevices()
        }
    }
    return noErr
}