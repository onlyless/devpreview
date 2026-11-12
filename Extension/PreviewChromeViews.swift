import AppKit

final class PreviewHeaderView: NSView {
    private let iconView = NSImageView(frame: .zero)
    private let nameLabel = NSTextField(labelWithString: "")
    private let metaLabel = NSTextField(labelWithString: "")
    private let brandLabel = NSTextField(labelWithString: "DEVPREVIEW")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with document: PreviewDocument) {
        iconView.image = symbolImage(for: document.language)
        nameLabel.stringValue = document.url.lastPathComponent

        let size = ByteCountFormatter.string(
            fromByteCount: document.byteCount,
            countStyle: .file
        )
        let lines = "\(document.lineCount.formatted()) 行"
        metaLabel.stringValue = [
            document.language.displayName,
            size,
            lines,
            document.encodingName,
        ].joined(separator: "  ·  ")

        setAccessibilityLabel("\(document.url.lastPathComponent)，\(document.language.displayName)")
    }

    func configure(with structure: StructureDocument) {
        iconView.image = symbolImage(named: structure.symbolName)
        nameLabel.stringValue = structure.url.lastPathComponent

        let size = ByteCountFormatter.string(
            fromByteCount: structure.byteCount,
            countStyle: .file
        )
        metaLabel.stringValue = [
            structure.formatName,
            size,
            structure.summary,
        ].joined(separator: "  ·  ")

        setAccessibilityLabel(
            "\(structure.url.lastPathComponent)，\(structure.formatName)"
        )
    }

    func configureLoading(for url: URL) {
        iconView.image = symbolImage(named: "doc.text")
        nameLabel.stringValue = url.lastPathComponent
        metaLabel.stringValue = "正在读取文件…"
    }

    func configureFailure(url: URL) {
        iconView.image = symbolImage(named: "doc.text")
        nameLabel.stringValue = url.lastPathComponent
        metaLabel.stringValue = "无法预览"
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.windowBackgroundColor.setFill()
        bounds.fill()

        NSColor.separatorColor.withAlphaComponent(0.55).setFill()
        NSRect(x: 0, y: 0, width: bounds.width, height: 1).fill()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }

    private func setup() {
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.contentTintColor = .controlAccentColor

        nameLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        nameLabel.lineBreakMode = .byTruncatingMiddle
        nameLabel.maximumNumberOfLines = 1
        nameLabel.cell?.usesSingleLineMode = true
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        metaLabel.font = .systemFont(ofSize: 10.5)
        metaLabel.textColor = .secondaryLabelColor
        metaLabel.lineBreakMode = .byTruncatingTail
        metaLabel.maximumNumberOfLines = 1
        metaLabel.cell?.usesSingleLineMode = true
        metaLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        brandLabel.font = .systemFont(ofSize: 9, weight: .semibold)
        brandLabel.textColor = .tertiaryLabelColor
        brandLabel.alignment = .right

        [iconView, nameLabel, metaLabel, brandLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),

            nameLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 9),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: brandLabel.leadingAnchor, constant: -12),

            metaLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            metaLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 1),
            metaLabel.trailingAnchor.constraint(lessThanOrEqualTo: brandLabel.leadingAnchor, constant: -12),

            brandLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            brandLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    private func symbolImage(for language: LanguageProfile) -> NSImage? {
        let symbol: String
        switch language.kind {
        case .code, .markup:
            symbol = "chevron.left.forwardslash.chevron.right"
        case .json:
            symbol = "curlybraces"
        case .yaml, .toml, .ini:
            symbol = "slider.horizontal.3"
        case .markdown:
            symbol = "text.alignleft"
        case .css:
            symbol = "paintbrush"
        case .diff:
            symbol = "plus.forwardslash.minus"
        case .makefile:
            symbol = "hammer"
        case .plain:
            symbol = "doc.text"
        }
        return symbolImage(named: symbol)
    }

    private func symbolImage(named name: String) -> NSImage? {
        let configuration = NSImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        return NSImage(
            systemSymbolName: name,
            accessibilityDescription: nil
        )?.withSymbolConfiguration(configuration)
    }
}

final class WarningBannerView: NSView {
    private let iconView = NSImageView(frame: .zero)
    private let label = NSTextField(labelWithString: "")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(_ message: String) {
        label.stringValue = message
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.systemOrange.withAlphaComponent(0.11).setFill()
        bounds.fill()

        NSColor.separatorColor.withAlphaComponent(0.35).setFill()
        NSRect(x: 0, y: 0, width: bounds.width, height: 1).fill()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }

    private func setup() {
        iconView.image = NSImage(
            systemSymbolName: "exclamationmark.triangle.fill",
            accessibilityDescription: nil
        )
        iconView.contentTintColor = .systemOrange
        iconView.imageScaling = .scaleProportionallyUpOrDown

        label.font = .systemFont(ofSize: 10.5)
        label.textColor = .labelColor
        label.lineBreakMode = .byTruncatingTail
        label.maximumNumberOfLines = 1
        label.cell?.usesSingleLineMode = true

        [iconView, label].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 12),
            iconView.heightAnchor.constraint(equalToConstant: 12),

            label.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 7),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
}

final class PreviewEmptyStateView: NSView {
    private let imageView = NSImageView(frame: .zero)
    private let titleLabel = NSTextField(labelWithString: "")
    private let messageLabel = NSTextField(wrappingLabelWithString: "")
    private let pathLabel = NSTextField(wrappingLabelWithString: "")
    private let stack = NSStackView(frame: .zero)

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(symbol: String, title: String, message: String, path: String?) {
        let configuration = NSImage.SymbolConfiguration(pointSize: 36, weight: .light)
        imageView.image = NSImage(
            systemSymbolName: symbol,
            accessibilityDescription: nil
        )?.withSymbolConfiguration(configuration)

        titleLabel.stringValue = title
        messageLabel.stringValue = message
        pathLabel.stringValue = path ?? ""
        pathLabel.isHidden = path == nil
    }

    private func setup() {
        imageView.contentTintColor = .tertiaryLabelColor
        imageView.imageScaling = .scaleProportionallyUpOrDown

        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.alignment = .center

        messageLabel.font = .systemFont(ofSize: 12)
        messageLabel.textColor = .secondaryLabelColor
        messageLabel.alignment = .center
        messageLabel.maximumNumberOfLines = 0
        messageLabel.preferredMaxLayoutWidth = 480

        pathLabel.font = .monospacedSystemFont(ofSize: 10, weight: .regular)
        pathLabel.textColor = .tertiaryLabelColor
        pathLabel.alignment = .center
        pathLabel.maximumNumberOfLines = 2
        pathLabel.lineBreakMode = .byTruncatingMiddle
        pathLabel.preferredMaxLayoutWidth = 480

        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        [imageView, titleLabel, messageLabel, pathLabel].forEach {
            stack.addArrangedSubview($0)
        }
        stack.setCustomSpacing(14, after: imageView)
        addSubview(stack)

        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 44),
            imageView.heightAnchor.constraint(equalToConstant: 44),

            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.widthAnchor.constraint(lessThanOrEqualToConstant: 520),

            messageLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 480),
            pathLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 480),
        ])
    }
}
