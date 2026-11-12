import Foundation

extension LanguageProfile {
    static let plain = LanguageProfile(
        id: "plain",
        displayName: "Plain Text",
        kind: .plain,
        lineComments: [],
        blockComments: [],
        stringDelimiters: [],
        colorsCapitalizedTypes: false
    )

    static let swift = LanguageProfile(
        id: "swift",
        displayName: "Swift",
        keywords: [
            "associatedtype", "class", "deinit", "enum", "extension", "fileprivate",
            "func", "import", "init", "inout", "internal", "let", "open", "operator",
            "private", "precedencegroup", "protocol", "public", "rethrows", "static",
            "struct", "subscript", "typealias", "var", "break", "case", "continue",
            "default", "defer", "do", "else", "fallthrough", "for", "guard", "if",
            "in", "repeat", "return", "switch", "where", "while", "as", "catch",
            "false", "is", "nil", "super", "self", "Self", "throw", "throws", "true",
            "try", "async", "await", "actor", "some", "any", "nonisolated", "isolated",
            "consuming", "borrowing", "package", "macro", "convenience", "dynamic",
            "final", "indirect", "infix", "lazy", "mutating", "nonmutating", "optional",
            "override", "postfix", "prefix", "required", "unowned", "weak",
        ],
        types: [
            "Int", "Int8", "Int16", "Int32", "Int64", "UInt", "UInt8", "UInt16",
            "UInt32", "UInt64", "Double", "Float", "String", "Bool", "Character",
            "Array", "Dictionary", "Set", "Optional", "Result", "Error", "Void",
            "Never", "Any", "AnyObject", "URL", "Data", "Date", "UUID",
        ],
        blockComments: [BlockComment(start: "/*", end: "*/")],
        stringDelimiters: ["\"\"\"", "\""],
        multilineStringDelimiters: ["\"\"\""],
        supportsHashDirectives: true,
        supportsAnnotations: true,
        nestedBlockComments: true
    )

    static let objectiveC = LanguageProfile(
        id: "objc",
        displayName: "Objective-C",
        keywords: [
            "auto", "break", "case", "char", "const", "continue", "default", "do",
            "double", "else", "enum", "extern", "float", "for", "goto", "if", "inline",
            "int", "long", "register", "restrict", "return", "short", "signed",
            "sizeof", "static", "struct", "switch", "typedef", "union", "unsigned",
            "void", "volatile", "while", "id", "instancetype", "BOOL", "YES", "NO",
            "nil", "Nil", "self", "super", "weak", "strong", "copy", "assign",
            "nonatomic", "atomic", "readonly", "readwrite", "nullable", "nonnull",
            "class", "protocol", "interface", "implementation", "end", "property",
            "synthesize", "dynamic", "selector", "optional", "required", "try",
            "catch", "finally", "throw", "synchronized", "autoreleasepool",
        ],
        types: [
            "NSObject", "NSString", "NSArray", "NSDictionary", "NSSet", "NSNumber",
            "NSData", "NSURL", "NSError", "UIView", "UIViewController", "CGFloat",
            "NSInteger", "NSUInteger", "CGRect", "CGPoint", "CGSize",
        ],
        supportsHashDirectives: true,
        supportsAnnotations: true
    )

    static let c = LanguageProfile(
        id: "c",
        displayName: "C",
        keywords: [
            "auto", "break", "case", "char", "const", "continue", "default", "do",
            "double", "else", "enum", "extern", "float", "for", "goto", "if",
            "inline", "int", "long", "register", "restrict", "return", "short",
            "signed", "sizeof", "static", "struct", "switch", "typedef", "union",
            "unsigned", "void", "volatile", "while", "bool", "true", "false",
            "NULL", "size_t",
        ],
        types: [
            "int8_t", "int16_t", "int32_t", "int64_t", "uint8_t", "uint16_t",
            "uint32_t", "uint64_t", "FILE", "va_list",
        ],
        supportsHashDirectives: true
    )

    static let cpp = LanguageProfile(
        id: "cpp",
        displayName: "C++",
        keywords: [
            "alignas", "alignof", "and", "asm", "auto", "bitand", "bitor", "bool",
            "break", "case", "catch", "char", "char8_t", "char16_t", "char32_t",
            "class", "compl", "concept", "const", "consteval", "constexpr",
            "constinit", "const_cast", "continue", "co_await", "co_return",
            "co_yield", "decltype", "default", "delete", "do", "double",
            "dynamic_cast", "else", "enum", "explicit", "export", "extern", "false",
            "float", "for", "friend", "goto", "if", "inline", "int", "long",
            "mutable", "namespace", "new", "noexcept", "not", "nullptr", "operator",
            "or", "private", "protected", "public", "register", "reinterpret_cast",
            "requires", "return", "short", "signed", "sizeof", "static",
            "static_assert", "static_cast", "struct", "switch", "template", "this",
            "thread_local", "throw", "true", "try", "typedef", "typeid", "typename",
            "union", "unsigned", "using", "virtual", "void", "volatile", "wchar_t",
            "while", "override", "final",
        ],
        types: [
            "std", "string", "vector", "map", "set", "unique_ptr", "shared_ptr",
            "optional", "variant", "size_t", "int8_t", "int16_t", "int32_t",
            "int64_t", "uint8_t", "uint16_t", "uint32_t", "uint64_t",
        ],
        supportsHashDirectives: true
    )

