import Foundation

@objc(FilesData)
protocol FilesData {
    func fetchFiles(_ urls: [String],
                    withReply reply: @escaping ([File]) -> Void)
    func fetchDerivedData(withReply reply: @escaping ([File]) -> Void)
    func trashFiles(_ urls: [String],
                   withReply reply: @escaping () -> Void)
    func removeFiles(_ urls: [String],
                     withReply reply: @escaping () -> Void)
    func cleanAll(withReply reply: @escaping () -> Void)
}
