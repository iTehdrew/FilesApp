import Foundation

enum DerivedDataServiceError: Error {
    case cantLoadFile(url: URL)
}

final class FilesDataService: NSObject, FilesData {
    
    var files = [File]()
    
    func fetchFiles(_ urls: [String],
                    withReply reply: @escaping ([File]) -> Void) {
        
        for url in urls {
            if let url = URL(string: url) {
                loadFiles(at: url)
            }
        }
        reply(files)
    }
    
    func fetchDerivedData(withReply reply: @escaping ([File]) -> Void) {
        if let url = URL(string: "/Users/\(NSUserName())/Library/Developer/Xcode/DerivedData/") {
            loadFiles(at: url)
        }
        reply(files)
    }
    
    func trashFiles(_ urls: [String],
                   withReply reply: @escaping () -> Void) {
        
        for url in urls {
            try? FileManager.default.trashItem(at: URL(fileURLWithPath: url), resultingItemURL: nil)
            files.removeAll { $0.path == url }
        }
        reply()
    }
    
    func removeFiles(_ urls: [String],
                     withReply reply: @escaping () -> Void) {
        for url in urls {
            files.removeAll { $0.path == url }
        }
        reply()
    }
    
    func cleanAll(withReply reply: @escaping () -> Void) {
        files.removeAll()
        reply()
    }
}

// MARK: - Private methods
private extension FilesDataService {

    func loadFiles(at url: URL) {
        
        var loadedfiles = [File]()
        
        let attributes = [URLResourceKey.fileSizeKey,
                          URLResourceKey.nameKey,
                          URLResourceKey.pathKey]
        
        if let enumerator = FileManager.default.enumerator(at: url,
                                                           includingPropertiesForKeys: attributes,
                                                           options: [.skipsHiddenFiles],
                                                           errorHandler: { [weak self] url, error in
                                                            
                                                            try? self?.loadSingleFile(at: url)
                                                            return true
        }) {
            
            while let url = enumerator.nextObject() as? URL {
                do {
                    let resourceValue = try url.resourceValues(forKeys: Set(attributes))
                    
                    if let name = resourceValue.name,
                        let size = resourceValue.fileSize,
                        let path = resourceValue.path {
                        
                        let fileObject = File(name: name, size: size, path: path)
                        loadedfiles.append(fileObject)
                    }
                }
                catch {
                    print(error.localizedDescription)
                }
            }
        }
        files += loadedfiles.filter { !files.contains($0) }
        print("Files count: \(files.count)")
    }
    
    func loadSingleFile(at url: URL) throws {
        
        let attributes = try FileManager.default.attributesOfItem(atPath: String(describing: url.path))
        guard let size = attributes[FileAttributeKey.size] as? Int else {
            throw DerivedDataServiceError.cantLoadFile(url: url)
        }
        let fileObject = File(name: url.lastPathComponent,
                              size: size,
                              path: url.path)
        
        if !self.files.contains(fileObject) {
            self.files.append(fileObject)
        }
    }
}
