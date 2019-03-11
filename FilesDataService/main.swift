import Foundation

let delegate = FilesDataServiceDelegate()
let listener = NSXPCListener.service()
listener.delegate = delegate
listener.resume()
