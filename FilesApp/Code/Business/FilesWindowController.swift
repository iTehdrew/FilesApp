import Cocoa

final class FilesWindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
    
        window?.title = NSLocalizedString("window_title", comment: "")
    }
    
    @IBAction func openDocument(_ sender: AnyObject?) {
        
        let openPanel = NSOpenPanel()
        openPanel.showsHiddenFiles = false
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        
        openPanel.beginSheetModal(for: window!) { response in
            guard response == .OK else {
                return
            }
            self.contentViewController?.representedObject = openPanel.urls
        }
    }
}
