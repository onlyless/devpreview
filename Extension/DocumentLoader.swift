import AppKit
import CoreFoundation
import Foundation

struct PreviewDocument {
    let url: URL
    let text: String
    let attributedText: NSAttributedString
    let language: LanguageProfile
    let encodingName: String
    let byteCount: Int64
    let lineCount: Int
    let warnings: [String]
}

struct PreviewFailure {
    let url: URL
    let title: String
    let message: String
    let symbol: String
}

enum DocumentLoadResult {
    case document(PreviewDocument)
    case structure(StructureDocument)
    case failure(PreviewFailure)
}

enum DocumentLoader {
    static let maxPreviewBytes = 512 * 1024
    static let maxHighlightBytes = 256 * 1024
    private static let readChunkBytes = 64 * 1024

    private static var truncatedWarning: String {
        let limit = ByteCountFormatter.string(
            fromByteCount: Int64(maxPreviewBytes),
            countStyle: .binary
        )
        return "文件较大，仅显示前 \(limit)。"
    }

    static func load(url: URL) -> DocumentLoadResult {
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let values = try? url.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
        if values?.isDirectory == true {
            return .failure(PreviewFailure(
                url: url,
                title: "这是一个文件夹",
                message: "DevPreview 只能预览文本文件。",
                symbol: "folder"
            ))
        }

        let totalBytes = Int64(values?.fileSize ?? 0)

        if let archiveFormat = ArchiveFormats.format(for: url) {
            return ArchiveReader.read(url: url, format: archiveFormat)
        }

        if ArchiveFormats.isDatabaseCandidate(url),
           isSQLiteDatabase(at: url) {
            return SQLiteReader.read(url: url, fileSize: totalBytes)
        }

        guard let handle = try? FileHandle(forReadingFrom: url) else {
            return .failure(PreviewFailure(
                url: url,
                title: "无法读取文件",
                message: "文件可能已被移动、删除，或当前进程没有读取权限。",
                symbol: "lock.slash"
            ))
        }

        let rawData: Data
        do {
            rawData = try readPrefix(from: handle, limit: maxPreviewBytes)
            try? handle.close()
        } catch {
            return .failure(PreviewFailure(
                url: url,
                title: "读取失败",
                message: error.localizedDescription,
                symbol: "exclamationmark.triangle"
            ))
        }

        if rawData.isEmpty, totalBytes > 0 {
            return .failure(PreviewFailure(
                url: url,
                title: "读取失败",
                message: "文件大小不为零，但没有读到内容。请确认文件仍可访问。",
                symbol: "exclamationmark.triangle"
            ))
        }

        return makeDocument(
            url: url,
            rawData: rawData,
            totalBytes: totalBytes,
            truncated: rawData.count > maxPreviewBytes
        )
    }

    private static func readPrefix(from handle: FileHandle, limit: Int) throws -> Data {
        var data = Data()
        data.reserveCapacity(min(limit + 1, readChunkBytes * 2))

        while data.count <= limit {
            let remaining = limit + 1 - data.count
            guard let chunk = try handle.read(upToCount: min(readChunkBytes, remaining)),
                  !chunk.isEmpty else {
                break
            }
            data.append(chunk)
        }
        return data
    }

    private static func makeDocument(
        url: URL,
        rawData: Data,
        totalBytes: Int64,
        truncated: Bool
    ) -> DocumentLoadResult {
        var data = truncated ? Data(rawData.prefix(maxPreviewBytes)) : rawData
        var warnings: [String] = []
        var convertedPlist = false

        if url.pathExtension.lowercased() == "plist", isBinaryPlist(data) {
            guard let object = try? PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: nil
            ),
            let xmlData = try? PropertyListSerialization.data(
                fromPropertyList: object,
                format: .xml,
                options: 0
            ) else {
                return .failure(PreviewFailure(
                    url: url,
                    title: "无法解析 Property List",
                    message: "这是一个二进制 plist，但解析失败。文件可能不完整或已损坏。",
                    symbol: "exclamationmark.triangle"
                ))
            }
            data = xmlData
            convertedPlist = true
            if truncated {
                warnings.append(truncatedWarning)
            }
        }

