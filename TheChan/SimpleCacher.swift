import Alamofire
import Foundation

class SimpleCacher {
    // MARK: Public

    public func getSizeOfDirectory(for category: String) -> UInt64 {
        let url = getDirectory(for: category)
        return fileManager.allocatedSizeOfDirectory(atUrl: url)
    }

    public func clearCache(for category: String) {
        let folderPath = getDirectory(for: category)
        guard let paths = try? fileManager.contentsOfDirectory(atPath: folderPath.path) else { return }
        for path in paths {
            try? fileManager.removeItem(atPath: "\(folderPath.path)/\(path)")
        }
    }

    // MARK: Internal

    func getFile(from url: URL, category: String = "genericCache", completionHandler: @escaping (URL?) -> Void) {
        var urlHash = url.absoluteString.sha256()
        urlHash
            .removeSubrange(
                (urlHash.index(urlHash.startIndex, offsetBy: 12)) ..< urlHash
                    .endIndex
            ) // leave first 11 characters

        let ext = url.pathExtension
        let dir = getDirectory(for: category)
        if !fileManager.fileExists(atPath: dir.path) {
            do {
                try fileManager.createDirectory(atPath: dir.path, withIntermediateDirectories: false, attributes: nil)
            } catch {
                completionHandler(nil)
                return
            }
        }

        let filePath = dir.appendingPathComponent("\(urlHash).\(ext)")
        if fileManager.fileExists(atPath: filePath.path) {
            completionHandler(filePath)
            return
        }

        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            (filePath, [.removePreviousFile])
        }

        Alamofire
            .download(url, to: destination)
            .validate(statusCode: 200 ..< 300)
            .responseData { response in
                if response.error != nil {
                    completionHandler(nil)
                } else {
                    completionHandler(filePath)
                }
            }
    }

    // MARK: Private

    private let fileManager = FileManager.default

    private func getDirectory(for category: String) -> URL {
        let dest = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return dest.appendingPathComponent(category, isDirectory: false)
    }
}

public extension FileManager {
    /// This method calculates the accumulated size of a directory on the volume in bytes.
    ///
    /// As there's no simple way to get this information from the file system it has to crawl the entire hierarchy,
    /// accumulating the overall sum on the way. The resulting value is roughly equivalent with the amount of bytes
    /// that would become available on the volume if the directory would be deleted.
    ///
    /// - note: There are a couple of oddities that are not taken into account (like symbolic links, meta data of
    /// directories, hard links, ...).

    func allocatedSizeOfDirectory(atUrl url: URL) -> UInt64 {
        // We'll sum up content size here:
        var accumulatedSize: UInt64 = 0

        // prefetching some properties during traversal will speed up things a bit.

        let prefetchedProperties = [
            URLResourceKey.isRegularFileKey,
            URLResourceKey.fileAllocatedSizeKey,
            URLResourceKey.totalFileAllocatedSizeKey,
        ]

        // The error handler simply signals errors to outside code.
        var errorDidOccur: Error?
        let errorHandler: (URL, Error) -> Bool = { _, error in
            errorDidOccur = error
            return false
        }

        // We have to enumerate all directory contents, including subdirectories.
        let enumerator = enumerator(
            at: url,
            includingPropertiesForKeys: prefetchedProperties,
            options: FileManager.DirectoryEnumerationOptions(rawValue: 0),
            errorHandler: errorHandler
        )

        // Start the traversal:
        while let contentURL = (enumerator?.nextObject() as? URL) {
            // Bail out on errors from the errorHandler.
            guard errorDidOccur == nil else { continue }

            // Get the type of this item, making sure we only sum up sizes of regular files.
            guard let resourceValues = try? contentURL.resourceValues(forKeys: Set(prefetchedProperties)) else {
                continue
            }

            guard resourceValues.isRegularFile ?? false else {
                continue
            }

            // To get the file's size we first try the most comprehensive value in terms of what the file may use on
            // disk.
            // This includes metadata, compression (on file system level) and block size.
            var fileSize = resourceValues.fileSize

            // In case the value is unavailable we use the fallback value (excluding meta data and compression)
            // This value should always be available.
            fileSize = fileSize ?? resourceValues.totalFileAllocatedSize

            // We're good, add up the value.
            accumulatedSize += UInt64(fileSize ?? 0)
        }

        // We finally got it.
        return accumulatedSize
    }
}
