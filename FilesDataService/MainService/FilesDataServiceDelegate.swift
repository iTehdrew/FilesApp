import Foundation

final class FilesDataServiceDelegate: NSObject, NSXPCListenerDelegate {
    
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        let exportedObject = FilesDataService()
        newConnection.exportedInterface = NSXPCInterface(with: FilesData.self)
        newConnection.exportedObject = exportedObject
        newConnection.resume()
        return true
    }
}
