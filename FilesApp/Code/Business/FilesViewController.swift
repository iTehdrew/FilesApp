import Cocoa

protocol FilesView: BaseView {
    func reloadData()
    func removeButton(isEnabled: Bool)
    func insertRow(at indexSet: IndexSet)
    func deselectRows()
    func removeRow(at indexSet: IndexSet)
    func updateProgressIndicator(isEnabled: Bool)
}


final class FilesViewController: NSViewController {
    
    // MARK: - IBOutlet
    @IBOutlet private(set) var tableView: NSTableView!
    @IBOutlet private(set) var addFileButton: NSButton!
    @IBOutlet private(set) var removeFileButton: NSButton!
    @IBOutlet private(set) var removeFilesFromListButton: NSButton!
    @IBOutlet private(set) var progressIndicator: NSProgressIndicator!
    @IBOutlet private(set) var cleanButton: NSButton!
    @IBOutlet private(set) var loadDerivedDataButton: NSButton!
    
    // MARK: - Properties
    var presenter: FilesAction!

    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        
        _ = FilesModule(viewController: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.doubleAction = #selector(tableViewDoubleClick(_:))
        
        for column in tableView.tableColumns {
            let identifier = Column(rawValue: column.identifier.rawValue)
            column.sortDescriptorPrototype = identifier?.sortDescriptor
        }
        
        removeFileButton.title = NSLocalizedString("move_to_trash_button", comment: "")
        loadDerivedDataButton.title = NSLocalizedString("load_derived_data_button", comment: "")
        cleanButton.title = NSLocalizedString("clean_list_button", comment: "")
        
        presenter.configureView()
    }
    
    override var representedObject: Any? {
        didSet {
            if let urls = representedObject as? [URL] {
                presenter.fetchFiles(from: urls)
            }
        }
    }
}

// MARK: - Private methods
private extension FilesViewController {
    
    func showRemoveAlert(completion: @escaping () -> Void) {
        let alert: NSAlert = NSAlert()
        alert.messageText = NSLocalizedString("alert_delete_title", comment: "")
        alert.informativeText = NSLocalizedString("alert_delete_description", comment: "")
        alert.addButton(withTitle: NSLocalizedString("alert_delete_button_delete", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("alert_delete_button_cancel", comment: ""))
        alert.alertStyle = NSAlert.Style.warning
        
        alert.beginSheetModal(for: view.window!) { response in
            if response == .alertFirstButtonReturn {
                completion()
            }
        }
    }
}

// MARK: - IBActions
private extension FilesViewController {
    
    @IBAction func openFiles(_ sender: NSButton) {
        presenter.addFiles()
    }
    
    @IBAction func removeFromList(_ sender: NSButton) {
        let items = presenter.item(at: tableView.selectedRowIndexes)
        presenter.removeFromList(items: items)
    }
    
    @IBAction func removeFile(_ sender: NSButton) {
        guard !tableView.selectedRowIndexes.isEmpty else {
            return
        }
        
        let items = presenter.item(at: tableView.selectedRowIndexes)
        
        showRemoveAlert { [weak self] in
            self?.presenter.removeToTrash(items: items)
        }
    }
    
    @IBAction func tableViewDoubleClick(_ sender: AnyObject) {
        guard !tableView.selectedRowIndexes.isEmpty else {
            return
        }
        
        let file = presenter.item(at: tableView.selectedRow)
        presenter.open(file: file)
    }
    
    @IBAction func getDerivedData(_ sender: NSButton) {
        presenter.fetchDerivedData()
    }
    
    @IBAction func cleanList(_ sender: NSButton) {
        presenter.cleanList()
    }
}

// MARK: - MainView
extension FilesViewController: FilesView {
    
    func reloadData() {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
    }
    
    func removeButton(isEnabled: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.removeFileButton.isEnabled = isEnabled
            self?.removeFilesFromListButton.isEnabled = isEnabled
            self?.cleanButton.isEnabled = isEnabled
            self?.tableView.isEnabled = isEnabled
        }
    }
    
    func insertRow(at indexSet: IndexSet) {
        tableView.insertRows(at: indexSet, withAnimation: [])
    }
    
    func removeRow(at indexSet: IndexSet) {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.removeRows(at: indexSet, withAnimation: .slideUp)
        }
    }
    
    func deselectRows() {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.deselectAll(self)
        }
    }
    
    func updateProgressIndicator(isEnabled: Bool) {
        DispatchQueue.main.async { [weak self] in
            
            guard let self = self else {
                return
            }
            
            self.removeFileButton.isEnabled = !isEnabled
            self.removeFilesFromListButton.isEnabled = !isEnabled
            self.addFileButton.isEnabled = !isEnabled
            self.cleanButton.isEnabled = !isEnabled
            self.tableView.isEnabled = !isEnabled
            self.loadDerivedDataButton.isEnabled = !isEnabled
            isEnabled ? self.progressIndicator.startAnimation(self) : self.progressIndicator.stopAnimation(self)
        }
    }
}

// MARK: - NSTableViewDataSource
extension FilesViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return presenter.numberOfRows()
    }
    
    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        guard let sortDescriptor = tableView.sortDescriptors.first,
            let key = sortDescriptor.key,
            let column = Column(rawValue: key) else {
                return
        }
        presenter.sortDescriptorsDidChange(in: column, ascending: sortDescriptor.ascending)
    }
}

// MARK: - NSTableViewDelegate
extension FilesViewController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        guard let identifier = tableColumn?.identifier.rawValue,
            let column = Column(rawValue: identifier),
            let cell = tableView.makeView(withIdentifier: column.columIdentifier,
                                          owner: nil) as? NSTableCellView else {
                                            return nil
        }
        
        let file = presenter.item(at: row)
        
        switch column {
        case .name:
            cell.textField?.stringValue = file.name
        case .size:
            cell.textField?.stringValue = file.stringSize
        case .path:
            cell.textField?.stringValue = file.path
        }
        
        return cell
    }
}