    static let csharp = LanguageProfile(
        id: "csharp",
        displayName: "C#",
        keywords: [
            "abstract", "as", "base", "bool", "break", "byte", "case", "catch",
            "char", "checked", "class", "const", "continue", "decimal", "default",
            "delegate", "do", "double", "else", "enum", "event", "explicit",
            "extern", "false", "finally", "fixed", "float", "for", "foreach",
            "goto", "if", "implicit", "in", "int", "interface", "internal", "is",
            "lock", "long", "namespace", "new", "null", "object", "operator", "out",
            "override", "params", "private", "protected", "public", "readonly",
            "ref", "return", "sbyte", "sealed", "short", "sizeof", "stackalloc",
            "static", "string", "struct", "switch", "this", "throw", "true", "try",
            "typeof", "uint", "ulong", "unchecked", "unsafe", "ushort", "using",
            "virtual", "void", "volatile", "while", "async", "await", "var",
            "record", "init", "get", "set", "value", "dynamic", "yield",
        ],
        types: [
            "String", "Int32", "Int64", "Double", "Boolean", "Object", "List",
            "Dictionary", "IEnumerable", "Task", "DateTime", "TimeSpan", "Guid",
        ],
        supportsHashDirectives: true,
        supportsAnnotations: false
    )

    static let go = LanguageProfile(
        id: "go",
        displayName: "Go",
        keywords: [
            "break", "case", "chan", "const", "continue", "default", "defer",
            "else", "fallthrough", "for", "func", "go", "goto", "if", "import",
            "interface", "map", "package", "range", "return", "select", "struct",
            "switch", "type", "var", "true", "false", "nil", "iota",
        ],
        types: [
            "bool", "byte", "complex64", "complex128", "error", "float32",
            "float64", "int", "int8", "int16", "int32", "int64", "rune", "string",
            "uint", "uint8", "uint16", "uint32", "uint64", "uintptr", "any",
            "comparable",
        ],
        blockComments: [BlockComment(start: "/*", end: "*/")],
        stringDelimiters: ["`", "\"", "'"],
        multilineStringDelimiters: ["`"],
        supportsHashDirectives: false
    )

    static let rust = LanguageProfile(
        id: "rust",
        displayName: "Rust",
        keywords: [
            "as", "async", "await", "break", "const", "continue", "crate", "dyn",
            "else", "enum", "extern", "false", "fn", "for", "if", "impl", "in",
            "let", "loop", "match", "mod", "move", "mut", "pub", "ref", "return",
            "self", "Self", "static", "struct", "super", "trait", "true", "type",
            "unsafe", "use", "where", "while", "yield", "box", "macro", "union",
        ],
        types: [
            "i8", "i16", "i32", "i64", "i128", "isize", "u8", "u16", "u32",
            "u64", "u128", "usize", "f32", "f64", "bool", "char", "str", "String",
            "Vec", "Option", "Result", "Box", "Rc", "Arc", "RefCell", "Cell",
            "HashMap", "HashSet", "BTreeMap", "BTreeSet",
        ],
        stringDelimiters: ["\"", "'"],
        multilineStringDelimiters: ["\""],
        supportsHashDirectives: true,
        supportsMacroBang: true,
        nestedBlockComments: true
    )

    static let python = LanguageProfile(
        id: "python",
        displayName: "Python",
        keywords: [
            "and", "as", "assert", "async", "await", "break", "class", "continue",
            "def", "del", "elif", "else", "except", "False", "finally", "for",
            "from", "global", "if", "import", "in", "is", "lambda", "None",
            "nonlocal", "not", "or", "pass", "raise", "return", "True", "try",
            "while", "with", "yield", "match", "case", "self", "cls",
        ],
        types: [
            "int", "float", "str", "bool", "list", "dict", "set", "tuple", "bytes",
            "bytearray", "object", "type", "Exception", "ValueError", "TypeError",
            "super", "staticmethod", "classmethod", "property",
        ],
        lineComments: ["#"],
        blockComments: [],
        stringDelimiters: ["\"\"\"", "'''", "\"", "'"],
        multilineStringDelimiters: ["\"\"\"", "'''"],
        supportsAnnotations: true
    )

