import AppKit

final class LineNumberRulerView: NSView {
    private weak var textView: NSTextView?
    private let numberFont: NSFont
    private var lineStarts: [Int] = [0]
    private var lineCount = 0
    private(set) var ruleThickness: CGFloat = 44

    init(textView: NSTextView) {
        self.textView = textView
        self.numberFont = NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular)
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isFlipped: Bool { true }

    @discardableResult
    func update(lineCount: Int, text: NSString) -> CGFloat {
        self.lineCount = lineCount

        var starts: [Int] = [0]
        if text.length > 0 {
            starts.reserveCapacity(max(1, lineCount))
            var index = 0
            while index < text.length {
                if text.character(at: index) == 10 {
                    starts.append(index + 1)
                }
                index += 1
            }
        }
        lineStarts = starts

        let digits = max(3, String(max(lineCount, 1)).count)
        let digitWidth = ("0" as NSString).size(withAttributes: [.font: numberFont]).width
        ruleThickness = ceil(max(38, CGFloat(digits) * digitWidth + 20))
        needsDisplay = true
        return ruleThickness
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.textBackgroundColor.setFill()
        bounds.fill()

        drawLineNumbers()

        NSColor.separatorColor.withAlphaComponent(0.45).setFill()
        NSRect(
            x: max(0, bounds.width - 1),
            y: 0,
            width: 1,
            height: bounds.height
        ).fill()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }

    private func drawLineNumbers() {
        guard lineCount > 0,
              let textView,
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer,
              let scrollView = textView.enclosingScrollView else {
            return
        }

        let visibleRect = scrollView.contentView.bounds
        let origin = textView.textContainerOrigin
        let containerRect = visibleRect.offsetBy(dx: -origin.x, dy: -origin.y)
        let glyphRange = layoutManager.glyphRange(
            forBoundingRect: containerRect,
            in: textContainer
        )
        let characterRange = layoutManager.characterRange(
            forGlyphRange: glyphRange,
            actualGlyphRange: nil
        )

        let firstLine = max(0, lineIndex(for: characterRange.location) - 1)
        let lastLine = min(
            lineStarts.count - 1,
            lineIndex(for: NSMaxRange(characterRange)) + 1
        )
        guard firstLine <= lastLine else { return }

        let relativePoint = convert(NSPoint.zero, from: textView)
        let textLength = (textView.string as NSString).length
        let attributes: [NSAttributedString.Key: Any] = [
            .font: numberFont,
            .foregroundColor: NSColor.tertiaryLabelColor,
        ]

        var line = firstLine
        while line <= lastLine {
            let start = lineStarts[line]
            let lineRect: NSRect

            if start >= textLength {
                lineRect = layoutManager.extraLineFragmentRect
            } else {
                let glyphIndex = min(
                    layoutManager.glyphIndexForCharacter(at: start),
                    max(0, layoutManager.numberOfGlyphs - 1)
                )
                lineRect = layoutManager.lineFragmentRect(
                    forGlyphAt: glyphIndex,
                    effectiveRange: nil
                )
            }

            if lineRect.height > 0 {
                let label = "\(line + 1)" as NSString
                let size = label.size(withAttributes: attributes)
                let x = bounds.width - size.width - 10
                let y = lineRect.minY + origin.y + relativePoint.y +
                    (lineRect.height - size.height) / 2
                label.draw(
                    at: NSPoint(x: x, y: y),
                    withAttributes: attributes
                )
            }

            line += 1
        }
    }

    private func lineIndex(for characterIndex: Int) -> Int {
        var low = 0
        var high = lineStarts.count - 1

        while low <= high {
            let middle = (low + high) / 2
            if lineStarts[middle] <= characterIndex {
                low = middle + 1
            } else {
                high = middle - 1
            }
        }

        return max(0, high)
    }
}
