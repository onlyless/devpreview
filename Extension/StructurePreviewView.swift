import AppKit

final class StructurePreviewView: NSView {
    private let scrollView = NSScrollView(frame: .zero)
    private let outlineView = NSOutlineView(frame: .zero)
    private let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Structure"))
    private var roots: [StructureNode] = []

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func display(_ structure: StructureDocument) {
        roots = structure.nodes
        outlineView.reloadData()
        outlineView.frame = NSRect(
            x: 0,
            y: 0,
            width: max(scrollView.contentSize.width, 400),
            height: outlineView.frame.height
        )

        if roots.count <= 40 {
            for root in roots where root.isExpandable {
                outlineView.expandItem(root)
            }
        }

        scrollView.contentView.scroll(to: .zero)
        scrollView.reflectScrolledClipView(scrollView.contentView)
    }

    func clear() {
        roots = []
        outlineView.reloadData()
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.textBackgroundColor.setFill()
        bounds.fill()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
        outlineView.backgroundColor = .textBackgroundColor
        scrollView.backgroundColor = .textBackgroundColor
    }

    private func setup() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = true
        scrollView.backgroundColor = .textBackgroundColor
        scrollView.scrollerStyle = .overlay
        addSubview(scrollView)

        column.title = "结构"
        column.width = 600
        column.minWidth = 200
        column.resizingMask = .autoresizingMask

        outlineView.addTableColumn(column)
        outlineView.outlineTableColumn = column
        outlineView.headerView = nil
        outlineView.rowHeight = 24
        outlineView.intercellSpacing = NSSize(width: 0, height: 0)
        outlineView.indentationPerLevel = 15
        outlineView.autoresizesOutlineColumn = true
        outlineView.columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle
        outlineView.backgroundColor = .textBackgroundColor
        outlineView.usesAlternatingRowBackgroundColors = false
        outlineView.selectionHighlightStyle = .regular
        outlineView.allowsMultipleSelection = false
        outlineView.allowsEmptySelection = true
        outlineView.style = .sourceList
        outlineView.dataSource = self
        outlineView.delegate = self
        outlineView.autoresizingMask = [.width]

        scrollView.documentView = outlineView

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}

extension StructurePreviewView: NSOutlineViewDataSource {
    func outlineView(
        _ outlineView: NSOutlineView,
        numberOfChildrenOfItem item: Any?
    ) -> Int {
        if let node = item as? StructureNode {
            return node.children.count
        }
        return roots.count
    }

    func outlineView(
        _ outlineView: NSOutlineView,
        child index: Int,
        ofItem item: Any?
    ) -> Any {
        if let node = item as? StructureNode {
            return node.children[index]
        }
        return roots[index]
    }

    func outlineView(
        _ outlineView: NSOutlineView,
        isItemExpandable item: Any
    ) -> Bool {
        (item as? StructureNode)?.isExpandable ?? false
    }
}

extension StructurePreviewView: NSOutlineViewDelegate {
    func outlineView(
        _ outlineView: NSOutlineView,
        viewFor tableColumn: NSTableColumn?,
        item: Any
    ) -> NSView? {
        guard let node = item as? StructureNode else { return nil }

        let identifier = NSUserInterfaceItemIdentifier("StructureCell")
        let cell: StructureCellView
        if let reused = outlineView.makeView(
            withIdentifier: identifier,
            owner: self
        ) as? StructureCellView {
            cell = reused
        } else {
            cell = StructureCellView(frame: .zero)
            cell.identifier = identifier
        }
        cell.configure(with: node)
        return cell
    }
}

private final class StructureCellView: NSTableCellView {
    private let iconView = NSImageView(frame: .zero)
    private let titleLabel = NSTextField(labelWithString: "")
    private let detailLabel = NSTextField(labelWithString: "")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with node: StructureNode) {
        let configuration = NSImage.SymbolConfiguration(
            pointSize: 12,
            weight: .regular
        )
        iconView.image = NSImage(
            systemSymbolName: node.symbolName,
            accessibilityDescription: nil
        )?.withSymbolConfiguration(configuration)
        iconView.contentTintColor = node.isExpandable
            ? .secondaryLabelColor
            : .tertiaryLabelColor

        titleLabel.stringValue = node.title
        detailLabel.stringValue = node.detail
        detailLabel.isHidden = node.detail.isEmpty
        toolTip = node.detail.isEmpty
            ? node.title
            : "\(node.title)\n\(node.detail)"
    }

    private func setup() {
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .systemFont(ofSize: 12)
        titleLabel.textColor = .labelColor
        titleLabel.lineBreakMode = .byTruncatingMiddle
        titleLabel.maximumNumberOfLines = 1
        titleLabel.cell?.usesSingleLineMode = true
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        detailLabel.font = .monospacedDigitSystemFont(ofSize: 10.5, weight: .regular)
        detailLabel.textColor = .secondaryLabelColor
        detailLabel.alignment = .right
        detailLabel.lineBreakMode = .byTruncatingTail
        detailLabel.maximumNumberOfLines = 1
        detailLabel.cell?.usesSingleLineMode = true
        detailLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        detailLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        detailLabel.translatesAutoresizingMaskIntoConstraints = false

        [iconView, titleLabel, detailLabel].forEach(addSubview)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 15),
            iconView.heightAnchor.constraint(equalToConstant: 15),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 7),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            detailLabel.leadingAnchor.constraint(
                greaterThanOrEqualTo: titleLabel.trailingAnchor,
                constant: 12
            ),
            detailLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            detailLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
}