    static let javascript = LanguageProfile(
        id: "javascript",
        displayName: "JavaScript",
        keywords: [
            "async", "await", "break", "case", "catch", "class", "const",
            "continue", "debugger", "default", "delete", "do", "else", "export",
            "extends", "false", "finally", "for", "from", "function", "get", "if",
            "import", "in", "instanceof", "let", "new", "null", "of", "return",
            "set", "static", "super", "switch", "this", "throw", "true", "try",
            "typeof", "undefined", "var", "void", "while", "with", "yield",
        ],
        types: [
            "Array", "Promise", "Record", "Partial", "Required", "Readonly", "Map",
            "Set", "Date", "RegExp", "Object", "String", "Number", "Boolean",
            "Symbol", "BigInt", "Error", "JSON", "Math",
        ],
        stringDelimiters: ["`", "\"", "'"],
        multilineStringDelimiters: ["`"],
        supportsHashDirectives: false,
        supportsMacroBang: false
    )

    static let typescript = LanguageProfile(
        id: "typescript",
        displayName: "TypeScript",
        keywords: [
            "abstract", "any", "as", "asserts", "async", "await", "boolean",
            "break", "case", "catch", "class", "const", "constructor", "continue",
            "debugger", "declare", "default", "delete", "do", "else", "enum",
            "export", "extends", "false", "finally", "for", "from", "function",
            "get", "if", "implements", "import", "in", "infer", "instanceof",
            "interface", "is", "keyof", "let", "namespace", "never", "new", "null",
            "number", "object", "of", "private", "protected", "public", "readonly",
            "return", "satisfies", "set", "static", "string", "super", "switch",
            "symbol", "this", "throw", "true", "try", "type", "typeof", "undefined",
            "unique", "unknown", "var", "void", "while", "with", "yield",
        ],
        types: [
            "Array", "Promise", "Record", "Partial", "Required", "Readonly", "Map",
            "Set", "Date", "RegExp", "Object", "String", "Number", "Boolean",
            "Symbol", "BigInt", "Error", "JSON", "Math",
        ],
        stringDelimiters: ["`", "\"", "'"],
        multilineStringDelimiters: ["`"],
        supportsHashDirectives: false
    )

    static let java = LanguageProfile(
        id: "java",
        displayName: "Java",
        keywords: [
            "abstract", "assert", "boolean", "break", "byte", "case", "catch",
            "char", "class", "const", "continue", "default", "do", "double",
            "else", "enum", "extends", "final", "finally", "float", "for", "goto",
            "if", "implements", "import", "instanceof", "int", "interface", "long",
            "native", "new", "package", "private", "protected", "public", "return",
            "short", "static", "strictfp", "super", "switch", "synchronized",
            "this", "throw", "throws", "transient", "try", "void", "volatile",
            "while", "var", "record", "sealed", "permits", "yield", "true",
            "false", "null",
        ],
        types: [
            "String", "Integer", "Long", "Double", "Float", "Boolean", "Object",
            "List", "Map", "Set", "Optional", "Stream", "Thread", "Runnable",
        ],
        supportsAnnotations: true
    )

    static let kotlin = LanguageProfile(
        id: "kotlin",
        displayName: "Kotlin",
        keywords: [
            "abstract", "actual", "annotation", "as", "break", "by", "catch",
            "class", "companion", "const", "constructor", "continue", "crossinline",
            "data", "delegate", "do", "dynamic", "else", "enum", "expect",
            "external", "false", "field", "file", "final", "finally", "for",
            "fun", "get", "if", "import", "in", "infix", "init", "inline", "inner",
            "interface", "internal", "is", "lateinit", "noinline", "null", "object",
            "open", "operator", "out", "override", "package", "param", "private",
            "protected", "public", "receiver", "reified", "return", "sealed", "set",
            "setparam", "super", "suspend", "tailrec", "this", "throw", "true",
            "try", "typealias", "typeof", "val", "var", "vararg", "when", "where",
            "while", "yield",
        ],
        types: [
            "String", "Int", "Long", "Double", "Float", "Boolean", "Any", "Unit",
            "Nothing", "List", "Map", "Set", "Array", "Sequence",
        ],
        stringDelimiters: ["\"\"\"", "\"", "'"],
        multilineStringDelimiters: ["\"\"\""],
        supportsAnnotations: true
    )

    static let ruby = LanguageProfile(
        id: "ruby",
        displayName: "Ruby",
        keywords: [
            "BEGIN", "END", "alias", "and", "begin", "break", "case", "class",
            "def", "defined?", "do", "else", "elsif", "end", "ensure", "false",
            "for", "if", "in", "module", "next", "nil", "not", "or", "redo",
            "rescue", "retry", "return", "self", "super", "then", "true", "undef",
            "unless", "until", "when", "while", "yield", "require",
            "require_relative", "attr_accessor", "attr_reader", "attr_writer",
            "include", "extend", "prepend",
        ],
        types: ["String", "Integer", "Float", "Array", "Hash", "Symbol", "Proc"],
        lineComments: ["#"],
        blockComments: [],
        stringDelimiters: ["\"", "'"],
        multilineStringDelimiters: ["\"", "'"],
        supportsAnnotations: false
    )

