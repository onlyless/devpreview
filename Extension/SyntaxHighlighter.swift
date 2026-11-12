import AppKit

enum SyntaxTheme {
    static let keyword = dynamic(
        light: NSColor(srgbRed: 0.64, green: 0.13, blue: 0.72, alpha: 1),
        dark: NSColor(srgbRed: 0.78, green: 0.47, blue: 0.92, alpha: 1)
    )
    static let string = dynamic(
        light: NSColor(srgbRed: 0.08, green: 0.46, blue: 0.18, alpha: 1),
        dark: NSColor(srgbRed: 0.59, green: 0.77, blue: 0.47, alpha: 1)
    )
    static let comment = dynamic(
        light: NSColor(srgbRed: 0.39, green: 0.43, blue: 0.47, alpha: 1),
        dark: NSColor(srgbRed: 0.50, green: 0.54, blue: 0.59, alpha: 1)
    )
    static let number = dynamic(
        light: NSColor(srgbRed: 0.66, green: 0.32, blue: 0.00, alpha: 1),
        dark: NSColor(srgbRed: 0.84, green: 0.60, blue: 0.40, alpha: 1)
    )
    static let type = dynamic(
        light: NSColor(srgbRed: 0.50, green: 0.32, blue: 0.00, alpha: 1),
        dark: NSColor(srgbRed: 0.90, green: 0.75, blue: 0.48, alpha: 1)
    )
    static let function = dynamic(
        light: NSColor(srgbRed: 0.00, green: 0.36, blue: 0.75, alpha: 1),
        dark: NSColor(srgbRed: 0.38, green: 0.69, blue: 0.94, alpha: 1)
    )
    static let key = dynamic(
        light: NSColor(srgbRed: 0.70, green: 0.11, blue: 0.16, alpha: 1),
        dark: NSColor(srgbRed: 0.88, green: 0.42, blue: 0.45, alpha: 1)
    )
    static let annotation = dynamic(
        light: NSColor(srgbRed: 0.45, green: 0.22, blue: 0.78, alpha: 1),
        dark: NSColor(srgbRed: 0.82, green: 0.66, blue: 1.00, alpha: 1)
    )
    static let preprocessor = dynamic(
        light: NSColor(srgbRed: 0.02, green: 0.31, blue: 0.68, alpha: 1),
        dark: NSColor(srgbRed: 0.34, green: 0.71, blue: 0.76, alpha: 1)
    )
    static let heading = dynamic(
        light: NSColor(srgbRed: 0.02, green: 0.31, blue: 0.68, alpha: 1),
        dark: NSColor(srgbRed: 0.38, green: 0.69, blue: 0.94, alpha: 1)
    )
    static let link = dynamic(
        light: NSColor(srgbRed: 0.04, green: 0.41, blue: 0.85, alpha: 1),
        dark: NSColor(srgbRed: 0.42, green: 0.71, blue: 1.00, alpha: 1)
    )
    static let punctuation = dynamic(
        light: NSColor(srgbRed: 0.42, green: 0.45, blue: 0.50, alpha: 1),
        dark: NSColor(srgbRed: 0.58, green: 0.62, blue: 0.68, alpha: 1)
    )
    static let codeBackground = dynamic(
        light: NSColor(srgbRed: 0.92, green: 0.94, blue: 0.96, alpha: 0.55),
        dark: NSColor(srgbRed: 0.18, green: 0.20, blue: 0.23, alpha: 0.65)
    )
    static let addedBackground = dynamic(
        light: NSColor(srgbRed: 0.76, green: 0.96, blue: 0.80, alpha: 0.55),
        dark: NSColor(srgbRed: 0.16, green: 0.36, blue: 0.22, alpha: 0.55)
    )
    static let removedBackground = dynamic(
        light: NSColor(srgbRed: 1.00, green: 0.87, blue: 0.87, alpha: 0.60),
        dark: NSColor(srgbRed: 0.43, green: 0.17, blue: 0.18, alpha: 0.55)
    )

