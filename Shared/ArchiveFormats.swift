import Foundation

enum ArchiveFormats {
    enum Format {
        case zip
        case tar
        case tarGzip
        case gzip

        var displayName: String {
            switch self {
            case .zip:
                return "ZIP"
            case .tar:
                return "TAR"
            case .tarGzip:
                return "TAR.GZ"
            case .gzip:
                return "GZIP"
            }
        }
    }

    static let zipExtensions: [String] = [
        "zip", "jar", "war", "ear", "aar", "apk", "aab", "ipa",
        "xpi", "vsix", "nupkg", "whl", "epub", "kmz", "sketch",
    ]

    static let databaseExtensions: [String] = [
        "sqlite", "sqlite3", "db", "sqlitedb",
    ]

    private static let zipExtensionSet = Set(zipExtensions)
    private static let databaseExtensionSet = Set(databaseExtensions)

    static func format(for url: URL) -> Format? {
        let name = url.lastPathComponent.lowercased()
        if name.hasSuffix(".tar.gz") || name.hasSuffix(".tgz") {
            return .tarGzip
        }

        let fileExtension = url.pathExtension.lowercased()
        if fileExtension == "tar" {
            return .tar
        }
        if zipExtensionSet.contains(fileExtension) {
            return .zip
        }
        if fileExtension == "gz" {
            return .gzip
        }
        return nil
    }

    static func isDatabaseCandidate(_ url: URL) -> Bool {
        databaseExtensionSet.contains(url.pathExtension.lowercased())
    }
}
