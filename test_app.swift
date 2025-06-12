import Cocoa
import Foundation

// Simple test app to debug menu bar issues
class TestApp: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Write to a log file so we can see what's happening
        let logMessage = "=== TEST APP STARTING ===\n"
        writeToLog(logMessage)
        
        setupMenuBar()
        
        writeToLog("=== TEST APP SETUP COMPLETE ===\n")
        
        // Keep the app running
        NSApp.setActivationPolicy(.accessory)
    }
    
    func setupMenuBar() {
        writeToLog("Creating status item...\n")
        
        statusItem = NSStatusBar.system.statusItem(withLength: 50)
        
        if let button = statusItem?.button {
            writeToLog("Status item button created successfully!\n")
            button.title = "TEST"
            button.font = NSFont.systemFont(ofSize: 16)
            
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Test Menu Item", action: nil, keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
            statusItem?.menu = menu
            
            writeToLog("Menu bar setup complete with title: \(button.title)\n")
        } else {
            writeToLog("ERROR: Could not create status item button!\n")
        }
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(self)
    }
    
    func writeToLog(_ message: String) {
        let logFile = "/tmp/volume_manager_debug.log"
        let timestamp = Date().description
        let logEntry = "[\(timestamp)] \(message)"
        
        if let data = logEntry.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logFile) {
                if let fileHandle = FileHandle(forWritingAtPath: logFile) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                FileManager.default.createFile(atPath: logFile, contents: data, attributes: nil)
            }
        }
    }
}

// Main execution
let app = NSApplication.shared
let delegate = TestApp()
app.delegate = delegate

// Write initial log
delegate.writeToLog("Starting test app...\n")

app.run() 