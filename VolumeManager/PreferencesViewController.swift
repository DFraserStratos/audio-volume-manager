import Cocoa

class PreferencesViewController: NSViewController {
    weak var appDelegate: AppDelegate?
    
    // UI outlets for programmatically created interface
    var statusLabel: NSTextField!
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
        updateStatus()
        refreshActivityLog()
        
        // Set up timer to update status every 1 second for live updates
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.refreshAvailableDevices()
            self.updateTrackedDeviceStates()
            self.updateStatus()
            self.refreshActivityLog()
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        refreshAvailableDevices()
        updateTrackedDeviceStates()
        updateStatus()
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
        
        // Tracked devices table (WITH status icons)
        let trackedScrollView = NSScrollView(frame: NSRect(x: 430, y: 390, width: 350, height: 150))
        trackedDevicesTableView = NSTableView()
        let trackedColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("TrackedDevice"))
        trackedColumn.title = "Device Name"
        trackedColumn.width = 330
        trackedDevicesTableView.addTableColumn(trackedColumn)
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
        
        // Status section
        statusLabel = NSTextField(labelWithString: "Status: Loading...")
        statusLabel.font = NSFont.systemFont(ofSize: 12)
        statusLabel.frame = NSRect(x: 20, y: 350, width: 760, height: 20)
        statusLabel.isEditable = false
        statusLabel.isBordered = false
        statusLabel.backgroundColor = .clear
        containerView.addSubview(statusLabel)
        
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
        let instructionsLabel = NSTextField(labelWithString: "How it works: When tracked devices disconnect, volume is muted. When they reconnect, volume is set to 50%.\nTip: Double-click devices to move them between lists.")
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
                appDelegate.savePreferences()
                
                // Refresh both lists
                refreshAvailableDevices()
                updateTrackedDeviceStates()
                updateStatus()
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
            appDelegate.savePreferences()
            
            // Refresh both lists
            refreshAvailableDevices()
            updateTrackedDeviceStates()
            updateStatus()
        }
    }
    
    func updateStatus() {
        guard let appDelegate = appDelegate else { return }
        
        let connectedDevices = appDelegate.getConnectedAudioDevices()
        let trackedCount = appDelegate.targetDevices.count
        let connectedTrackedCount = appDelegate.targetDevices.filter { trackedDevice in
            connectedDevices.contains { deviceName in
                deviceName.localizedCaseInsensitiveContains(trackedDevice)
            }
        }.count
        
        DispatchQueue.main.async {
            if trackedCount == 0 {
                self.statusLabel.stringValue = "Status: No devices tracked"
                self.statusLabel.textColor = .secondaryLabelColor
            } else if connectedTrackedCount == 0 {
                self.statusLabel.stringValue = "Status: \(trackedCount) tracked, 0 connected (Volume Muted)"
                self.statusLabel.textColor = .systemOrange
            } else {
                self.statusLabel.stringValue = "Status: \(trackedCount) tracked, \(connectedTrackedCount) connected (Volume at 50%)"
                self.statusLabel.textColor = .systemGreen
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
            // Tracked devices table - WITH live status icons
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