    static let php = LanguageProfile(
        id: "php",
        displayName: "PHP",
        keywords: [
            "abstract", "and", "array", "as", "break", "callable", "case", "catch",
            "class", "clone", "const", "continue", "declare", "default", "do",
            "echo", "else", "elseif", "empty", "enddeclare", "endfor", "endforeach",
            "endif", "endswitch", "endwhile", "eval", "exit", "extends", "final",
            "finally", "fn", "for", "foreach", "function", "global", "goto", "if",
            "implements", "include", "include_once", "instanceof", "insteadof",
            "interface", "isset", "list", "match", "namespace", "new", "or",
            "print", "private", "protected", "public", "readonly", "require",
            "require_once", "return", "static", "switch", "throw", "trait", "try",
            "unset", "use", "var", "while", "xor", "yield", "true", "false", "null",
        ],
        types: ["string", "int", "float", "bool", "array", "object", "mixed", "void"],
        lineComments: ["//", "#"],
        blockComments: [BlockComment(start: "/*", end: "*/")],
        stringDelimiters: ["\"", "'"],
        multilineStringDelimiters: ["\"", "'"],
        supportsAnnotations: false,
        supportsDollarVariables: true
    )

    static let shell = LanguageProfile(
        id: "shell",
        displayName: "Shell",
        keywords: [
            "if", "then", "else", "elif", "fi", "for", "while", "until", "do",
            "done", "case", "esac", "function", "in", "select", "time", "coproc",
            "break", "continue", "return", "exit", "export", "readonly", "local",
            "declare", "typeset", "unset", "shift", "source", "alias", "unalias",
            "eval", "exec", "trap", "set", "test",
        ],
        types: ["true", "false"],
        lineComments: ["#"],
        blockComments: [],
        stringDelimiters: ["\"", "'", "`"],
        multilineStringDelimiters: ["\"", "'"],
        supportsDollarVariables: true,
        hashCommentNeedsWhitespace: true,
        colorsCapitalizedTypes: false
    )

    static let sql = LanguageProfile(
        id: "sql",
        displayName: "SQL",
        keywords: [
            "select", "from", "where", "and", "or", "not", "insert", "into",
            "values", "update", "set", "delete", "create", "table", "alter", "drop",
            "index", "view", "join", "inner", "left", "right", "full", "outer", "on",
            "group", "by", "order", "having", "limit", "offset", "union", "all",
            "distinct", "as", "exists", "between", "like", "in", "is", "null",
            "case", "when", "then", "else", "end", "begin", "commit", "rollback",
            "transaction", "primary", "key", "foreign", "references", "default",
            "unique", "check", "constraint", "with", "recursive", "explain",
            "analyze", "vacuum", "grant", "revoke", "truncate", "replace",
        ],
        types: [
            "int", "integer", "varchar", "char", "text", "boolean", "date",
            "timestamp", "decimal", "numeric", "bigint", "smallint", "json",
            "jsonb", "uuid", "blob",
        ],
        lineComments: ["--", "#"],
        blockComments: [BlockComment(start: "/*", end: "*/")],
        stringDelimiters: ["'", "\"", "`"],
        hashCommentNeedsWhitespace: true,
        caseInsensitiveKeywords: true,
        colorsCapitalizedTypes: false
    )

    static let html = LanguageProfile(
        id: "html",
        displayName: "HTML",
        kind: .markup,
        lineComments: [],
        blockComments: [],
        stringDelimiters: [],
        colorsCapitalizedTypes: false
    )

    static let xml = LanguageProfile(
        id: "xml",
        displayName: "XML",
        kind: .markup,
        lineComments: [],
        blockComments: [],
        stringDelimiters: [],
        colorsCapitalizedTypes: false
    )

    static let vue = LanguageProfile(
        id: "vue",
        displayName: "Vue",
        kind: .markup,
        lineComments: [],
        blockComments: [],
        stringDelimiters: [],
        colorsCapitalizedTypes: false
    )

    static let svelte = LanguageProfile(
        id: "svelte",
        displayName: "Svelte",
        kind: .markup,
        lineComments: [],
        blockComments: [],
        stringDelimiters: [],
        colorsCapitalizedTypes: false
    )

    static let css = LanguageProfile(
        id: "css",
        displayName: "CSS",
        kind: .css,
        keywords: ["important", "inherit", "initial", "unset", "revert", "none", "auto"],
        lineComments: [],
        blockComments: [BlockComment(start: "/*", end: "*/")],
        stringDelimiters: ["\"", "'"],
        colorsCapitalizedTypes: false
    )

    static let json = LanguageProfile(
        id: "json",
        displayName: "JSON",
        kind: .json,
        keywords: ["true", "false", "null"],
        lineComments: ["//"],
        blockComments: [BlockComment(start: "/*", end: "*/")],
        stringDelimiters: ["\""],
        colorsCapitalizedTypes: false
    )