    private static func dynamic(light: NSColor, dark: NSColor) -> NSColor {
        NSColor(name: nil, dynamicProvider: { appearance in
            let match = appearance.bestMatch(from: [.aqua, .darkAqua])
            return match == .darkAqua ? dark : light
        }) ?? light
    }
}

enum SyntaxHighlighter {
    static let fontSize: CGFloat = 12
    static let highlightLimit = 2 * 1024 * 1024

    static func makeFont() -> NSFont {
        NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
    }

    static func makeParagraphStyle(font: NSFont) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 1.5
        style.lineBreakMode = .byWordWrapping
        style.tabStops = []
        let spaceWidth = (" " as NSString).size(withAttributes: [.font: font]).width
        style.defaultTabInterval = max(12, spaceWidth * 4)
        return style
    }

    static func plain(
        _ text: String,
        font: NSFont,
        paragraphStyle: NSParagraphStyle
    ) -> NSAttributedString {
        NSAttributedString(
            string: text,
            attributes: baseAttributes(font: font, paragraphStyle: paragraphStyle)
        )
    }

    static func highlight(
        _ text: String,
        language: LanguageProfile,
        font: NSFont,
        paragraphStyle: NSParagraphStyle,
        enabled: Bool
    ) -> NSAttributedString {
        let base = baseAttributes(font: font, paragraphStyle: paragraphStyle)

        guard enabled, !text.isEmpty else {
            return NSAttributedString(string: text, attributes: base)
        }

        switch language.kind {
        case .plain:
            return NSAttributedString(string: text, attributes: base)
        case .markdown:
            return highlightMarkdown(text, base: base, font: font)
        case .markup:
            return highlightMarkup(text, base: base)
        case .diff:
            return highlightDiff(text, base: base)
        case .makefile:
            return highlightMakefile(text, language: language, base: base)
        case .yaml:
            return highlightYAML(text, language: language, base: base)
        case .toml, .ini:
            return highlightKeyValue(text, language: language, base: base)
        case .code, .json, .css:
            return highlightCode(text, language: language, base: base)
        }
    }

    private static func baseAttributes(
        font: NSFont,
        paragraphStyle: NSParagraphStyle
    ) -> [NSAttributedString.Key: Any] {
        [
            .font: font,
            .foregroundColor: NSColor.textColor,
            .paragraphStyle: paragraphStyle,
        ]
    }

    private static func highlightCode(
        _ text: String,
        language: LanguageProfile,
        base: [NSAttributedString.Key: Any]
    ) -> NSAttributedString {
        let source = text as NSString
        let result = NSMutableAttributedString(string: text)
        result.addAttributes(base, range: NSRange(location: 0, length: source.length))
        guard source.length > 0 else { return result }

        var index = 0
        var onlyWhitespaceOnLine = true

        while index < source.length {
            let character = source.character(at: index)

            if character == 10 {
                index += 1
                onlyWhitespaceOnLine = true
                continue
            }
            if character == 32 || character == 9 || character == 13 {
                index += 1
                continue
            }

            if language.supportsHashDirectives, onlyWhitespaceOnLine, character == 35 {
                let end = lineEnd(in: source, from: index)
                addColor(
                    SyntaxTheme.preprocessor,
                    range: NSRange(location: index, length: max(0, end - index)),
                    to: result
                )
                index = max(end, index + 1)
                onlyWhitespaceOnLine = false
                continue
            }

            if let range = commentRange(
                in: source,
                at: index,
                language: language,
                onlyWhitespaceOnLine: onlyWhitespaceOnLine
            ) {
                addColor(SyntaxTheme.comment, range: range, to: result)
                index = NSMaxRange(range)
                onlyWhitespaceOnLine = false
                continue
            }

            if let range = stringRange(in: source, at: index, language: language) {
                let color = language.kind == .json && isJSONKey(after: NSMaxRange(range), in: source)
                    ? SyntaxTheme.key
                    : SyntaxTheme.string
                addColor(color, range: range, to: result)
                index = NSMaxRange(range)
                onlyWhitespaceOnLine = false
                continue
            }

            if language.supportsDollarVariables, character == 36,
               let range = dollarVariableRange(in: source, at: index) {
                addColor(SyntaxTheme.annotation, range: range, to: result)
                index = NSMaxRange(range)
                onlyWhitespaceOnLine = false
                continue
            }

            if language.supportsAnnotations, character == 64 {
                var cursor = index + 1
                while cursor < source.length, isIdentifierContinuation(source.character(at: cursor)) {
                    cursor += 1
                }
                if cursor > index + 1 {
                    addColor(
                        SyntaxTheme.annotation,
                        range: NSRange(location: index, length: cursor - index),
                        to: result
                    )
                    index = cursor
                    onlyWhitespaceOnLine = false
                    continue
                }
            }

            if isIdentifierStart(character) {
                var cursor = index + 1
                while cursor < source.length, isIdentifierContinuation(source.character(at: cursor)) {
                    cursor += 1
                }

                let range = NSRange(location: index, length: cursor - index)
                let word = source.substring(with: range)
                let lookup = language.caseInsensitiveKeywords ? word.lowercased() : word

                if language.keywords.contains(lookup) {
                    addColor(SyntaxTheme.keyword, range: range, to: result)
                } else if language.types.contains(lookup) {
                    addColor(SyntaxTheme.type, range: range, to: result)
                } else if language.colorsCapitalizedTypes, word.first?.isUppercase == true {
                    addColor(SyntaxTheme.type, range: range, to: result)
                } else if let next = nextNonWhitespace(in: source, after: cursor) {
                    if next == 40 {
                        addColor(SyntaxTheme.function, range: range, to: result)
                    } else if next == 33, language.supportsMacroBang {
                        addColor(SyntaxTheme.function, range: range, to: result)
                    }
                }

                index = cursor
                onlyWhitespaceOnLine = false
                continue
            }

            if isDigit(character) ||
                (character == 46 && index + 1 < source.length && isDigit(source.character(at: index + 1))) {
                let range = numberRange(in: source, at: index)
                addColor(SyntaxTheme.number, range: range, to: result)
                index = NSMaxRange(range)
                onlyWhitespaceOnLine = false
                continue
            }

            onlyWhitespaceOnLine = false
            index += 1
        }

        return result
    }

    private static func highlightYAML(
        _ text: String,
        language: LanguageProfile,
        base: [NSAttributedString.Key: Any]
    ) -> NSAttributedString {
        let result = NSMutableAttributedString(
            attributedString: highlightCode(text, language: language, base: base)
        )
        let source = text as NSString
        let full = NSRange(location: 0, length: source.length)

        if let keyRegex = try? NSRegularExpression(
            pattern: "^(\\s*(?:-\\s+)?)([^\\s#][^:\\n]*?):(?=\\s|$)",
            options: [.anchorsMatchLines]
        ) {
            for match in keyRegex.matches(in: text, range: full) where match.numberOfRanges > 2 {
                addColor(SyntaxTheme.key, range: match.range(at: 2), to: result)
            }
        }

        if let listRegex = try? NSRegularExpression(
            pattern: "^(\\s*)(-)(\\s)",
            options: [.anchorsMatchLines]
        ) {
            for match in listRegex.matches(in: text, range: full) where match.numberOfRanges > 2 {
                addColor(SyntaxTheme.keyword, range: match.range(at: 2), to: result)
            }
        }

        return result
    }

    private static func highlightKeyValue(
        _ text: String,
        language: LanguageProfile,
        base: [NSAttributedString.Key: Any]
    ) -> NSAttributedString {
        let result = NSMutableAttributedString(
            attributedString: highlightCode(text, language: language, base: base)
        )
        let source = text as NSString
        let full = NSRange(location: 0, length: source.length)

        if let keyRegex = try? NSRegularExpression(
            pattern: "^(\\s*)([A-Za-z0-9_.\\-]+)\\s*=",
            options: [.anchorsMatchLines]
        ) {
            for match in keyRegex.matches(in: text, range: full) where match.numberOfRanges > 2 {
                addColor(SyntaxTheme.key, range: match.range(at: 2), to: result)
            }
        }

        if let sectionRegex = try? NSRegularExpression(
            pattern: "^\\s*\\[\\[?([^\\]]+)\\]\\]?",
            options: [.anchorsMatchLines]
        ) {
            for match in sectionRegex.matches(in: text, range: full) where match.numberOfRanges > 1 {
                addColor(SyntaxTheme.type, range: match.range(at: 1), to: result)
            }
        }

        return result
    }

    private static func highlightMakefile(
        _ text: String,
        language: LanguageProfile,
        base: [NSAttributedString.Key: Any]
    ) -> NSAttributedString {
        let result = NSMutableAttributedString(
            attributedString: highlightCode(text, language: language, base: base)
        )
        let source = text as NSString
        let full = NSRange(location: 0, length: source.length)

        if let targetRegex = try? NSRegularExpression(
            pattern: "^([^\\s:#][^:\\n]*):",
            options: [.anchorsMatchLines]
        ) {
            for match in targetRegex.matches(in: text, range: full) where match.numberOfRanges > 1 {
                addColor(SyntaxTheme.function, range: match.range(at: 1), to: result)
            }
        }

        if let variableRegex = try? NSRegularExpression(
            pattern: "^\\s*([A-Za-z0-9_.\\-]+)\\s*[:?+]?=",
            options: [.anchorsMatchLines]
        ) {
            for match in variableRegex.matches(in: text, range: full) where match.numberOfRanges > 1 {
                addColor(SyntaxTheme.key, range: match.range(at: 1), to: result)
            }
        }

        if let referenceRegex = try? NSRegularExpression(
            pattern: "\\$[({][^)}\\n]+[)}]"
        ) {
            for match in referenceRegex.matches(in: text, range: full) {
                addColor(SyntaxTheme.annotation, range: match.range, to: result)
            }
        }

        return result
    }

    private static func highlightDiff(
        _ text: String,
        base: [NSAttributedString.Key: Any]
    ) -> NSAttributedString {
        let result = NSMutableAttributedString(string: text)
        let source = text as NSString
        result.addAttributes(base, range: NSRange(location: 0, length: source.length))

        forEachLine(in: source) { range, line in
            guard range.length > 0 else { return }

            if line.hasPrefix("+++") || line.hasPrefix("---") || line.hasPrefix("diff ") ||
                line.hasPrefix("index ") {
                addColor(SyntaxTheme.comment, range: range, to: result)
            } else if line.hasPrefix("@@") {
                addColor(SyntaxTheme.heading, range: range, to: result)
                addBackground(SyntaxTheme.codeBackground, range: range, to: result)
            } else if line.hasPrefix("+") {
                addColor(NSColor.systemGreen, range: range, to: result)
                addBackground(SyntaxTheme.addedBackground, range: range, to: result)
            } else if line.hasPrefix("-") {
                addColor(NSColor.systemRed, range: range, to: result)
                addBackground(SyntaxTheme.removedBackground, range: range, to: result)
            } else if line.hasPrefix("!") {
                addColor(SyntaxTheme.keyword, range: range, to: result)
            }
        }

        return result
    }

    private static func highlightMarkdown(
        _ text: String,
        base: [NSAttributedString.Key: Any],
        font: NSFont
    ) -> NSAttributedString {
        let source = text as NSString
        let result = NSMutableAttributedString(string: text)
        result.addAttributes(base, range: NSRange(location: 0, length: source.length))

        let headingFont = NSFont.monospacedSystemFont(ofSize: font.pointSize, weight: .semibold)
        var inFence = false
        var fenceMarker: String?

        forEachLine(in: source) { range, line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if let marker = fencePrefix(in: trimmed) {
                if !inFence {
                    inFence = true
                    fenceMarker = marker
                } else if trimmed.hasPrefix(fenceMarker ?? marker) {
                    inFence = false
                    fenceMarker = nil
                }
                addColor(SyntaxTheme.comment, range: range, to: result)
                return
            }

            if inFence {
                addColor(SyntaxTheme.string, range: range, to: result)
                addBackground(SyntaxTheme.codeBackground, range: range, to: result)
                return
            }

            if trimmed.hasPrefix("#") {
                let hashes = trimmed.prefix { $0 == "#" }.count
                let rest = trimmed.dropFirst(hashes)
                if (1...6).contains(hashes), rest.first == " " {
                    addColor(SyntaxTheme.heading, range: range, to: result)
                    result.addAttribute(.font, value: headingFont, range: range)
                }
            } else if trimmed.hasPrefix(">") {
                addColor(SyntaxTheme.comment, range: range, to: result)
            }

            applyMarkdownInlineStyles(
                to: result,
                line: line,
                globalRange: range,
                font: font
            )
        }

        return result
    }

    private static func applyMarkdownInlineStyles(
        to result: NSMutableAttributedString,
        line: String,
        globalRange: NSRange,
        font: NSFont
    ) {
        let local = line as NSString
        let localFull = NSRange(location: 0, length: local.length)
        var codeRanges: [NSRange] = []

        if let codeRegex = try? NSRegularExpression(pattern: "`[^`\\n]+`") {
            for match in codeRegex.matches(in: line, range: localFull) {
                let range = offset(match.range, by: globalRange.location)
                codeRanges.append(range)
                addColor(SyntaxTheme.string, range: range, to: result)
                addBackground(SyntaxTheme.codeBackground, range: range, to: result)
            }
        }

        if let linkRegex = try? NSRegularExpression(pattern: "\\[([^\\]]+)\\]\\(([^)]+)\\)") {
            for match in linkRegex.matches(in: line, range: localFull) where match.numberOfRanges > 2 {
                let textRange = offset(match.range(at: 1), by: globalRange.location)
                let urlRange = offset(match.range(at: 2), by: globalRange.location)
                addColor(SyntaxTheme.link, range: textRange, to: result)
                addColor(SyntaxTheme.comment, range: urlRange, to: result)
                if urlRange.location != NSNotFound {
                    let urlString = (result.string as NSString).substring(with: urlRange)
                    result.addAttribute(.link, value: urlString, range: textRange)
                }
            }
        }

        if let boldRegex = try? NSRegularExpression(pattern: "\\*\\*([^*\\n]+)\\*\\*|__([^_\\n]+)__") {
            let boldFont = NSFont.monospacedSystemFont(ofSize: font.pointSize, weight: .semibold)
            for match in boldRegex.matches(in: line, range: localFull) {
                let range = offset(match.range, by: globalRange.location)
                guard !intersectsProtectedRange(range, codeRanges) else { continue }
                result.addAttribute(.font, value: boldFont, range: range)
            }
        }

        if let italicRegex = try? NSRegularExpression(
            pattern: "(?<!\\*)\\*([^*\\n]+)\\*(?!\\*)|(?<!_)_([^_\\n]+)_(?!_)"
        ) {
            for match in italicRegex.matches(in: line, range: localFull) {
                let range = offset(match.range, by: globalRange.location)
                guard !intersectsProtectedRange(range, codeRanges) else { continue }
                result.addAttribute(.obliqueness, value: 0.16, range: range)
            }
        }
    }

    private static func highlightMarkup(
        _ text: String,
        base: [NSAttributedString.Key: Any]
    ) -> NSAttributedString {
        let source = text as NSString
        let result = NSMutableAttributedString(string: text)
        result.addAttributes(base, range: NSRange(location: 0, length: source.length))

        var index = 0
        while index < source.length {
            let character = source.character(at: index)

            if character == 60 {
                if matches(source, at: index, string: "<!--"),
                   let end = find(source, from: index + 4, string: "-->") {
                    let range = NSRange(location: index, length: end - index)
                    addColor(SyntaxTheme.comment, range: range, to: result)
                    index = end
                    continue
                }

                if let end = tagEnd(in: source, from: index) {
                    highlightTag(
                        in: source,
                        range: NSRange(location: index, length: end + 1 - index),
                        result: result
                    )
                    index = end + 1
                    continue
                }
            }

            if character == 38,
               let semicolon = find(source, from: index + 1, string: ";", limit: 16) {
                let range = NSRange(location: index, length: semicolon - index)
                addColor(SyntaxTheme.annotation, range: range, to: result)
                index = semicolon
                continue
            }

            index += 1
        }

        return result
    }

    private static func highlightTag(
        in source: NSString,
        range: NSRange,
        result: NSMutableAttributedString
    ) {
        let end = NSMaxRange(range)
        addColor(
            SyntaxTheme.punctuation,
            range: NSRange(location: range.location, length: 1),
            to: result
        )
        addColor(
            SyntaxTheme.punctuation,
            range: NSRange(location: end - 1, length: 1),
            to: result
        )

        var cursor = range.location + 1
        if cursor < end, source.character(at: cursor) == 47 {
            cursor += 1
        }
        while cursor < end, isWhitespace(source.character(at: cursor)) {
            cursor += 1
        }

        if cursor < end,
           source.character(at: cursor) == 33 || source.character(at: cursor) == 63 {
            addColor(
                SyntaxTheme.preprocessor,
                range: NSRange(location: cursor, length: max(0, end - 1 - cursor)),
                to: result
            )
            return
        }

        let nameStart = cursor
        while cursor < end, isTagNameCharacter(source.character(at: cursor)) {
            cursor += 1
        }
        if cursor > nameStart {
            addColor(
                SyntaxTheme.type,
                range: NSRange(location: nameStart, length: cursor - nameStart),
                to: result
            )
        }

        while cursor < end - 1 {
            let character = source.character(at: cursor)
            if isWhitespace(character) || character == 47 {
                cursor += 1
                continue
            }

            let attributeStart = cursor
            while cursor < end - 1,
                  isTagNameCharacter(source.character(at: cursor)) ||
                  source.character(at: cursor) == 46 {
                cursor += 1
            }
            if cursor > attributeStart {
                addColor(
                    SyntaxTheme.function,
                    range: NSRange(location: attributeStart, length: cursor - attributeStart),
                    to: result
                )
            } else if cursor < end - 1, source.character(at: cursor) != 61 {
                cursor += 1
                continue
            }

            while cursor < end - 1, isWhitespace(source.character(at: cursor)) {
                cursor += 1
            }

            guard cursor < end - 1, source.character(at: cursor) == 61 else {
                continue
            }
            cursor += 1
            while cursor < end - 1, isWhitespace(source.character(at: cursor)) {
                cursor += 1
            }

            if cursor < end - 1 {
                let quote = source.character(at: cursor)
                if quote == 34 || quote == 39 {
                    let valueStart = cursor
                    cursor += 1
                    while cursor < end - 1 {
                        if source.character(at: cursor) == quote {
                            cursor += 1
                            break
                        }
                        cursor += 1
                    }
                    addColor(
                        SyntaxTheme.string,
                        range: NSRange(location: valueStart, length: cursor - valueStart),
                        to: result
                    )
                } else {
                    let valueStart = cursor
                    while cursor < end - 1, !isWhitespace(source.character(at: cursor)) {
                        cursor += 1
                    }
                    addColor(
                        SyntaxTheme.string,
                        range: NSRange(location: valueStart, length: cursor - valueStart),
                        to: result
                    )
                }
            }
        }
    }

    private static func commentRange(
        in source: NSString,
        at index: Int,
        language: LanguageProfile,
        onlyWhitespaceOnLine: Bool
    ) -> NSRange? {
        for block in language.blockComments where matches(source, at: index, string: block.start) {
            var depth = 1
            var cursor = index + (block.start as NSString).length

            while cursor < source.length {
                if language.nestedBlockComments,
                   matches(source, at: cursor, string: block.start) {
                    depth += 1
                    cursor += (block.start as NSString).length
                    continue
                }
                if matches(source, at: cursor, string: block.end) {
                    depth -= 1
                    cursor += (block.end as NSString).length
                    if depth == 0 {
                        break
                    }
                    continue
                }
                cursor += 1
            }

            return NSRange(location: index, length: max(0, cursor - index))
        }

        for prefix in language.lineComments where matches(source, at: index, string: prefix) {
            if prefix == "#", language.hashCommentNeedsWhitespace, !onlyWhitespaceOnLine {
                let previous = index > 0 ? source.character(at: index - 1) : 32
                if previous != 32, previous != 9 {
                    continue
                }
            }
            let end = lineEnd(in: source, from: index)
            return NSRange(location: index, length: max(0, end - index))
        }

        return nil
    }

    private static func stringRange(
        in source: NSString,
        at index: Int,
        language: LanguageProfile
    ) -> NSRange? {
        for delimiter in language.stringDelimiters where matches(source, at: index, string: delimiter) {
            let delimiterLength = (delimiter as NSString).length
            let allowsMultiline = language.multilineStringDelimiters.contains(delimiter)
            var cursor = index + delimiterLength
            var closed = false

            while cursor < source.length {
                let character = source.character(at: cursor)

                if character == 92 {
                    cursor = min(source.length, cursor + 2)
                    continue
                }
                if character == 10, !allowsMultiline {
                    break
                }
                if matches(source, at: cursor, string: delimiter) {
                    cursor += delimiterLength
                    closed = true
                    break
                }
                cursor += 1
            }

            if closed {
                return NSRange(location: index, length: cursor - index)
            }
            if !allowsMultiline {
                let end = lineEnd(in: source, from: cursor)
                if end > index + delimiterLength {
                    return NSRange(location: index, length: end - index)
                }
            }
        }

        return nil
    }

    private static func numberRange(in source: NSString, at index: Int) -> NSRange {
        var cursor = index
        if source.character(at: cursor) == 46 {
            cursor += 1
        }

        while cursor < source.length {
            let character = source.character(at: cursor)
            if isDigit(character) || isASCIIAlpha(character) || character == 46 || character == 95 {
                cursor += 1
                continue
            }
            if character == 43 || character == 45 {
                let previous = cursor > index ? source.character(at: cursor - 1) : 0
                if previous == 69 || previous == 101 {
                    cursor += 1
                    continue
                }
            }
            break
        }

        return NSRange(location: index, length: max(1, cursor - index))
    }

    private static func dollarVariableRange(in source: NSString, at index: Int) -> NSRange? {
        var cursor = index + 1
        guard cursor < source.length else { return nil }

        if source.character(at: cursor) == 123 {
            cursor += 1
            while cursor < source.length {
                if source.character(at: cursor) == 125 {
                    cursor += 1
                    return NSRange(location: index, length: cursor - index)
                }
                if source.character(at: cursor) == 10 {
                    return nil
                }
                cursor += 1
            }
            return nil
        }

        guard isIdentifierStart(source.character(at: cursor)) else { return nil }
        while cursor < source.length, isIdentifierContinuation(source.character(at: cursor)) {
            cursor += 1
        }
        return NSRange(location: index, length: cursor - index)
    }

    private static func isJSONKey(after index: Int, in source: NSString) -> Bool {
        var cursor = index
        while cursor < source.length {
            let character = source.character(at: cursor)
            if character == 32 || character == 9 || character == 10 || character == 13 {
                cursor += 1
                continue
            }
            return character == 58
        }
        return false
    }

    private static func lineEnd(in source: NSString, from index: Int) -> Int {
        var cursor = index
        while cursor < source.length, source.character(at: cursor) != 10 {
            cursor += 1
        }
        return cursor
    }

    private static func nextNonWhitespace(in source: NSString, after index: Int) -> unichar? {
        var cursor = index
        while cursor < source.length {
            let character = source.character(at: cursor)
            if character == 32 || character == 9 || character == 10 || character == 13 {
                cursor += 1
                continue
            }
            return character
        }
        return nil
    }

    private static func matches(_ source: NSString, at index: Int, string: String) -> Bool {
        let length = (string as NSString).length
        guard index >= 0, index + length <= source.length else { return false }
        return source.substring(with: NSRange(location: index, length: length)) == string
    }

    private static func find(
        _ source: NSString,
        from index: Int,
        string: String,
        limit: Int? = nil
    ) -> Int? {
        let needleLength = (string as NSString).length
        let end = min(source.length, index + (limit ?? source.length))
        var cursor = index
        while cursor + needleLength <= end {
            if source.substring(with: NSRange(location: cursor, length: needleLength)) == string {
                return cursor + needleLength
            }
            cursor += 1
        }
        return nil
    }

    private static func tagEnd(in source: NSString, from index: Int) -> Int? {
        var cursor = index + 1
        var quote: unichar = 0

        while cursor < source.length {
            let character = source.character(at: cursor)
            if quote != 0 {
                if character == quote {
                    quote = 0
                }
            } else if character == 34 || character == 39 {
                quote = character
            } else if character == 62 {
                return cursor
            }
            cursor += 1
        }
        return nil
    }

    private static func forEachLine(
        in source: NSString,
        _ body: (NSRange, String) -> Void
    ) {
        var start = 0
        while start < source.length {
            let lineRange = source.lineRange(for: NSRange(location: start, length: 0))
            var end = NSMaxRange(lineRange)
            while end > start {
                let character = source.character(at: end - 1)
                if character == 10 || character == 13 {
                    end -= 1
                } else {
                    break
                }
            }
            let contentRange = NSRange(location: start, length: max(0, end - start))
            body(contentRange, source.substring(with: contentRange))
            let next = NSMaxRange(lineRange)
            if next <= start {
                break
            }
            start = next
        }
    }

    private static func fencePrefix(in line: String) -> String? {
        if line.hasPrefix("```") {
            return "```"
        }
        if line.hasPrefix("~~~") {
            return "~~~"
        }
        return nil
    }

    private static func offset(_ range: NSRange, by amount: Int) -> NSRange {
        guard range.location != NSNotFound else { return range }
        return NSRange(location: range.location + amount, length: range.length)
    }

    private static func intersectsProtectedRange(_ range: NSRange, _ protected: [NSRange]) -> Bool {
        protected.contains { NSIntersectionRange($0, range).length > 0 }
    }

    private static func addColor(
        _ color: NSColor,
        range: NSRange,
        to result: NSMutableAttributedString
    ) {
        guard isValid(range, in: result) else { return }
        result.addAttribute(.foregroundColor, value: color, range: range)
    }

    private static func addBackground(
        _ color: NSColor,
        range: NSRange,
        to result: NSMutableAttributedString
    ) {
        guard isValid(range, in: result) else { return }
        result.addAttribute(.backgroundColor, value: color, range: range)
    }

    private static func isValid(_ range: NSRange, in result: NSAttributedString) -> Bool {
        guard range.location != NSNotFound, range.location >= 0, range.length > 0 else {
            return false
        }
        return NSMaxRange(range) <= result.length
    }

    private static func isWhitespace(_ character: unichar) -> Bool {
        character == 32 || character == 9 || character == 10 || character == 13
    }

    private static func isDigit(_ character: unichar) -> Bool {
        character >= 48 && character <= 57
    }

    private static func isASCIIAlpha(_ character: unichar) -> Bool {
        (character >= 65 && character <= 90) || (character >= 97 && character <= 122)
    }

    private static func isIdentifierStart(_ character: unichar) -> Bool {
        isASCIIAlpha(character) || character == 95 || character == 36 || character >= 128
    }

    private static func isIdentifierContinuation(_ character: unichar) -> Bool {
        isIdentifierStart(character) || isDigit(character)
    }

    private static func isTagNameCharacter(_ character: unichar) -> Bool {
        isIdentifierContinuation(character) || character == 45 || character == 58
    }
}
