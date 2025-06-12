import Cocoa

class PreferencesViewController: NSViewController {
    weak var appDelegate: AppDelegate?
    
    // UI outlets for programmatically created interface
    var availableDevicesTableView: NSTableView!
    var trackedDevicesTableView: NSTableView!
    var activityLogTableView: NSTableView!
    
    // Data sources
    var availableDevices: [String] = []
    var trackedDeviceStates: [String: Bool] = [:]
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        appDelegate = NSApp.delegate as? AppDelegate
        
        // Create the UI programmatically
        setupUI()
        
        // Initial data load
        refreshAvailableDevices()  
        updateTrackedDeviceStates()
        refreshActivityLog()
        
        // Set up timer to update status every 5 seconds for live updates
        // Use longer interval to avoid interfering with main app logic
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.refreshAvailableDevices()
            self?.updateTrackedDeviceStates()
            self?.refreshActivityLog()
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        refreshAvailableDevices()
        updateTrackedDeviceStates()
    }
    
    func setupUI() {
        let containerView = view
        containerView.frame = NSRect(x: 0, y: 0, width: 800, height: 600)
        
        // Available devices section
        let availableLabel = NSTextField(labelWithString: "Available Audio Devices:")
        availableLabel.font = NSFont.boldSystemFont(ofSize: 13)
        availableLabel.frame = NSRect(x: 20, y: 550, width: 250, height: 20)
        containerView.addSubview(availableLabel)
        
        // Available devices table (NO status icons here)
        let availableScrollView = NSScrollView(frame: NSRect(x: 20, y: 390, width: 350, height: 150))
        availableDevicesTableView = NSTableView()
        let availableColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("AvailableDevice"))
        availableColumn.title = "Device Name"
        availableColumn.width = 330
        availableDevicesTableView.addTableColumn(availableColumn)
        availableDevicesTableView.delegate = self
        availableDevicesTableView.dataSource = self
        availableDevicesTableView.doubleAction = #selector(addSelectedDevice)
        availableDevicesTableView.target = self
        availableScrollView.documentView = availableDevicesTableView
        availableScrollView.hasVerticalScroller = true
        availableScrollView.borderType = .bezelBorder
        containerView.addSubview(availableScrollView)
        
        // Helper text for available devices
        let availableHelpLabel = NSTextField(labelWithString: "Double-click to add device to tracking →")
        availableHelpLabel.font = NSFont.systemFont(ofSize: 11)
        availableHelpLabel.frame = NSRect(x: 20, y: 365, width: 350, height: 20)
        availableHelpLabel.textColor = .secondaryLabelColor
        availableHelpLabel.alignment = .center
        containerView.addSubview(availableHelpLabel)
        
        // Tracked devices section
        let trackedLabel = NSTextField(labelWithString: "Tracked Devices:")
        trackedLabel.font = NSFont.boldSystemFont(ofSize: 13)
        trackedLabel.frame = NSRect(x: 430, y: 550, width: 250, height: 20)
        containerView.addSubview(trackedLabel)
        
        // Tracked devices table (WITH status icons and volume controls)
        let trackedScrollView = NSScrollView(frame: NSRect(x: 430, y: 390, width: 350, height: 150))
        trackedDevicesTableView = NSTableView()
        
        // Device Name column
        let trackedColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("TrackedDevice"))
        trackedColumn.title = "Device Name"
        trackedColumn.width = 200
        trackedDevicesTableView.addTableColumn(trackedColumn)
        
        // Volume column
        let volumeColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("VolumeControl"))
        volumeColumn.title = "Volume"
        volumeColumn.width = 140
        trackedDevicesTableView.addTableColumn(volumeColumn)
        
        trackedDevicesTableView.delegate = self
        trackedDevicesTableView.dataSource = self
        trackedDevicesTableView.doubleAction = #selector(removeSelectedDevice)
        trackedDevicesTableView.target = self
        trackedScrollView.documentView = trackedDevicesTableView
        trackedScrollView.hasVerticalScroller = true
        trackedScrollView.borderType = .bezelBorder
        containerView.addSubview(trackedScrollView)
        
        // Helper text for tracked devices
        let trackedHelpLabel = NSTextField(labelWithString: "← Double-click to remove device from tracking")
        trackedHelpLabel.font = NSFont.systemFont(ofSize: 11)
        trackedHelpLabel.frame = NSRect(x: 430, y: 365, width: 350, height: 20)
        trackedHelpLabel.textColor = .secondaryLabelColor
        trackedHelpLabel.alignment = .center
        containerView.addSubview(trackedHelpLabel)
        

        
        // Activity log section
        let activityLabel = NSTextField(labelWithString: "Recent Activity:")
        activityLabel.font = NSFont.boldSystemFont(ofSize: 13)
        activityLabel.frame = NSRect(x: 20, y: 310, width: 250, height: 20)
        containerView.addSubview(activityLabel)
        
        // Activity log table
        let activityScrollView = NSScrollView(frame: NSRect(x: 20, y: 50, width: 760, height: 250))
        activityLogTableView = NSTableView()
        let activityColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("ActivityLog"))
        activityColumn.title = "Device Activity"
        activityColumn.width = 740
        activityLogTableView.addTableColumn(activityColumn)
        activityLogTableView.delegate = self
        activityLogTableView.dataSource = self
        activityScrollView.documentView = activityLogTableView
        activityScrollView.hasVerticalScroller = true
        activityScrollView.borderType = .bezelBorder
        containerView.addSubview(activityScrollView)
        
        // Instructions
        let instructionsLabel = NSTextField(labelWithString: "How it works: When tracked devices disconnect, volume is muted. When they reconnect, volume is set to each device's custom level.\nTip: Double-click devices to move them between lists. Use +/− buttons to adjust volume in 5% increments for each device.")
        instructionsLabel.font = NSFont.systemFont(ofSize: 11)
        instructionsLabel.frame = NSRect(x: 20, y: 10, width: 760, height: 35)
        instructionsLabel.isEditable = false
        instructionsLabel.isBordered = false
        instructionsLabel.backgroundColor = .clear
        instructionsLabel.textColor = .secondaryLabelColor
        containerView.addSubview(instructionsLabel)
    }
    
    func refreshAvailableDevices() {
        guard let appDelegate = appDelegate else { return }
        
        // Get all connected devices, but exclude devices that are already being tracked
        let allConnectedDevices = appDelegate.getConnectedAudioDevices()
        
        // Filter out devices that are already in the tracked list
        availableDevices = allConnectedDevices.filter { connectedDevice in
            !appDelegate.targetDevices.contains { trackedDevice in
                // Check if this connected device matches any tracked device
                connectedDevice.localizedCaseInsensitiveContains(trackedDevice) ||
                trackedDevice.localizedCaseInsensitiveContains(connectedDevice)
            }
        }
        
        DispatchQueue.main.async {
            self.availableDevicesTableView?.reloadData()
        }
    }
    
    func updateTrackedDeviceStates() {
        guard let appDelegate = appDelegate else { return }
        
        let connectedDevices = appDelegate.getConnectedAudioDevices()
        
        // Update tracked device states
        for trackedDevice in appDelegate.targetDevices {
            let isConnected = connectedDevices.contains { deviceName in
                deviceName.localizedCaseInsensitiveContains(trackedDevice)
            }
            trackedDeviceStates[trackedDevice] = isConnected
        }
        
        DispatchQueue.main.async {
            self.trackedDevicesTableView?.reloadData()
        }
    }
    
    @objc func addSelectedDevice() {
        guard let appDelegate = appDelegate else { return }
        
        let selectedRow = availableDevicesTableView?.selectedRow ?? -1
        
        if selectedRow >= 0 && selectedRow < availableDevices.count {
            let selectedDevice = availableDevices[selectedRow]
            
            // Don't add if already tracked
            if !appDelegate.targetDevices.contains(selectedDevice) {
                appDelegate.targetDevices.append(selectedDevice)
                
                // Set default volume of 50% for new device if not already set
                if appDelegate.deviceVolumeSettings[selectedDevice] == nil {
                    appDelegate.deviceVolumeSettings[selectedDevice] = 0.5
                }
                
                appDelegate.savePreferences()
                
                // Refresh both lists
                refreshAvailableDevices()
                updateTrackedDeviceStates()
            }
        }
    }
    
    @objc func removeSelectedDevice() {
        guard let appDelegate = appDelegate else { return }
        
        let selectedRow = trackedDevicesTableView?.selectedRow ?? -1
        
        if selectedRow >= 0 && selectedRow < appDelegate.targetDevices.count {
            let deviceToRemove = appDelegate.targetDevices[selectedRow]
            appDelegate.targetDevices.remove(at: selectedRow)
            trackedDeviceStates.removeValue(forKey: deviceToRemove)
            // Also remove volume setting for this device
            appDelegate.deviceVolumeSettings.removeValue(forKey: deviceToRemove)
            appDelegate.savePreferences()
            
            // Refresh both lists
            refreshAvailableDevices()
            updateTrackedDeviceStates()
        }
    }
    
    @objc func volumeDecreaseClicked(_ sender: NSButton) {
        guard let appDelegate = appDelegate else { return }
        
        let row = sender.tag
        if row >= 0 && row < appDelegate.targetDevices.count {
            let deviceName = appDelegate.targetDevices[row]
            let currentVolume = appDelegate.getVolumeForDevice(deviceName)
            let currentPercentage = Int(currentVolume * 100)
            
            // Decrease by 5%, minimum 0%, rounded to nearest 5%
            let newPercentage = max(0, ((currentPercentage - 5) / 5) * 5)
            let newVolume = Float(newPercentage) / 100.0
            
            // Update only the stored setting (don't apply immediately)
            appDelegate.deviceVolumeSettings[deviceName] = newVolume
            appDelegate.savePreferences()
            
            // Update the percentage label
            if let cell = sender.superview as? NSTableCellView,
               let label = cell.subviews.first(where: { $0 is NSTextField }) as? NSTextField {
                label.stringValue = "\(newPercentage)%"
            }
        }
    }
    
    @objc func volumeIncreaseClicked(_ sender: NSButton) {
        guard let appDelegate = appDelegate else { return }
        
        let row = sender.tag
        if row >= 0 && row < appDelegate.targetDevices.count {
            let deviceName = appDelegate.targetDevices[row]
            let currentVolume = appDelegate.getVolumeForDevice(deviceName)
            let currentPercentage = Int(currentVolume * 100)
            
            // Increase by 5%, maximum 100%, rounded to nearest 5%
            let newPercentage = min(100, ((currentPercentage + 5) / 5) * 5)
            let newVolume = Float(newPercentage) / 100.0
            
            // Update only the stored setting (don't apply immediately)
            appDelegate.deviceVolumeSettings[deviceName] = newVolume
            appDelegate.savePreferences()
            
            // Update the percentage label
            if let cell = sender.superview as? NSTableCellView,
               let label = cell.subviews.first(where: { $0 is NSTextField }) as? NSTextField {
                label.stringValue = "\(newPercentage)%"
            }
        }
    }
    

    

    
    func refreshActivityLog() {
        DispatchQueue.main.async {
            self.activityLogTableView?.reloadData()
        }
    }
}

