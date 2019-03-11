import Cocoa
import FilesDataService

protocol FilesAction: BasePresenter {
    func addFiles()
    func numberOfRows() -> Int
    func item(at row: Int) -> File
    func item(at indexSet: IndexSet) -> [File]
    func sortDescriptorsDidChange(in column: Column, ascending: Bool)
    func fetchFiles(from urls: [URL])
    func open(file: File)
    func removeFromList(items: [File])
    func removeToTrash(items: [File])
    func fetchDerivedData()
    func cleanList()
}

final class FilesPresenter {
    
    weak var view: FilesView!
    
    // MARK: - Properties
    private(set) var files = [File]()
    var proxyErrorHandler: ((Error) -> Void)?
    private(set) lazy var connection: NSXPCConnection = {
        let connection = NSXPCConnection(serviceName: "none.DerivedDataAppService")
        connection.remoteObjectInterface = NSXPCInterface(with: FilesData.self)
        connection.interruptionHandler = {
            // Handle interruption
        }
        connection.invalidationHandler = {
            // Handle invalidation
            self.view.updateProgressIndicator(isEnabled: false)
        }
        return connection
    }()

    // MARK: - Configure
    func configureView() {
        view.removeButton(isEnabled: !files.isEmpty)
        
        proxyErrorHandler = { [weak self] error in
            self?.view.updateProgressIndicator(isEnabled: false)
            self?.connection.suspend()
        }
    }
}

// MARK: - Private methods
private extension FilesPresenter {
    
    func connectionInterface(for selector: Selector, set: Set<AnyHashable>? = nil) -> NSXPCInterface {
        
        let interface = NSXPCInterface(with: FilesData.self)
        let set = NSSet().addingObjects(from: [NSArray.self, File.self, NSString.self, NSNumber.self])
        interface.setClasses(set,
                             for: selector,
                             argumentIndex: 0,
                             ofReply: true)
        return interface
    }
    
    func remoteObjectProxyService() -> FilesData {
        return connection.remoteObjectProxyWithErrorHandler { error in
            self.proxyErrorHandler?(error)
        } as! FilesData
    }
}

// MARK: - FilesAction
extension FilesPresenter: FilesAction {
    
    func addFiles() {
        
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.allowsMultipleSelection = true
        openPanel.canChooseDirectories = true
        
        openPanel.begin { [weak self] result in
            
            switch result {
            case .OK:
                self?.fetchFiles(from: openPanel.urls)
            default: ()
            }
        }
    }
    
    func numberOfRows() -> Int {
        return files.count
    }
    
    func item(at row: Int) -> File {
        return files[row]
    }
    
    func item(at indexSet: IndexSet) -> [File] {
        return indexSet.map { files[$0] }
    }
    
    func sortDescriptorsDidChange(in column: Column, ascending: Bool) {
        switch column {
        case .name:
            files.sort { ascending ? $0.name < $1.name : $0.name > $1.name }
        case .path:
            files.sort { ascending ? $0.path < $1.path : $0.path > $1.path }
        case .size:
            files.sort { ascending ? $0.size < $1.size : $0.size > $1.size }
        }
        view.reloadData()
    }
    
    func open(file: File) {
        _ = NSWorkspace.shared.openFile(file.path)
    }
    
    // MARK: - XPC methods
    func fetchFiles(from urls: [URL]) {
        
        connection.remoteObjectInterface = connectionInterface(for:
            #selector(FilesData.fetchFiles(_:withReply:)))
        
        let service = remoteObjectProxyService()
        connection.resume()
        
        let urls: [String] = urls.map { String(describing: $0) }
        self.view.updateProgressIndicator(isEnabled: true)
        service.fetchFiles(urls, withReply: { [weak self] file in
            self?.files = file
            self?.view.reloadData()
            self?.view.updateProgressIndicator(isEnabled: false)
            self?.connection.suspend()
        })
    }
    
    func removeFromList(items: [File]) {
        
        let service = remoteObjectProxyService()
        connection.resume()
        
        self.view.updateProgressIndicator(isEnabled: true)
        let urls: [String] = items.map { String(describing: $0.path) }
        service.removeFiles(urls) { [weak self] in
            
            guard let self = self else {
                return
            }
            
            self.view.deselectRows()
            items.forEach { item in
                
                if let index = self.files.firstIndex(of: item) {
                    self.view.removeRow(at: IndexSet(integer: index))
                }
                self.files.removeAll { $0 == item }
            }
            self.view.reloadData()
            self.view.updateProgressIndicator(isEnabled: false)
            self.view.removeButton(isEnabled: !self.files.isEmpty)
            self.connection.suspend()
        }
    }
    
    func removeToTrash(items: [File]) {

        let service = remoteObjectProxyService()
        connection.resume()
        
        self.view.updateProgressIndicator(isEnabled: true)
        
        let urls: [String] = items.map { String(describing: $0.path) }
        service.trashFiles(urls) { [weak self] in
            self?.view.updateProgressIndicator(isEnabled: false)
            self?.connection.suspend()
            self?.view.deselectRows()
            items.forEach { item in
                if let index = self?.files.firstIndex(of: item) {
                    self?.view.removeRow(at: IndexSet(integer: index))
                }
                self?.files.removeAll { $0 == item }
            }
        }
        
    }
    
    func fetchDerivedData() {
        
        cleanList()
        connection.remoteObjectInterface = connectionInterface(for:
            #selector(FilesData.fetchDerivedData(withReply:)))
        let service = remoteObjectProxyService()
        
        self.view.updateProgressIndicator(isEnabled: true)
        service.fetchDerivedData { [weak self] files in
            self?.files = files
            self?.view.reloadData()
            self?.view.updateProgressIndicator(isEnabled: false)
            self?.connection.suspend()
        }
    }
    
    func cleanList() {
        let service = remoteObjectProxyService()
        connection.resume()
        service.cleanAll { [weak self] in
            
            guard let self = self else {
                return
            }
            
            self.files.removeAll()
            self.view.reloadData()
            self.view.removeButton(isEnabled: !self.files.isEmpty)
            self.connection.suspend()
        }
    }
}
