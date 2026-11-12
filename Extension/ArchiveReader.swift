import Compression
import Foundation

enum ArchiveReader {
    static let maxEntries = 20_000
    static let maxDecompressedBytes = 32 * 1024 * 1024
    private static let maxCentralDirectoryBytes = 16 * 1024 * 1024
    private static let maxCompressedReadBytes = 64 * 1024 * 1024

    static func read(url: URL, format: ArchiveFormats.Format) -> DocumentLoadResult {
        let fileSize = resolvedFileSize(of: url)

        do {
            var warnings: [String] = []
            let entries: [ArchiveEntry]

            switch format {
            case .zip:
                let outcome = try readZipEntries(url: url, fileSize: fileSize)
                entries = outcome.entries
                if outcome.truncated {
                    warnings.append("压缩包较大，仅列出前 \(maxEntries) 项。")
                }
            case .tar:
                let outcome = try readTarEntries(url: url, fileSize: fileSize)
                entries = outcome.entries
                if outcome.truncated {
                    warnings.append("压缩包较大，仅列出前 \(maxEntries) 项。")
                }
            case .tarGzip:
                let outcome = try readTarGzipEntries(url: url)
                entries = outcome.entries
                if outcome.truncated {
                    warnings.append("压缩包较大，仅列出了部分内容。")
                }
            case .gzip:
                return readGzipInfo(url: url, fileSize: fileSize)
            }

            guard !entries.isEmpty else {
                return .failure(PreviewFailure(
                    url: url,
                    title: "压缩包是空的",
                    message: "没有找到可列出的文件条目。",
                    symbol: "doc.zipper"
                ))
            }

            let fileCount = entries.filter { !$0.isDirectory }.count
            let totalSize = entries.reduce(Int64(0)) { $0 + ($1.isDirectory ? 0 : $1.size) }
            let sizeText = ByteCountFormatter.string(
                fromByteCount: totalSize,
                countStyle: .file
            )

            return .structure(StructureDocument(
                url: url,
                formatName: format.displayName,
                symbolName: "doc.zipper",
                byteCount: fileSize,
                summary: "\(fileCount) 个文件 · \(sizeText)",
                nodes: buildNodes(from: entries),
                warnings: warnings
            ))
        } catch let failure as ArchiveFailure {
            return .failure(PreviewFailure(
                url: url,
                title: failure.title,
                message: failure.message,
                symbol: failure.symbol
            ))
        } catch {
            return .failure(PreviewFailure(
                url: url,
                title: "无法读取压缩包",
                message: error.localizedDescription,
                symbol: "doc.zipper"
            ))
        }
    }

    // MARK: - ZIP