    static let yaml = LanguageProfile(
        id: "yaml",
        displayName: "YAML",
        kind: .yaml,
        keywords: ["true", "false", "null", "yes", "no", "on", "off", "~"],
        lineComments: ["#"],
        blockComments: [],
        stringDelimiters: ["\"", "'"],
        hashCommentNeedsWhitespace: true,
        colorsCapitalizedTypes: false
    )

    static let toml = LanguageProfile(
        id: "toml",
        displayName: "TOML",
        kind: .toml,
        keywords: ["true", "false"],
        lineComments: ["#"],
        blockComments: [],
        stringDelimiters: ["\"\"\"", "'''", "\"", "'"],
        multilineStringDelimiters: ["\"\"\"", "'''"],
        colorsCapitalizedTypes: false
    )

    static let ini = LanguageProfile(
        id: "ini",
        displayName: "INI / Properties",
        kind: .ini,
        keywords: ["true", "false", "yes", "no", "on", "off"],
        lineComments: ["#", ";"],
        blockComments: [],
        stringDelimiters: ["\"", "'"],
        colorsCapitalizedTypes: false
    )

    static let markdown = LanguageProfile(
        id: "markdown",
        displayName: "Markdown",
        kind: .markdown,
        lineComments: [],
        blockComments: [],
        stringDelimiters: [],
        colorsCapitalizedTypes: false
    )

    static let diff = LanguageProfile(
        id: "diff",
        displayName: "Diff",
        kind: .diff,
        lineComments: [],
        blockComments: [],
        stringDelimiters: [],
        colorsCapitalizedTypes: false
    )

    static let makefile = LanguageProfile(
        id: "makefile",
        displayName: "Makefile",
        kind: .makefile,
        keywords: [
            "include", "define", "endef", "export", "override", "ifeq", "ifneq",
            "ifdef", "ifndef", "endif", "else", "vpath",
        ],
        lineComments: ["#"],
        blockComments: [],
        stringDelimiters: ["\"", "'"],
        colorsCapitalizedTypes: false
    )

    static let dockerfile = LanguageProfile(
        id: "dockerfile",
        displayName: "Dockerfile",
        keywords: [
            "FROM", "RUN", "CMD", "LABEL", "MAINTAINER", "EXPOSE", "ENV", "ADD",
            "COPY", "ENTRYPOINT", "VOLUME", "USER", "WORKDIR", "ARG", "ONBUILD",
            "STOPSIGNAL", "HEALTHCHECK", "SHELL", "AS",
        ],
        lineComments: ["#"],
        blockComments: [],
        stringDelimiters: ["\"", "'"],
        hashCommentNeedsWhitespace: true,
        caseInsensitiveKeywords: true,
        colorsCapitalizedTypes: false
    )

    static let terraform = LanguageProfile(
        id: "terraform",
        displayName: "Terraform / HCL",
        keywords: [
            "resource", "data", "variable", "output", "module", "provider", "locals",
            "terraform", "for_each", "count", "depends_on", "lifecycle", "dynamic",
            "true", "false", "null", "if", "for", "in",
        ],
        lineComments: ["#", "//"],
        blockComments: [BlockComment(start: "/*", end: "*/")],
        stringDelimiters: ["\"", "'"],
        colorsCapitalizedTypes: false
    )

    static let graphql = LanguageProfile(
        id: "graphql",
        displayName: "GraphQL",
        keywords: [
            "query", "mutation", "subscription", "fragment", "type", "interface",
            "union", "enum", "input", "scalar", "schema", "extend", "directive",
            "on", "true", "false", "null",
        ],
        lineComments: ["#"],
        blockComments: [],
        stringDelimiters: ["\"\"\"", "\""],
        multilineStringDelimiters: ["\"\"\""],
        colorsCapitalizedTypes: false
    )

    static let protobuf = LanguageProfile(
        id: "protobuf",
        displayName: "Protocol Buffers",
        keywords: [
            "syntax", "package", "import", "option", "message", "enum", "service",
            "rpc", "returns", "repeated", "optional", "required", "oneof", "map",
            "reserved", "extend", "extensions", "to", "max", "public", "weak",
            "true", "false",
        ],
        lineComments: ["//"],
        blockComments: [BlockComment(start: "/*", end: "*/")],
        stringDelimiters: ["\"", "'"],
        colorsCapitalizedTypes: false
    )

    static let cmake = LanguageProfile(
        id: "cmake",
        displayName: "CMake",
        keywords: [
            "cmake_minimum_required", "project", "add_executable", "add_library",
            "target_link_libraries", "target_include_directories", "set", "if",
            "elseif", "else", "endif", "foreach", "endforeach", "function",
            "endfunction", "macro", "endmacro", "option", "find_package", "install",
            "include", "message", "list", "string", "file", "configure_file",
        ],
        lineComments: ["#"],
        blockComments: [],
        stringDelimiters: ["\"", "'"],
        caseInsensitiveKeywords: true,
        colorsCapitalizedTypes: false
    )