        if !convertedPlist, isLikelyBinary(data) {
            return .failure(PreviewFailure(
                url: url,
                title: "无法预览二进制文件",
                message: "DevPreview 只显示文本内容。请使用对应的专用预览器打开此文件。",
                symbol: "doc.zipper"
            ))
        }

        guard let decoded = decode(data, truncated: truncated) else {
            return .failure(PreviewFailure(
                url: url,
                title: "无法识别文本编码",
                message: "文件既不是有效的 UTF-8 / UTF-16，也不像可读的文本。",
                symbol: "textformat.abc.dottedunderline"
            ))
        }

        var text = decoded.text
        if text.first == "\u{FEFF}" {
            text.removeFirst()
        }
        text = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        let language = resolvedLanguage(for: url, text: text)
        let lineCount = countLines(text)
        let highlightEnabled = text.utf8.count <= maxHighlightBytes

        if truncated, !warnings.contains(truncatedWarning) {
            warnings.append(truncatedWarning)
        }
        if !highlightEnabled, !text.isEmpty {
            warnings.append("文件较大，已关闭语法高亮。")
        }
        if convertedPlist {
            warnings.append("Binary plist 已转换为 XML 显示。")
        }

        let font = SyntaxHighlighter.makeFont()
        let paragraphStyle = SyntaxHighlighter.makeParagraphStyle(font: font)
        let attributedText = SyntaxHighlighter.highlight(
            text,
            language: language,
            font: font,
            paragraphStyle: paragraphStyle,
            enabled: highlightEnabled
        )

