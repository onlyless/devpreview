import Foundation

// DevPreview 示例：在 Finder 中按空格查看此文件
struct PreviewItem: Codable {
    let name: String
    let language: String
    let extensions: [String]

    var summary: String {
        "\(name) (\(language)): \(extensions.joined(separator: ", "))"
    }
}

enum PreviewError: Error {
    case unsupportedEncoding
    case fileTooLarge
}

@MainActor
final class PreviewStore {
    private(set) var items: [PreviewItem] = []

    func add(_ item: PreviewItem) {
        items.append(item)
    }

    func load(from url: URL) throws -> [PreviewItem] {
        let data = try Data(contentsOf: url)
        guard data.count < 8 * 1024 * 1024 else {
            throw PreviewError.fileTooLarge
        }
        return try JSONDecoder().decode([PreviewItem].self, from: data)
    }
}

let item = PreviewItem(
    name: "DevPreview",
    language: "Swift",
    extensions: ["swift", "md", "json"]
)
print(item.summary)