    private static func readZipEntries(
        url: URL,
        fileSize: Int64
    ) throws -> (entries: [ArchiveEntry], truncated: Bool) {
        guard fileSize >= 22 else {
            throw ArchiveFailure(title: "无法读取压缩包", message: "文件太小，不是有效的 ZIP。", symbol: "doc.zipper")
        }

        let handle: FileHandle
        do {
            handle = try FileHandle(forReadingFrom: url)
        } catch {
            throw ArchiveFailure(title: "无法读取压缩包", message: "文件可能已被移动或没有读取权限。", symbol: "doc.zipper")
        }
        defer { try? handle.close() }

        let tailLength = Int(min(fileSize, 66_000))
        guard let tailData = readChunk(handle, offset: Int(fileSize) - tailLength, length: tailLength) else {
            throw ArchiveFailure(title: "无法读取压缩包", message: "读取文件尾部失败。", symbol: "doc.zipper")
        }
        let tail = [UInt8](tailData)

        guard let endOfCentralDirectory = lastIndex(
            of: 0x06054B50,
            in: tail
        ) else {
            throw ArchiveFailure(title: "不是有效的 ZIP", message: "没有找到 ZIP 目录结构。", symbol: "doc.zipper")
        }

        var totalEntries = Int(u16(tail, endOfCentralDirectory + 10))
        var directorySize = Int64(u32(tail, endOfCentralDirectory + 12))
        var directoryOffset = Int64(u32(tail, endOfCentralDirectory + 16))

        if totalEntries == 0xFFFF || directorySize == 0xFFFFFFFF || directoryOffset == 0xFFFFFFFF {
            let locatorIndex = endOfCentralDirectory - 20
            if locatorIndex >= 0, u32(tail, locatorIndex) == 0x07064B50 {
                let zip64Offset = Int64(u64(tail, locatorIndex + 8))
                if let zip64Data = readChunk(handle, offset: Int(zip64Offset), length: 56) {
                    let zip64 = [UInt8](zip64Data)
                    if zip64.count >= 56, u32(zip64, 0) == 0x06064B50 {
                        totalEntries = Int(u64(zip64, 32))
                        directorySize = Int64(u64(zip64, 40))
                        directoryOffset = Int64(u64(zip64, 48))
                    }
                }
            }
        }

        if totalEntries == 0, directorySize == 0 {
            return ([], false)
        }

        guard directoryOffset >= 0, directorySize > 0 else {
            throw ArchiveFailure(title: "不是有效的 ZIP", message: "ZIP 目录偏移无效。", symbol: "doc.zipper")
        }

        let readableSize = Int(min(directorySize, Int64(maxCentralDirectoryBytes)))
        guard let directoryData = readChunk(
            handle,
            offset: Int(directoryOffset),
            length: readableSize
        ) else {
            throw ArchiveFailure(title: "无法读取压缩包", message: "读取 ZIP 目录失败。", symbol: "doc.zipper")
        }
        let directory = [UInt8](directoryData)

        var entries: [ArchiveEntry] = []
        var index = 0
        var truncated = directorySize > Int64(readableSize)

        while index + 46 <= directory.count {
            guard u32(directory, index) == 0x02014B50 else { break }

            let flags = u16(directory, index + 8)
            let compressedSize32 = u32(directory, index + 20)
            let uncompressedSize32 = u32(directory, index + 24)
            let nameLength = Int(u16(directory, index + 28))
            let extraLength = Int(u16(directory, index + 30))
            let commentLength = Int(u16(directory, index + 32))
            let recordEnd = index + 46 + nameLength + extraLength + commentLength

            guard recordEnd <= directory.count else {
                truncated = true
                break
            }

            let nameBytes = Array(directory[(index + 46)..<(index + 46 + nameLength)])
            var size = Int64(uncompressedSize32)

            if uncompressedSize32 == 0xFFFFFFFF || compressedSize32 == 0xFFFFFFFF {
                let extraStart = index + 46 + nameLength
                var cursor = extraStart
                let extraEnd = extraStart + extraLength
                while cursor + 4 <= extraEnd {
                    let fieldID = u16(directory, cursor)
                    let fieldLength = Int(u16(directory, cursor + 2))
                    cursor += 4
                    if fieldID == 0x0001 {
                        var pointer = cursor
                        if uncompressedSize32 == 0xFFFFFFFF, pointer + 8 <= cursor + fieldLength {
                            size = Int64(u64(directory, pointer))
                            pointer += 8
                        }
                        break
                    }
                    cursor += fieldLength
                }
            }

            let name = decodeName(nameBytes, isUTF8: flags & 0x0800 != 0)
            if !name.isEmpty {
                let isDirectory = name.hasSuffix("/")
                entries.append(ArchiveEntry(
                    path: name,
                    isDirectory: isDirectory,
                    size: isDirectory ? 0 : size
                ))
            }

            if entries.count >= maxEntries {
                truncated = true
                break
            }
            index = recordEnd
        }

        if entries.isEmpty {
            throw ArchiveFailure(title: "不是有效的 ZIP", message: "ZIP 目录中没有任何条目。", symbol: "doc.zipper")
        }
        if totalEntries > entries.count {
            truncated = true
        }
        return (entries, truncated)
    }

    // MARK: - TAR