    static let lua = LanguageProfile(
        id: "lua",
        displayName: "Lua",
        keywords: [
            "and", "break", "do", "else", "elseif", "end", "false", "for",
            "function", "goto", "if", "in", "local", "nil", "not", "or", "repeat",
            "return", "then", "true", "until", "while",
        ],
        types: ["string", "number", "boolean", "table", "function", "thread", "userdata"],
        lineComments: ["--"],
        blockComments: [BlockComment(start: "--[[", end: "]]")],
        stringDelimiters: ["\"", "'"],
        colorsCapitalizedTypes: false
    )

    static let nix = LanguageProfile(
        id: "nix",
        displayName: "Nix",
        keywords: [
            "let", "in", "with", "rec", "inherit", "if", "then", "else", "assert",
            "or", "map", "filter", "builtins", "import", "true", "false", "null",
        ],
        lineComments: ["#"],
        blockComments: [BlockComment(start: "/*", end: "*/")],
        stringDelimiters: ["''", "\""],
        multilineStringDelimiters: ["''"],
        colorsCapitalizedTypes: false
    )

    static let scala = LanguageProfile(
        id: "scala",
        displayName: "Scala",
        keywords: [
            "abstract", "case", "catch", "class", "def", "do", "else", "enum",
            "extends", "false", "final", "finally", "for", "given", "if",
            "implicit", "import", "lazy", "match", "new", "null", "object",
            "override", "package", "private", "protected", "return", "sealed",
            "super", "then", "this", "throw", "trait", "true", "try", "type",
            "using", "val", "var", "while", "with", "yield", "export",
        ],
        types: ["String", "Int", "Long", "Double", "Boolean", "Option", "List", "Map", "Set"],
        stringDelimiters: ["\"\"\"", "\"", "'"],
        multilineStringDelimiters: ["\"\"\""],
        supportsAnnotations: true
    )

    static let elixir = LanguageProfile(
        id: "elixir",
        displayName: "Elixir",
        keywords: [
            "def", "defp", "defmodule", "defstruct", "defmacro", "defguard",
            "do", "end", "fn", "case", "cond", "if", "unless", "for", "with",
            "try", "rescue", "catch", "after", "raise", "import", "require", "use",
            "alias", "__MODULE__", "true", "false", "nil", "when", "in",
        ],
        types: ["String", "Integer", "Float", "List", "Map", "Tuple", "Atom", "PID"],
        lineComments: ["#"],
        blockComments: [],
        stringDelimiters: ["\"\"\"", "\"", "'"],
        multilineStringDelimiters: ["\"\"\""],
        colorsCapitalizedTypes: true
    )

    static let erlang = LanguageProfile(
        id: "erlang",
        displayName: "Erlang",
        keywords: [
            "after", "begin", "case", "catch", "cond", "end", "fun", "if", "let",
            "of", "query", "receive", "try", "when", "andalso", "orelse", "not",
            "and", "or", "true", "false",
        ],
        lineComments: ["%"],
        blockComments: [],
        stringDelimiters: ["\"", "'"],
        colorsCapitalizedTypes: true
    )

    static let haskell = LanguageProfile(
        id: "haskell",
        displayName: "Haskell",
        keywords: [
            "case", "class", "data", "default", "deriving", "do", "else", "if",
            "import", "in", "infix", "infixl", "infixr", "instance", "let",
            "module", "newtype", "of", "then", "type", "where", "forall", "mdo",
            "proc", "rec",
        ],
        types: ["Int", "Integer", "Float", "Double", "Bool", "Char", "String", "Maybe", "Either", "IO"],
        lineComments: ["--"],
        blockComments: [BlockComment(start: "{-", end: "-}")],
        stringDelimiters: ["\"", "'"],
        colorsCapitalizedTypes: true
    )

    static let clojure = LanguageProfile(
        id: "clojure",
        displayName: "Clojure",
        keywords: [
            "def", "defn", "defmacro", "fn", "let", "if", "do", "loop", "recur",
            "case", "cond", "when", "condp", "and", "or", "not", "nil", "true",
            "false", "ns", "require", "import", "try", "catch", "finally",
        ],
        lineComments: [";"],
        blockComments: [],
        stringDelimiters: ["\""],
        colorsCapitalizedTypes: false
    )

    static let zig = LanguageProfile(
        id: "zig",
        displayName: "Zig",
        keywords: [
            "const", "var", "fn", "pub", "struct", "enum", "union", "error", "if",
            "else", "switch", "while", "for", "return", "break", "continue",
            "defer", "errdefer", "try", "catch", "comptime", "inline", "noinline",
            "export", "extern", "test", "asm", "orelse", "and", "or",
        ],
        types: ["bool", "void", "type", "anyerror", "usize", "isize", "u8", "u16", "u32", "u64", "i8", "i16", "i32", "i64", "f32", "f64"],
        blockComments: [],
        stringDelimiters: ["\"", "'"],
        colorsCapitalizedTypes: true
    )