// MARK: - NSTableViewDataSource
extension PreferencesViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == availableDevicesTableView {
            return availableDevices.count
        } else if tableView == trackedDevicesTableView {
            return appDelegate?.targetDevices.count ?? 0
        } else if tableView == activityLogTableView {
            return appDelegate?.activityLog.count ?? 0
        }
        return 0
    }
}

// MARK: - NSTableViewDelegate
extension PreferencesViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        if tableView == availableDevicesTableView {
            // Available devices table - NO status icons, just device names
            let cellIdentifier = NSUserInterfaceItemIdentifier("AvailableDeviceCell")
            
            let cell: NSTableCellView
            if let recycledCell = tableView.makeView(withIdentifier: cellIdentifier, owner: nil) as? NSTableCellView {
                cell = recycledCell
            } else {
                cell = NSTableCellView()
                cell.identifier = cellIdentifier
                
                let textField = NSTextField()
                textField.isBordered = false
                textField.backgroundColor = .clear
                textField.isEditable = false
                textField.font = NSFont.systemFont(ofSize: 13)
                textField.translatesAutoresizingMaskIntoConstraints = false
                
                cell.addSubview(textField)
                cell.textField = textField
                
                NSLayoutConstraint.activate([
                    textField.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 5),
                    textField.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -5),
                    textField.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
                ])
            }
            
            if row < availableDevices.count {
                cell.textField?.stringValue = availableDevices[row]
                cell.textField?.textColor = .labelColor
            }
            
            return cell
            
        } else if tableView == trackedDevicesTableView {
            // Tracked devices table - WITH live status icons and volume controls
            if tableColumn?.identifier == NSUserInterfaceItemIdentifier("TrackedDevice") {
                // Device name column
                let cellIdentifier = NSUserInterfaceItemIdentifier("TrackedDeviceCell")
                
                let cell: NSTableCellView
                if let recycledCell = tableView.makeView(withIdentifier: cellIdentifier, owner: nil) as? NSTableCellView {
                    cell = recycledCell
                } else {
                    cell = NSTableCellView()
                    cell.identifier = cellIdentifier
                    
                    let textField = NSTextField()
                    textField.isBordered = false
                    textField.backgroundColor = .clear
                    textField.isEditable = false
                    textField.font = NSFont.systemFont(ofSize: 13)
                    textField.translatesAutoresizingMaskIntoConstraints = false
                    
                    cell.addSubview(textField)
                    cell.textField = textField
                    
                    NSLayoutConstraint.activate([
                        textField.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 5),
                        textField.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -5),
                        textField.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
                    ])
                }
                
                if let devices = appDelegate?.targetDevices, row < devices.count {
                    let deviceName = devices[row]
                    let isConnected = trackedDeviceStates[deviceName] ?? false
                    
                    // Show live status with green/red icons
                    let statusIcon = isConnected ? "🟢" : "🔴"
                    let statusText = isConnected ? "Connected" : "Disconnected"
                    
                    cell.textField?.stringValue = "\(statusIcon) \(deviceName) - \(statusText)"
                    cell.textField?.textColor = isConnected ? .systemGreen : .systemOrange
                }
                
                return cell
                
            } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier("VolumeControl") {
                // Volume control column with +/- buttons
                let cellIdentifier = NSUserInterfaceItemIdentifier("VolumeControlCell")
                
                let cell: NSTableCellView
                if let recycledCell = tableView.makeView(withIdentifier: cellIdentifier, owner: nil) as? NSTableCellView {
                    cell = recycledCell
                } else {
                    cell = NSTableCellView()
                    cell.identifier = cellIdentifier
                    
                    // Minus button
                    let minusButton = NSButton()
                    minusButton.title = "−"
                    minusButton.bezelStyle = .circular
                    minusButton.font = NSFont.systemFont(ofSize: 14)
                    minusButton.translatesAutoresizingMaskIntoConstraints = false
                    minusButton.action = #selector(volumeDecreaseClicked(_:))
                    minusButton.target = self
                    
                    // Volume label
                    let volumeLabel = NSTextField()
                    volumeLabel.isBordered = false
                    volumeLabel.backgroundColor = .clear
                    volumeLabel.isEditable = false
                    volumeLabel.font = NSFont.systemFont(ofSize: 13)
                    volumeLabel.translatesAutoresizingMaskIntoConstraints = false
                    volumeLabel.alignment = .center
                    
                    // Plus button
                    let plusButton = NSButton()
                    plusButton.title = "+"
                    plusButton.bezelStyle = .circular
                    plusButton.font = NSFont.systemFont(ofSize: 14)
                    plusButton.translatesAutoresizingMaskIntoConstraints = false
                    plusButton.action = #selector(volumeIncreaseClicked(_:))
                    plusButton.target = self
                    
                    cell.addSubview(minusButton)
                    cell.addSubview(volumeLabel)
                    cell.addSubview(plusButton)
                    
                    NSLayoutConstraint.activate([
                        // Minus button
                        minusButton.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 6),
                        minusButton.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
                        minusButton.widthAnchor.constraint(equalToConstant: 24),
                        minusButton.heightAnchor.constraint(equalToConstant: 20),
                        
                        // Volume label
                        volumeLabel.leadingAnchor.constraint(equalTo: minusButton.trailingAnchor, constant: 6),
                        volumeLabel.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
                        volumeLabel.widthAnchor.constraint(equalToConstant: 45),
                        
                        // Plus button
                        plusButton.leadingAnchor.constraint(equalTo: volumeLabel.trailingAnchor, constant: 6),
                        plusButton.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
                        plusButton.widthAnchor.constraint(equalToConstant: 24),
                        plusButton.heightAnchor.constraint(equalToConstant: 20),
                        plusButton.trailingAnchor.constraint(lessThanOrEqualTo: cell.trailingAnchor, constant: -8)
                    ])
                }
                
                if let devices = appDelegate?.targetDevices, row < devices.count {
                    let deviceName = devices[row]
                    // Get volume directly from deviceVolumeSettings to avoid excessive function calls
                    let volume = appDelegate?.deviceVolumeSettings[deviceName] ?? 0.5
                    
                    // Find buttons and label in the cell
                    if let minusButton = cell.subviews.first(where: { ($0 as? NSButton)?.title == "−" }) as? NSButton,
                       let plusButton = cell.subviews.first(where: { ($0 as? NSButton)?.title == "+" }) as? NSButton,
                       let volumeLabel = cell.subviews.first(where: { $0 is NSTextField }) as? NSTextField {
                        
                        // Store row index for identification
                        minusButton.tag = row
                        plusButton.tag = row
                        volumeLabel.tag = row
                        
                        // Update display
                        volumeLabel.stringValue = "\(Int(volume * 100))%"
                    }
                }
                
                return cell
            }
            
        } else if tableView == activityLogTableView {
            // Activity log table view
            let cellIdentifier = NSUserInterfaceItemIdentifier("ActivityCell")
            
            let cell: NSTableCellView
            if let recycledCell = tableView.makeView(withIdentifier: cellIdentifier, owner: nil) as? NSTableCellView {
                cell = recycledCell
            } else {
                cell = NSTableCellView()
                cell.identifier = cellIdentifier
                
                let textField = NSTextField()
                textField.isBordered = false
                textField.backgroundColor = .clear
                textField.isEditable = false
                textField.font = NSFont.systemFont(ofSize: 12)
                textField.translatesAutoresizingMaskIntoConstraints = false
                
                cell.addSubview(textField)
                cell.textField = textField
                
                NSLayoutConstraint.activate([
                    textField.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 5),
                    textField.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -5),
                    textField.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
                ])
            }
            
            if let activities = appDelegate?.activityLog, row < activities.count {
                let activity = activities[row]
                let formatter = DateFormatter()
                formatter.dateStyle = .none
                formatter.timeStyle = .short
                let timeString = formatter.string(from: activity.timestamp)
                
                let statusIcon = activity.event == "Connected" ? "🟢" : "🔴"
                cell.textField?.stringValue = "\(statusIcon) \(activity.deviceName) - \(activity.event) at \(timeString)"
                
                // Color code the events
                if activity.event == "Connected" {
                    cell.textField?.textColor = .systemGreen
                } else if activity.event == "Disconnected" {
                    cell.textField?.textColor = .systemOrange
                } else {
                    cell.textField?.textColor = .labelColor
                }
            }
            
            return cell
        }
        
        return nil
    }
    

}