    private static func readTarEntries(
        url: URL,
        fileSize: Int64
    ) throws -> (entries: [ArchiveEntry], truncated: Bool) {
        let handle: FileHandle
        do {
            handle = try FileHandle(forReadingFrom: url)
        } catch {
            throw ArchiveFailure(title: "无法读取压缩包", message: "文件可能已被移动或没有读取权限。", symbol: "doc.zipper")
        }
        defer { try? handle.close() }

        let result = parseTar(
            totalSize: Int(fileSize),
            maxEntries: maxEntries
        ) { offset, length in
            readChunk(handle, offset: offset, length: length)
        }

        guard !result.entries.isEmpty else {
            throw ArchiveFailure(title: "不是有效的 TAR", message: "没有解析到 TAR 条目。", symbol: "doc.zipper")
        }
        return result
    }

    private static func readTarGzipEntries(
        url: URL
    ) throws -> (entries: [ArchiveEntry], truncated: Bool) {
        let handle: FileHandle
        do {
            handle = try FileHandle(forReadingFrom: url)
        } catch {
            throw ArchiveFailure(title: "无法读取压缩包", message: "文件可能已被移动或没有读取权限。", symbol: "doc.zipper")
        }
        defer { try? handle.close() }

        guard let compressed = try? handle.read(upToCount: maxCompressedReadBytes),
              !compressed.isEmpty else {
            throw ArchiveFailure(title: "无法读取压缩包", message: "读取压缩数据失败。", symbol: "doc.zipper")
        }

        let decompressed = try gunzipPrefix(compressed, limit: maxDecompressedBytes)
        var result = parseTar(
            totalSize: decompressed.data.count,
            maxEntries: maxEntries
        ) { offset, length in
            guard offset >= 0, length > 0, offset + length <= decompressed.data.count else {
                return nil
            }
            return decompressed.data.subdata(in: offset..<(offset + length))
        }
        if decompressed.truncated {
            result.truncated = true
        }

        guard !result.entries.isEmpty else {
            throw ArchiveFailure(title: "不是有效的 TAR.GZ", message: "没有解析到 TAR 条目。", symbol: "doc.zipper")
        }
        return result
    }

    private static func parseTar(
        totalSize: Int,
        maxEntries: Int,
        read: (Int, Int) -> Data?
    ) -> (entries: [ArchiveEntry], truncated: Bool) {
        var entries: [ArchiveEntry] = []
        var offset = 0
        var pendingName: String?
        var truncated = false

        while offset + 512 <= totalSize {
            guard let headerData = read(offset, 512), headerData.count == 512 else {
                truncated = true
                break
            }
            let header = [UInt8](headerData)
            if header.allSatisfy({ $0 == 0 }) {
                break
            }
            guard isValidTarHeader(header) else {
                break
            }

            let rawName = cString(header, 0, 100)
            let prefix = cString(header, 345, 155)
            let size = tarSize(header)
            guard size >= 0, size <= Int64(totalSize) else {
                truncated = true
                break
            }
            let type = header[156]
            let dataOffset = offset + 512
            let dataBlocks = Int((size + 511) / 512) * 512

            switch type {
            case 76:
                if let data = read(dataOffset, Int(size)) {
                    pendingName = cString([UInt8](data), 0, data.count)
                }
            case 120:
                if let data = read(dataOffset, Int(size)) {
                    pendingName = paxPath(data) ?? pendingName
                }
            case 75, 86:
                break
            case 103:
                break
            default:
                var name = pendingName ?? rawName
                if pendingName == nil, !prefix.isEmpty {
                    name = prefix + "/" + rawName
                }
                pendingName = nil

                if !name.isEmpty {
                    let isDirectory = type == 53 || name.hasSuffix("/")
                    entries.append(ArchiveEntry(
                        path: name,
                        isDirectory: isDirectory,
                        size: isDirectory ? 0 : size
                    ))
                    if entries.count >= maxEntries {
                        truncated = true
                        break
                    }
                }
            }

            offset = dataOffset + dataBlocks
        }

        return (entries, truncated)
    }

    // MARK: - GZIP