    static let solidity = LanguageProfile(
        id: "solidity",
        displayName: "Solidity",
        keywords: [
            "pragma", "import", "contract", "interface", "library", "function",
            "modifier", "event", "error", "struct", "enum", "mapping", "address",
            "bool", "string", "bytes", "uint", "int", "public", "private",
            "internal", "external", "pure", "view", "payable", "memory", "storage",
            "calldata", "returns", "return", "if", "else", "for", "while", "do",
            "break", "continue", "emit", "new", "delete", "try", "catch",
            "constructor", "fallback", "receive", "true", "false", "this",
        ],
        types: ["uint256", "uint128", "int256", "bytes32", "address"],
        stringDelimiters: ["\"", "'"],
        colorsCapitalizedTypes: true
    )

    static let dart = LanguageProfile(
        id: "dart",
        displayName: "Dart",
        keywords: [
            "abstract", "as", "assert", "async", "await", "break", "case", "catch",
            "class", "const", "continue", "covariant", "default", "deferred", "do",
            "dynamic", "else", "enum", "export", "extends", "extension", "external",
            "factory", "false", "final", "finally", "for", "get", "hide", "if",
            "implements", "import", "in", "interface", "is", "late", "library",
            "mixin", "new", "null", "on", "operator", "part", "required", "rethrow",
            "return", "sealed", "set", "show", "static", "super", "switch", "sync",
            "this", "throw", "true", "try", "typedef", "var", "void", "while",
            "with", "yield",
        ],
        types: ["String", "int", "double", "bool", "List", "Map", "Set", "Future", "Stream", "Object"],
        stringDelimiters: ["\"\"\"", "'''", "\"", "'"],
        multilineStringDelimiters: ["\"\"\"", "'''"],
        supportsAnnotations: true
    )

    static let groovy = LanguageProfile(
        id: "groovy",
        displayName: "Groovy / Gradle",
        keywords: [
            "abstract", "as", "assert", "break", "case", "catch", "class", "const",
            "continue", "def", "default", "do", "else", "enum", "extends", "false",
            "final", "finally", "for", "goto", "if", "implements", "import", "in",
            "instanceof", "interface", "new", "null", "package", "private",
            "protected", "public", "return", "static", "super", "switch",
            "synchronized", "this", "throw", "throws", "trait", "true", "try",
            "var", "while",
        ],
        types: ["String", "Integer", "Long", "Double", "Boolean", "List", "Map", "Set"],
        stringDelimiters: ["\"\"\"", "'''", "\"", "'"],
        multilineStringDelimiters: ["\"\"\"", "'''"],
        supportsAnnotations: true
    )

    static let powershell = LanguageProfile(
        id: "powershell",
        displayName: "PowerShell",
        keywords: [
            "begin", "break", "catch", "class", "continue", "data", "do", "dynamicparam",
            "else", "elseif", "end", "enum", "exit", "filter", "finally", "for",
            "foreach", "from", "function", "if", "in", "param", "process", "return",
            "switch", "throw", "trap", "try", "until", "using", "while", "workflow",
            "true", "false", "null",
        ],
        lineComments: ["#"],
        blockComments: [BlockComment(start: "<#", end: "#>")],
        stringDelimiters: ["\"", "'"],
        multilineStringDelimiters: ["\"", "'"],
        supportsDollarVariables: true,
        caseInsensitiveKeywords: true,
        colorsCapitalizedTypes: false
    )

    static let batch = LanguageProfile(
        id: "batch",
        displayName: "Batch",
        keywords: [
            "if", "else", "for", "goto", "call", "set", "echo", "exit", "rem",
            "shift", "start", "pushd", "popd", "cd", "dir", "copy", "move", "del",
        ],
        lineComments: ["::"],
        blockComments: [],
        stringDelimiters: ["\""],
        caseInsensitiveKeywords: true,
        colorsCapitalizedTypes: false
    )

    static let assembly = LanguageProfile(
        id: "assembly",
        displayName: "Assembly",
        keywords: [
            "mov", "add", "sub", "mul", "div", "push", "pop", "call", "ret", "jmp",
            "je", "jne", "jz", "jnz", "cmp", "test", "lea", "xor", "and", "or",
            "not", "shl", "shr", "inc", "dec", "section", "global", "extern",
        ],
        lineComments: [";"],
        blockComments: [],
        stringDelimiters: ["\"", "'"],
        caseInsensitiveKeywords: true,
        colorsCapitalizedTypes: false
    )

