import AppKit

final class CodePreviewView: NSView {
    private let headerView = PreviewHeaderView(frame: .zero)
    private let warningView = WarningBannerView(frame: .zero)
    private let scrollView = NSScrollView(frame: .zero)
    private let textView = NSTextView(frame: .zero)
    private let structureView = StructurePreviewView(frame: .zero)
    private let emptyStateView = PreviewEmptyStateView(frame: .zero)
    private let loadingView = NSView(frame: .zero)
    private let loadingSpinner = NSProgressIndicator(frame: .zero)
    private let loadingLabel = NSTextField(labelWithString: "正在读取文件…")
    private var rulerView: LineNumberRulerView?
    private var warningHeightConstraint: NSLayoutConstraint!
    private var gutterWidthConstraint: NSLayoutConstraint!

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showLoading(for url: URL) {
        headerView.configureLoading(for: url)
        setWarning(nil)
        scrollView.isHidden = true
        rulerView?.isHidden = true
        structureView.isHidden = true
        structureView.clear()
        emptyStateView.isHidden = true
        loadingView.isHidden = false
        loadingSpinner.startAnimation(nil)
    }

    func display(_ result: DocumentLoadResult) {
        loadingSpinner.stopAnimation(nil)
        loadingView.isHidden = true

        switch result {
        case let .document(document):
            headerView.configure(with: document)
            setWarning(document.warnings.isEmpty ? nil : document.warnings.joined(separator: "  ·  "))
            structureView.isHidden = true

            if document.text.isEmpty {
                scrollView.isHidden = true
                rulerView?.isHidden = true
                emptyStateView.isHidden = false
                emptyStateView.configure(
                    symbol: "doc",
                    title: "空文件",
                    message: "这个文件没有内容。",
                    path: document.url.path
                )
                return
            }

            emptyStateView.isHidden = true
            scrollView.isHidden = false
            rulerView?.isHidden = false
            textView.textStorage?.setAttributedString(document.attributedText)
            textView.setSelectedRange(NSRange(location: 0, length: 0))
            if let width = rulerView?.update(
                lineCount: document.lineCount,
                text: document.text as NSString
            ) {
                gutterWidthConstraint.constant = width
            }
            textView.scrollRangeToVisible(NSRange(location: 0, length: 0))
            scrollView.reflectScrolledClipView(scrollView.contentView)

        case let .structure(structure):
            headerView.configure(with: structure)
            setWarning(structure.warnings.isEmpty ? nil : structure.warnings.joined(separator: "  ·  "))
            scrollView.isHidden = true
            rulerView?.isHidden = true
            emptyStateView.isHidden = true
            structureView.isHidden = false
            structureView.display(structure)

        case let .failure(failure):
            headerView.configureFailure(url: failure.url)
            setWarning(nil)
            scrollView.isHidden = true
            rulerView?.isHidden = true
            structureView.isHidden = true
            emptyStateView.isHidden = false
            emptyStateView.configure(
                symbol: failure.symbol,
                title: failure.title,
                message: failure.message,
                path: failure.url.path
            )
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.textBackgroundColor.setFill()
        bounds.fill()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
        scrollView.backgroundColor = .textBackgroundColor
        textView.backgroundColor = .textBackgroundColor
        structureView.needsDisplay = true
    }

    private func setWarning(_ message: String?) {
        if let message {
            warningView.configure(message)
            warningView.isHidden = false
            warningHeightConstraint.constant = 26
        } else {
            warningView.isHidden = true
            warningHeightConstraint.constant = 0
        }
        needsLayout = true
    }

    private func setup() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        warningView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        structureView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        loadingView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(headerView)
        addSubview(warningView)
        addSubview(scrollView)
        addSubview(structureView)
        addSubview(emptyStateView)
        addSubview(loadingView)

        let ruler = LineNumberRulerView(textView: textView)
        ruler.translatesAutoresizingMaskIntoConstraints = false
        addSubview(ruler)
        rulerView = ruler
        ruler.isHidden = true

        warningHeightConstraint = warningView.heightAnchor.constraint(equalToConstant: 0)
        gutterWidthConstraint = ruler.widthAnchor.constraint(equalToConstant: ruler.ruleThickness)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: topAnchor),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 52),

            warningView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            warningView.leadingAnchor.constraint(equalTo: leadingAnchor),
            warningView.trailingAnchor.constraint(equalTo: trailingAnchor),
            warningHeightConstraint,

            scrollView.topAnchor.constraint(equalTo: warningView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: ruler.trailingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            structureView.topAnchor.constraint(equalTo: warningView.bottomAnchor),
            structureView.leadingAnchor.constraint(equalTo: leadingAnchor),
            structureView.trailingAnchor.constraint(equalTo: trailingAnchor),
            structureView.bottomAnchor.constraint(equalTo: bottomAnchor),

            ruler.leadingAnchor.constraint(equalTo: leadingAnchor),
            ruler.topAnchor.constraint(equalTo: scrollView.topAnchor),
            ruler.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            gutterWidthConstraint,

            emptyStateView.centerXAnchor.constraint(equalTo: centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 20),
            emptyStateView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 40),
            emptyStateView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -40),

            loadingView.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 20),
        ])

        setupScrollView()
        setupLoadingView()

        warningView.isHidden = true
        scrollView.isHidden = true
        structureView.isHidden = true
        emptyStateView.isHidden = true
        loadingView.isHidden = false
        loadingSpinner.startAnimation(nil)
    }

    private func setupScrollView() {
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = true
        scrollView.backgroundColor = .textBackgroundColor
        scrollView.scrollerStyle = .overlay

        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = true
        textView.importsGraphics = false
        textView.drawsBackground = true
        textView.backgroundColor = .textBackgroundColor
        textView.textContainerInset = NSSize(width: 14, height: 12)
        textView.font = SyntaxHighlighter.makeFont()
        textView.textColor = .textColor
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.isGrammarCheckingEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(
            width: 0,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainer?.lineFragmentPadding = 0
        textView.postsFrameChangedNotifications = true
        textView.postsBoundsChangedNotifications = true
        textView.setAccessibilityLabel("代码预览")

        scrollView.documentView = textView

        scrollView.contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clipViewDidScroll),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func clipViewDidScroll() {
        rulerView?.needsDisplay = true
    }

    private func setupLoadingView() {
        loadingSpinner.style = .spinning
        loadingSpinner.controlSize = .small
        loadingSpinner.translatesAutoresizingMaskIntoConstraints = false

        loadingLabel.font = .systemFont(ofSize: 12)
        loadingLabel.textColor = .secondaryLabelColor
        loadingLabel.alignment = .center

        let stack = NSStackView(views: [loadingSpinner, loadingLabel])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        loadingView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: loadingView.topAnchor),
            stack.leadingAnchor.constraint(equalTo: loadingView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: loadingView.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: loadingView.bottomAnchor),
        ])
    }
}
