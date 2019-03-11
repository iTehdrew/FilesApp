import Cocoa

enum Column: String {
    case name
    case path
    case size
    
    var columIdentifier: NSUserInterfaceItemIdentifier {
        return NSUserInterfaceItemIdentifier(self.rawValue)
    }
    
    var title: String {
        switch self {
        case .name:
            return NSLocalizedString("list_column_name", comment: "")
        case .path:
            return NSLocalizedString("list_column_path", comment: "")
        case .size:
            return NSLocalizedString("list_column_size", comment: "")
        }
    }
    
    var sortDescriptor: NSSortDescriptor {
        switch self {
        case .name:
            return NSSortDescriptor(key: Column.name.rawValue, ascending: true)
        case .path:
            return NSSortDescriptor(key: Column.path.rawValue, ascending: true)
        case .size:
            return NSSortDescriptor(key: Column.size.rawValue, ascending: true)
        }
    }
}