    static let latex = LanguageProfile(
        id: "latex",
        displayName: "LaTeX",
        keywords: [
            "begin", "end", "documentclass", "usepackage", "section",
            "subsection", "subsubsection", "paragraph", "title", "author", "date",
            "maketitle", "label", "ref", "cite", "item", "itemize", "enumerate",
            "figure", "table", "centering", "caption", "includegraphics", "frac",
            "textbf", "textit", "texttt", "emph", "href", "url",
        ],
        lineComments: ["%"],
        blockComments: [],
        stringDelimiters: [],
        colorsCapitalizedTypes: false
    )

    static let r = LanguageProfile(
        id: "r",
        displayName: "R",
        keywords: [
            "if", "else", "repeat", "while", "function", "for", "in", "next",
            "break", "TRUE", "FALSE", "NULL", "Inf", "NaN", "NA", "library",
            "require", "return",
        ],
        lineComments: ["#"],
        blockComments: [],
        stringDelimiters: ["\"", "'"],
        colorsCapitalizedTypes: true
    )

    static let julia = LanguageProfile(
        id: "julia",
        displayName: "Julia",
        keywords: [
            "begin", "break", "catch", "const", "continue", "do", "else", "elseif",
            "end", "for", "function", "global", "if", "import", "in", "let",
            "local", "macro", "module", "quote", "return", "struct", "try", "using",
            "while", "true", "false", "nothing",
        ],
        lineComments: ["#"],
        blockComments: [BlockComment(start: "#=", end: "=#")],
        stringDelimiters: ["\"\"\"", "\"", "'"],
        multilineStringDelimiters: ["\"\"\""],
        supportsAnnotations: true
    )

    static let vim = LanguageProfile(
        id: "vim",
        displayName: "Vim Script",
        keywords: [
            "let", "set", "setlocal", "function", "endfunction", "if", "elseif",
            "else", "endif", "for", "endfor", "while", "endwhile", "autocmd",
            "command", "map", "nmap", "vmap", "imap", "nnoremap", "vnoremap",
            "inoremap", "call", "return", "syntax", "highlight", "augroup",
            "augroup", "execute", "silent",
        ],
        lineComments: ["\""],
        blockComments: [],
        stringDelimiters: ["'"],
        colorsCapitalizedTypes: false
    )

    static let metal = LanguageProfile(
        id: "metal",
        displayName: "Metal",
        keywords: [
            "using", "namespace", "struct", "class", "enum", "union", "kernel",
            "vertex", "fragment", "constant", "device", "threadgroup", "thread",
            "constexpr", "inline", "static", "return", "if", "else", "for", "while",
            "true", "false", "nullptr",
        ],
        types: ["float", "float2", "float3", "float4", "half", "half4", "int", "uint", "bool", "texture2d", "sampler"],
        supportsHashDirectives: true,
        supportsAnnotations: true
    )

    static let http = LanguageProfile(
        id: "http",
        displayName: "HTTP",
        keywords: [
            "GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS", "HTTP",
            "Host", "Content-Type", "Content-Length", "Authorization", "Accept",
            "User-Agent", "Cookie", "Set-Cookie", "Cache-Control",
        ],
        lineComments: ["#"],
        blockComments: [],
        stringDelimiters: [],
        caseInsensitiveKeywords: true,
        colorsCapitalizedTypes: false
    )

    static let rst = LanguageProfile(
        id: "rst",
        displayName: "reStructuredText",
        kind: .plain,
        lineComments: [],
        blockComments: [],
        stringDelimiters: [],
        colorsCapitalizedTypes: false
    )

    static let asciidoc = LanguageProfile(
        id: "asciidoc",
        displayName: "AsciiDoc",
        kind: .plain,
        lineComments: [],
        blockComments: [],
        stringDelimiters: [],
        colorsCapitalizedTypes: false
    )

    static let csv = LanguageProfile(
        id: "csv",
        displayName: "CSV",
        kind: .plain,
        lineComments: [],
        blockComments: [],
        stringDelimiters: [],
        colorsCapitalizedTypes: false
    )

    static let log = LanguageProfile(
        id: "log",
        displayName: "Log",
        kind: .plain,
        lineComments: [],
        blockComments: [],
        stringDelimiters: [],
        colorsCapitalizedTypes: false
    )

    static let jupyter = LanguageProfile(
        id: "jupyter",
        displayName: "Jupyter Notebook",
        kind: .json,
        keywords: ["true", "false", "null"],
        lineComments: [],
        blockComments: [],
        stringDelimiters: ["\""],
        colorsCapitalizedTypes: false
    )

    static let xcodeProject = LanguageProfile(
        id: "xcode-project",
        displayName: "Xcode Project",
        kind: .plain,
        lineComments: [],
        blockComments: [],
        stringDelimiters: [],
        colorsCapitalizedTypes: false
    )

    static let lockfile = LanguageProfile(
        id: "lockfile",
        displayName: "Lock File",
        kind: .plain,
        lineComments: [],
        blockComments: [],
        stringDelimiters: [],
        colorsCapitalizedTypes: false
    )
}