    private static func readGzipInfo(url: URL, fileSize: Int64) -> DocumentLoadResult {
        guard let handle = try? FileHandle(forReadingFrom: url) else {
            return .failure(PreviewFailure(
                url: url,
                title: "无法读取文件",
                message: "文件可能已被移动或没有读取权限。",
                symbol: "doc.zipper"
            ))
        }
        defer { try? handle.close() }

        guard let headData = readChunk(handle, offset: 0, length: 4096),
              let header = try? gzipHeader([UInt8](headData)) else {
            return .failure(PreviewFailure(
                url: url,
                title: "不是有效的 GZIP",
                message: "gzip 文件头无效。",
                symbol: "doc.zipper"
            ))
        }

        var uncompressedSize: Int64 = 0
        if fileSize >= 4,
           let tailData = readChunk(handle, offset: Int(fileSize) - 4, length: 4) {
            uncompressedSize = Int64(u32([UInt8](tailData), 0))
        }

        let name = header.name ?? url.deletingPathExtension().lastPathComponent
        let sizeText = ByteCountFormatter.string(
            fromByteCount: uncompressedSize,
            countStyle: .file
        )
        return .structure(StructureDocument(
            url: url,
            formatName: ArchiveFormats.Format.gzip.displayName,
            symbolName: "doc.zipper",
            byteCount: fileSize,
            summary: "单个压缩文件 · 解压后 \(sizeText)",
            nodes: [
                StructureNode(
                    title: name,
                    detail: sizeText,
                    symbolName: "doc"
                ),
            ],
            warnings: []
        ))
    }

    private static func gzipHeader(
        _ bytes: [UInt8]
    ) throws -> (payloadOffset: Int, name: String?) {
        guard bytes.count > 18, bytes[0] == 0x1F, bytes[1] == 0x8B else {
            throw ArchiveFailure(title: "不是有效的 GZIP", message: "gzip 文件头无效。", symbol: "doc.zipper")
        }

        let flags = bytes[3]
        var offset = 10
        if flags & 0x04 != 0 {
            guard offset + 2 <= bytes.count else {
                throw ArchiveFailure(title: "不是有效的 GZIP", message: "gzip 扩展头不完整。", symbol: "doc.zipper")
            }
            let extraLength = Int(bytes[offset]) | Int(bytes[offset + 1]) << 8
            offset += 2 + extraLength
        }

        var name: String?
        if flags & 0x08 != 0 {
            let start = offset
            while offset < bytes.count, bytes[offset] != 0 { offset += 1 }
            if offset > start {
                name = String(
                    bytes: bytes[start..<offset],
                    encoding: .isoLatin1
                )
            }
            offset += 1
        }
        if flags & 0x10 != 0 {
            while offset < bytes.count, bytes[offset] != 0 { offset += 1 }
            offset += 1
        }
        if flags & 0x02 != 0 {
            offset += 2
        }

        guard offset < bytes.count else {
            throw ArchiveFailure(title: "不是有效的 GZIP", message: "gzip 文件头不完整。", symbol: "doc.zipper")
        }
        return (offset, name)
    }

    private static func gunzipPrefix(
        _ data: Data,
        limit: Int
    ) throws -> (data: Data, truncated: Bool) {
        let bytes = [UInt8](data)
        let header = try gzipHeader(bytes)
        let payload = data.subdata(in: header.payloadOffset..<data.count)
        var output = Data(count: limit)
        let written = output.withUnsafeMutableBytes { destination in
            payload.withUnsafeBytes { source in
                compression_decode_buffer(
                    destination.bindMemory(to: UInt8.self).baseAddress!,
                    limit,
                    source.bindMemory(to: UInt8.self).baseAddress!,
                    payload.count,
                    nil,
                    COMPRESSION_ZLIB
                )
            }
        }

        guard written > 0 else {
            throw ArchiveFailure(title: "无法解压", message: "gzip 数据解压失败。", symbol: "doc.zipper")
        }
        return (Data(output.prefix(written)), written >= limit)
    }