        return .document(PreviewDocument(
            url: url,
            text: text,
            attributedText: attributedText,
            language: language,
            encodingName: decoded.encodingName,
            byteCount: totalBytes > 0 ? totalBytes : Int64(data.count),
            lineCount: lineCount,
            warnings: warnings
        ))
    }

    private static func resolvedLanguage(for url: URL, text: String) -> LanguageProfile {
        let detected = LanguageCatalog.language(for: url)
        guard detected.id == "plain" else { return detected }

        let firstLine = text.split(
            separator: "\n",
            maxSplits: 1,
            omittingEmptySubsequences: false
        ).first

        if let firstLine,
           let shebangLanguage = LanguageCatalog.language(forShebang: String(firstLine)) {
            return shebangLanguage
        }
        return detected
    }

    private static func countLines(_ text: String) -> Int {
        guard !text.isEmpty else { return 0 }
        let source = text as NSString
        var count = 1
        var index = 0
        while index < source.length {
            if source.character(at: index) == 10 {
                count += 1
            }
            index += 1
        }
        return count
    }

    private static func isSQLiteDatabase(at url: URL) -> Bool {
        guard let handle = try? FileHandle(forReadingFrom: url) else {
            return false
        }
        defer { try? handle.close() }

        guard let header = try? handle.read(upToCount: 16),
              header.count == 16 else {
            return false
        }
        return header.elementsEqual("SQLite format 3\u{0}".utf8)
    }

    private static func isBinaryPlist(_ data: Data) -> Bool {
        starts(data, with: [0x62, 0x70, 0x6C, 0x69, 0x73, 0x74])
    }

    private static func isLikelyBinary(_ data: Data) -> Bool {
        guard !data.isEmpty else { return false }

        if starts(data, with: [0xEF, 0xBB, 0xBF]) ||
            starts(data, with: [0xFF, 0xFE]) ||
            starts(data, with: [0xFE, 0xFF]) ||
            starts(data, with: [0x00, 0x00, 0xFE, 0xFF]) {
            return false
        }

        let sample = data.prefix(4096)
        if sample.contains(0), !looksLikeUTF16(data) {
            return true
        }

        var controlBytes = 0
        for byte in sample {
            if byte < 0x09 || (byte > 0x0D && byte < 0x20) {
                controlBytes += 1
            }
        }
        return controlBytes > max(2, sample.count / 20)
    }

    private static func decode(
        _ data: Data,
        truncated: Bool
    ) -> (text: String, encodingName: String)? {
        if data.isEmpty {
            return ("", "UTF-8")
        }

        if starts(data, with: [0xEF, 0xBB, 0xBF]) {
            if let text = decodeUTF8(Data(data.dropFirst(3)), truncated: truncated) {
                return (text, "UTF-8")
            }
        }

        if starts(data, with: [0xFF, 0xFE, 0x00, 0x00]) {
            if let text = String(data: data.dropFirst(4), encoding: .utf32LittleEndian) {
                return (text, "UTF-32 LE")
            }
        }

        if starts(data, with: [0x00, 0x00, 0xFE, 0xFF]) {
            if let text = String(data: data.dropFirst(4), encoding: .utf32BigEndian) {
                return (text, "UTF-32 BE")
            }
        }

        if starts(data, with: [0xFF, 0xFE]) {
            if let text = String(data: data.dropFirst(2), encoding: .utf16LittleEndian) {
                return (text, "UTF-16 LE")
            }
        }

        if starts(data, with: [0xFE, 0xFF]) {
            if let text = String(data: data.dropFirst(2), encoding: .utf16BigEndian) {
                return (text, "UTF-16 BE")
            }
        }

        if let endianness = utf16Endianness(data) {
            let encoding: String.Encoding = endianness == .little ? .utf16LittleEndian : .utf16BigEndian
            if let text = String(data: data, encoding: encoding) {
                return (text, endianness == .little ? "UTF-16 LE" : "UTF-16 BE")
            }
        }

        if let text = decodeUTF8(data, truncated: truncated) {
            return (text, "UTF-8")
        }

        let gb18030 = String.Encoding(
            rawValue: CFStringConvertEncodingToNSStringEncoding(
                CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)
            )
        )
        if let text = String(data: data, encoding: gb18030), !text.contains("\u{FFFD}") {
            return (text, "GB18030")
        }

        if !data.prefix(4096).contains(0),
           let text = String(data: data, encoding: .isoLatin1) {
            return (text, "Latin-1")
        }

        if truncated {
            return (String(decoding: data, as: UTF8.self), "UTF-8")
        }

        return nil
    }

    private static func decodeUTF8(_ data: Data, truncated: Bool) -> String? {
        if let text = String(data: data, encoding: .utf8) {
            return text
        }

        guard truncated else { return nil }
        for trim in 1...3 where data.count > trim {
            if let text = String(data: Data(data.dropLast(trim)), encoding: .utf8) {
                return text
            }
        }
        return nil
    }

    private enum Endianness: Equatable {
        case little
        case big
    }

    private static func utf16Endianness(_ data: Data) -> Endianness? {
        let sample = data.prefix(4096)
        guard sample.count >= 4 else { return nil }

        var evenZeros = 0
        var oddZeros = 0
        var pairs = 0
        var index = 0

        while index + 1 < sample.count {
            let first = sample[sample.startIndex + index]
            let second = sample[sample.startIndex + index + 1]
            if first == 0 {
                evenZeros += 1
            }
            if second == 0 {
                oddZeros += 1
            }
            pairs += 1
            index += 2
        }

        guard pairs > 0 else { return nil }
        let threshold = max(2, pairs / 4)

        if oddZeros >= threshold, evenZeros < threshold {
            return .little
        }
        if evenZeros >= threshold, oddZeros < threshold {
            return .big
        }
        return nil
    }

    private static func looksLikeUTF16(_ data: Data) -> Bool {
        utf16Endianness(data) != nil
    }

    private static func starts(_ data: Data, with bytes: [UInt8]) -> Bool {
        guard data.count >= bytes.count else { return false }
        return data.prefix(bytes.count).elementsEqual(bytes)
    }
}
