import Foundation

final class StructureNode {
    let title: String
    let detail: String
    let symbolName: String
    let children: [StructureNode]

    init(
        title: String,
        detail: String,
        symbolName: String,
        children: [StructureNode] = []
    ) {
        self.title = title
        self.detail = detail
        self.symbolName = symbolName
        self.children = children
    }

    var isExpandable: Bool {
        !children.isEmpty
    }
}

struct StructureDocument {
    let url: URL
    let formatName: String
    let symbolName: String
    let byteCount: Int64
    let summary: String
    let nodes: [StructureNode]
    let warnings: [String]
}