    // MARK: - Tree

    private static func buildNodes(from entries: [ArchiveEntry]) -> [StructureNode] {
        let root = ArchiveNodeBuilder()

        for entry in entries {
            var path = entry.path.replacingOccurrences(of: "\\", with: "/")
            while path.hasPrefix("/") {
                path.removeFirst()
            }
            while path.hasPrefix("./") {
                path.removeFirst(2)
            }
            guard !path.isEmpty, path != "." else { continue }

            let components = path.split(separator: "/").map(String.init)
            guard !components.isEmpty else { continue }

            var node = root
            for component in components {
                if let existing = node.children[component] {
                    node = existing
                } else {
                    let child = ArchiveNodeBuilder()
                    node.children[component] = child
                    node = child
                }
            }

            if entry.isDirectory || path.hasSuffix("/") {
                node.isDirectory = true
            } else {
                node.size += entry.size
            }
        }

        return makeNodes(from: root)
    }

    private static func makeNodes(from builder: ArchiveNodeBuilder) -> [StructureNode] {
        let names = builder.children.keys.sorted { left, right in
            guard let leftNode = builder.children[left],
                  let rightNode = builder.children[right] else {
                return left.localizedStandardCompare(right) == .orderedAscending
            }
            let leftIsDirectory = leftNode.isDirectory || !leftNode.children.isEmpty
            let rightIsDirectory = rightNode.isDirectory || !rightNode.children.isEmpty
            if leftIsDirectory != rightIsDirectory {
                return leftIsDirectory
            }
            return left.localizedStandardCompare(right) == .orderedAscending
        }

        return names.map { name in
            let child = builder.children[name]!
            let children = makeNodes(from: child)
            let isDirectory = child.isDirectory || !children.isEmpty
            let size = totalSize(of: child)
            let detail: String
            if size > 0 {
                detail = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
            } else {
                detail = isDirectory ? "—" : "0 bytes"
            }
            return StructureNode(
                title: name,
                detail: detail,
                symbolName: symbolName(for: name, isDirectory: isDirectory),
                children: children
            )
        }
    }

    private static func totalSize(of builder: ArchiveNodeBuilder) -> Int64 {
        builder.size + builder.children.values.reduce(Int64(0)) { $0 + totalSize(of: $1) }
    }

    private static func symbolName(for name: String, isDirectory: Bool) -> String {
        if isDirectory {
            return "folder.fill"
        }
        switch (name as NSString).pathExtension.lowercased() {
        case "swift", "m", "mm", "c", "cc", "cpp", "h", "hpp", "go", "rs",
             "py", "js", "ts", "tsx", "jsx", "java", "kt", "rb", "php", "sh", "sql":
            return "chevron.left.forwardslash.chevron.right"
        case "png", "jpg", "jpeg", "gif", "heic", "webp", "svg", "icns", "tiff", "bmp":
            return "photo"
        case "zip", "jar", "war", "apk", "ipa", "tar", "gz", "tgz", "7z", "rar":
            return "doc.zipper"
        case "json", "jsonl", "yaml", "yml", "toml", "xml", "plist":
            return "curlybraces"
        case "md", "txt", "log":
            return "doc.text"
        default:
            return "doc"
        }
    }

    // MARK: - Helpers

    private struct ArchiveEntry {
        let path: String
        let isDirectory: Bool
        let size: Int64
    }

    private final class ArchiveNodeBuilder {
        var isDirectory = false
        var size: Int64 = 0
        var children: [String: ArchiveNodeBuilder] = [:]
    }

    private struct ArchiveFailure: Error {
        let title: String
        let message: String
        let symbol: String
    }

    private static func resolvedFileSize(of url: URL) -> Int64 {
        if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize,
           size > 0 {
            return Int64(size)
        }
        guard let handle = try? FileHandle(forReadingFrom: url) else {
            return 0
        }
        defer { try? handle.close() }
        return Int64((try? handle.seekToEnd()) ?? 0)
    }

