import Foundation

enum SyntaxKind {
    case code
    case json
    case yaml
    case toml
    case ini
    case markdown
    case markup
    case css
    case diff
    case makefile
    case plain
}

struct BlockComment {
    let start: String
    let end: String
}

struct LanguageProfile {
    let id: String
    let displayName: String
    let kind: SyntaxKind
    let keywords: Set<String>
    let types: Set<String>
    let lineComments: [String]
    let blockComments: [BlockComment]
    let stringDelimiters: [String]
    let multilineStringDelimiters: Set<String>
    let supportsHashDirectives: Bool
    let supportsAnnotations: Bool
    let supportsDollarVariables: Bool
    let supportsMacroBang: Bool
    let hashCommentNeedsWhitespace: Bool
    let caseInsensitiveKeywords: Bool
    let colorsCapitalizedTypes: Bool
    let nestedBlockComments: Bool

    init(
        id: String,
        displayName: String,
        kind: SyntaxKind = .code,
        keywords: [String] = [],
        types: [String] = [],
        lineComments: [String] = ["//"],
        blockComments: [BlockComment] = [BlockComment(start: "/*", end: "*/")],
        stringDelimiters: [String] = ["\"", "'"],
        multilineStringDelimiters: [String] = [],
        supportsHashDirectives: Bool = false,
        supportsAnnotations: Bool = false,
        supportsDollarVariables: Bool = false,
        supportsMacroBang: Bool = false,
        hashCommentNeedsWhitespace: Bool = false,
        caseInsensitiveKeywords: Bool = false,
        colorsCapitalizedTypes: Bool = true,
        nestedBlockComments: Bool = false
    ) {
        self.id = id
        self.displayName = displayName
        self.kind = kind

        if caseInsensitiveKeywords {
            self.keywords = Set(keywords.map { $0.lowercased() })
            self.types = Set(types.map { $0.lowercased() })
        } else {
            self.keywords = Set(keywords)
            self.types = Set(types)
        }

        self.lineComments = lineComments
        self.blockComments = blockComments
        self.stringDelimiters = stringDelimiters.sorted {
            if $0.count == $1.count {
                return $0 < $1
            }
            return $0.count > $1.count
        }
        self.multilineStringDelimiters = Set(multilineStringDelimiters)
        self.supportsHashDirectives = supportsHashDirectives
        self.supportsAnnotations = supportsAnnotations
        self.supportsDollarVariables = supportsDollarVariables
        self.supportsMacroBang = supportsMacroBang
        self.hashCommentNeedsWhitespace = hashCommentNeedsWhitespace
        self.caseInsensitiveKeywords = caseInsensitiveKeywords
        self.colorsCapitalizedTypes = colorsCapitalizedTypes
        self.nestedBlockComments = nestedBlockComments
    }
}
