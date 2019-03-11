import Cocoa

@objc(File)
final class File: NSObject, NSSecureCoding {
    
    let name: String
    let size: Int
    let path: String
    
    var stringSize: String {
        return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }
    
    init(name: String, size: Int, path: String) {
        self.name = name
        self.size = size
        self.path = path
    }
    
    // MARK: - NSCoding
    required init?(coder aDecoder: NSCoder) {
        
        guard let name = aDecoder.decodeObject(forKey: "name") as? String,
            let size = aDecoder.decodeObject(forKey: "size") as? Int,
            let path = aDecoder.decodeObject(forKey: "path") as? String else {
                fatalError("Could not deserialise name!")
        }
        
        self.name = name
        self.size = size
        self.path = path
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: "name")
        aCoder.encode(size, forKey: "size")
        aCoder.encode(path, forKey: "path")
    }
    
    // MARK: - NSSecureCoding
    static var supportsSecureCoding: Bool = true

    // MARK: - Custom equitable logic
    override func isEqual(_ object: Any?) -> Bool {
        return name == (object as? File)?.name &&
            size == (object as? File)?.size &&
            path == (object as? File)?.path
    }
}