    private static func readChunk(_ handle: FileHandle, offset: Int, length: Int) -> Data? {
        guard offset >= 0, length > 0 else { return nil }
        do {
            try handle.seek(toOffset: UInt64(offset))
            return try handle.read(upToCount: length)
        } catch {
            return nil
        }
    }

    private static func decodeName(_ bytes: [UInt8], isUTF8: Bool) -> String {
        if isUTF8 {
            return String(decoding: bytes, as: UTF8.self)
        }
        if let text = String(bytes: bytes, encoding: .utf8) {
            return text
        }
        return String(bytes: bytes, encoding: .isoLatin1) ?? ""
    }

    private static func cString(_ bytes: [UInt8], _ start: Int, _ length: Int) -> String {
        guard start >= 0, start < bytes.count else { return "" }
        let end = min(bytes.count, start + length)
        var slice = Array(bytes[start..<end])
        if let zero = slice.firstIndex(of: 0) {
            slice = Array(slice[..<zero])
        }
        return String(bytes: slice, encoding: .utf8) ?? ""
    }

    private static func isValidTarHeader(_ header: [UInt8]) -> Bool {
        guard header.count >= 512 else { return false }
        guard !cString(header, 0, 100).isEmpty else { return false }

        let checksumText = cString(header, 148, 8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let expected = Int(checksumText, radix: 8) else { return false }

        var unsignedSum = 0
        var signedSum = 0
        for index in 0..<512 {
            let byte: UInt8 = (148..<156).contains(index) ? 0x20 : header[index]
            unsignedSum += Int(byte)
            signedSum += Int(Int8(bitPattern: byte))
        }
        return expected == unsignedSum || expected == signedSum
    }

    private static func tarSize(_ header: [UInt8]) -> Int64 {
        guard header.count >= 136 else { return 0 }
        if header[124] & 0x80 != 0 {
            var value = Int64(header[124] & 0x7F)
            for index in 125..<136 {
                value = (value << 8) | Int64(header[index])
            }
            return value
        }
        let raw = cString(header, 124, 12)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Int64(raw, radix: 8) ?? 0
    }

    private static func paxPath(_ data: Data) -> String? {
        let bytes = [UInt8](data)
        var index = 0

        while index < bytes.count {
            var separator = index
            while separator < bytes.count, bytes[separator] != 0x20 {
                separator += 1
            }
            guard separator < bytes.count,
                  let length = Int(String(decoding: bytes[index..<separator], as: UTF8.self)),
                  length > 0 else {
                break
            }

            let end = min(index + length, bytes.count)
            let record = String(decoding: bytes[(separator + 1)..<end], as: UTF8.self)
            let line = record.trimmingCharacters(in: .newlines)
            if line.hasPrefix("path=") {
                return String(line.dropFirst(5))
            }
            index = end
        }
        return nil
    }

    private static func u16(_ bytes: [UInt8], _ index: Int) -> UInt16 {
        guard index >= 0, index + 1 < bytes.count else { return 0 }
        return UInt16(bytes[index]) | UInt16(bytes[index + 1]) << 8
    }

    private static func u32(_ bytes: [UInt8], _ index: Int) -> UInt32 {
        guard index >= 0, index + 3 < bytes.count else { return 0 }
        return UInt32(bytes[index])
            | UInt32(bytes[index + 1]) << 8
            | UInt32(bytes[index + 2]) << 16
            | UInt32(bytes[index + 3]) << 24
    }

    private static func u64(_ bytes: [UInt8], _ index: Int) -> UInt64 {
        guard index >= 0, index + 7 < bytes.count else { return 0 }
        var value: UInt64 = 0
        for offset in (0..<8).reversed() {
            value = (value << 8) | UInt64(bytes[index + offset])
        }
        return value
    }

    private static func lastIndex(of signature: UInt32, in bytes: [UInt8]) -> Int? {
        guard bytes.count >= 4 else { return nil }
        var index = bytes.count - 4
        while index >= 0 {
            if u32(bytes, index) == signature {
                return index
            }
            index -= 1
        }
        return nil
    }
}
