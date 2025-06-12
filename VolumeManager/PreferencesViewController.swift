import Cocoa

class PreferencesViewController: NSViewController {
    weak var appDelegate: AppDelegate?
    
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var connectedDevicesLabel: NSTextField!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var addButton: NSButton!
    @IBOutlet weak var removeButton: NSButton!
    @IBOutlet weak var instructionsLabel: NSTextField!
    @IBOutlet weak var activityLogTableView: NSTableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        appDelegate = NSApp.delegate as? AppDelegate
        
        print("🔧 PreferencesViewController viewDidLoad() called")
        print("📊 activityLogTableView outlet: \(activityLogTableView)")
        
        // Configure table view for tracked devices
        tableView.delegate = self
        tableView.dataSource = self
        tableView.target = self
        tableView.doubleAction = #selector(tableViewDoubleClick)
        
        // Configure activity log table view
        if let activityLogTableView = activityLogTableView {
            print("✅ Activity log table view found, configuring...")
            activityLogTableView.delegate = self
            activityLogTableView.dataSource = self
        } else {
            print("❌ Activity log table view outlet not connected!")
        }
        
        // Update UI
        updateStatus()
        refreshActivityLog()
        
        // Set up timer to update status every 2 seconds (less frequent than before)
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            self.updateStatus()
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        updateStatus()
    }
    
    func updateStatus() {
        guard let appDelegate = appDelegate else { return }
        
        let connectedDevices = appDelegate.getConnectedAudioDevices()
        let matchingDevices = connectedDevices.filter { deviceName in
            appDelegate.targetDevices.contains { target in
                deviceName.localizedCaseInsensitiveContains(target)
            }
        }
        
        if matchingDevices.isEmpty {
            connectedDevicesLabel.stringValue = "Connected Devices: None"
            statusLabel.stringValue = "Status: Running (Volume Muted)"
            statusLabel.textColor = .systemOrange
        } else {
            connectedDevicesLabel.stringValue = "Connected Devices: \(matchingDevices.joined(separator: ", "))"
            statusLabel.stringValue = "Status: Running (Volume at 50%)"
            statusLabel.textColor = .systemGreen
        }
        
        // Update all connected devices list
        let allConnectedLabel = "All Audio Devices: \(connectedDevices.joined(separator: ", "))"
        instructionsLabel.stringValue = """
        Add device names to monitor. When these devices disconnect, volume will be muted. \
        When they reconnect, volume will be set to 50%.
        
        \(allConnectedLabel)
        """
    }
    
    @IBAction func addDevice(_ sender: Any) {
        let alert = NSAlert()
        alert.messageText = "Add Device"
        alert.informativeText = "Enter the name of the device to monitor:"
        alert.addButton(withTitle: "Add")
        alert.addButton(withTitle: "Cancel")
        
        let inputField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        inputField.placeholderString = "Device name (e.g., AirPods)"
        alert.accessoryView = inputField
        
        alert.beginSheetModal(for: view.window!) { response in
            if response == .alertFirstButtonReturn {
                let deviceName = inputField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
                if !deviceName.isEmpty && !self.appDelegate!.targetDevices.contains(deviceName) {
                    self.appDelegate?.targetDevices.append(deviceName)
                    self.tableView.reloadData()
                    self.appDelegate?.savePreferences()
                    self.updateStatus()
                }
            }
        }
    }
    
    @IBAction func removeDevice(_ sender: Any) {
        let selectedRow = tableView.selectedRow
        if selectedRow >= 0 && selectedRow < appDelegate!.targetDevices.count {
            appDelegate?.targetDevices.remove(at: selectedRow)
            tableView.reloadData()
            appDelegate?.savePreferences()
            updateStatus()
        }
    }
    
    @objc func tableViewDoubleClick() {
        // Optional: Allow editing on double-click
        let selectedRow = tableView.selectedRow
        if selectedRow >= 0 {
            // Could implement inline editing here
        }
    }
    
    func refreshActivityLog() {
        print("🔄 refreshActivityLog() called")
        print("📊 Activity log count: \(appDelegate?.activityLog.count ?? 0)")
        if let activities = appDelegate?.activityLog {
            for (index, activity) in activities.enumerated() {
                print("📝 Activity \(index): \(activity.deviceName) - \(activity.event) at \(activity.timestamp)")
            }
        }
        
        DispatchQueue.main.async {
            if let tableView = self.activityLogTableView {
                print("✅ Reloading activity log table view")
                tableView.reloadData()
            } else {
                print("❌ Activity log table view is nil, cannot reload")
            }
        }
    }
}

// MARK: - NSTableViewDataSource
extension PreferencesViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == self.tableView {
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
        if tableView == self.tableView {
            // Tracked devices table view
            let cellIdentifier = NSUserInterfaceItemIdentifier("DeviceCell")
            
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
                cell.textField?.stringValue = devices[row]
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
                
                cell.textField?.stringValue = "\(activity.deviceName) - \(activity.event) at \(timeString)"
                
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
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        if let tableView = notification.object as? NSTableView, tableView == self.tableView {
            removeButton.isEnabled = tableView.selectedRow >= 0
        }
    }
}