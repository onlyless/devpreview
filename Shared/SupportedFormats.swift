import Foundation

struct FormatItem: Identifiable, Hashable {
    let name: String
    let extensions: [String]

    var id: String { name }

    var extensionSummary: String {
        extensions.map { ".\($0)" }.joined(separator: "  ")
    }
}

struct FormatCategory: Identifiable {
    let title: String
    let symbol: String
    let items: [FormatItem]

    var id: String { title }
}

enum SupportedFormats {
    static let categories: [FormatCategory] = [
        FormatCategory(
            title: "编程语言",
            symbol: "chevron.left.forwardslash.chevron.right",
            items: [
                FormatItem(name: "Swift", extensions: ["swift", "swiftinterface"]),
                FormatItem(name: "Objective-C / C / C++", extensions: ["h", "m", "mm", "c", "cc", "cpp", "cxx", "hpp", "hh", "hxx"]),
                FormatItem(name: "Go", extensions: ["go"]),
                FormatItem(name: "Rust", extensions: ["rs"]),
                FormatItem(name: "Python", extensions: ["py", "pyw", "pyi"]),
                FormatItem(name: "JavaScript", extensions: ["js", "mjs", "cjs", "jsx"]),
                FormatItem(name: "TypeScript", extensions: ["ts", "mts", "cts", "tsx"]),
                FormatItem(name: "Vue / Svelte", extensions: ["vue", "svelte"]),
                FormatItem(name: "Java / Kotlin", extensions: ["java", "kt", "kts"]),
                FormatItem(name: "C# / Dart", extensions: ["cs", "dart"]),
                FormatItem(name: "Ruby / PHP", extensions: ["rb", "rake", "gemspec", "php"]),
                FormatItem(name: "Shell", extensions: ["sh", "bash", "zsh", "fish", "ksh"]),
                FormatItem(name: "SQL", extensions: ["sql"]),
                FormatItem(name: "Lua / Zig", extensions: ["lua", "zig"]),
                FormatItem(name: "Scala / Groovy", extensions: ["scala", "sc", "sbt", "groovy", "gradle"]),
                FormatItem(name: "Elixir / Erlang", extensions: ["ex", "exs", "erl", "hrl"]),
                FormatItem(name: "Haskell / Clojure", extensions: ["hs", "lhs", "clj", "cljs", "cljc", "edn"]),
                FormatItem(name: "Solidity", extensions: ["sol"]),
                FormatItem(name: "PowerShell / Batch", extensions: ["ps1", "psm1", "bat", "cmd"]),
                FormatItem(name: "Assembly / R / Julia", extensions: ["asm", "s", "r", "jl"]),
                FormatItem(name: "Vim / Metal / LaTeX", extensions: ["vim", "metal", "tex"]),
                FormatItem(name: "Starlark / Bazel", extensions: ["bzl", "bazel"]),
            ]
        ),
        FormatCategory(
            title: "配置与数据",
            symbol: "gearshape.2",
            items: [
                FormatItem(name: "JSON", extensions: ["json", "jsonc", "json5", "geojson", "webmanifest", "jsonl", "ndjson", "har"]),
                FormatItem(name: "YAML", extensions: ["yaml", "yml"]),
                FormatItem(name: "TOML", extensions: ["toml"]),
                FormatItem(name: "XML / Plist", extensions: ["xml", "xsl", "xslt", "plist", "entitlements", "xcscheme"]),
                FormatItem(name: "INI / Properties", extensions: ["ini", "cfg", "conf", "properties", "env", "xcconfig"]),
                FormatItem(name: "Dockerfile", extensions: ["dockerfile", "containerfile"]),
                FormatItem(name: "Makefile", extensions: ["mk", "mak"]),
                FormatItem(name: "Terraform / HCL", extensions: ["tf", "tfvars", "hcl"]),
                FormatItem(name: "GraphQL", extensions: ["graphql", "graphqls", "gql"]),
                FormatItem(name: "Protocol Buffers", extensions: ["proto"]),
                FormatItem(name: "Jsonnet / Prisma", extensions: ["jsonnet", "libsonnet", "prisma"]),
                FormatItem(name: "Apple 工程资源", extensions: ["strings", "stringsdict", "xcprivacy", "modulemap", "podspec", "xib", "storyboard", "mobileconfig"]),
                FormatItem(name: "C# / .NET 工程", extensions: ["csproj", "fsproj", "vbproj", "props", "targets", "sln", "resx", "xaml", "cshtml", "razor"]),
                FormatItem(name: "CMake", extensions: ["cmake"]),
                FormatItem(name: "Nix", extensions: ["nix"]),
                FormatItem(name: "Xcode / Lock / HTTP", extensions: ["pbxproj", "lock", "http", "ninja"]),
            ]
        ),
        FormatCategory(
            title: "压缩包与数据库",
            symbol: "archivebox",
            items: [
                FormatItem(name: "ZIP 家族", extensions: ArchiveFormats.zipExtensions),
                FormatItem(name: "TAR", extensions: ["tar"]),
                FormatItem(name: "GZIP / TAR.GZ", extensions: ["gz", "tgz", "tar.gz"]),
                FormatItem(name: "SQLite", extensions: ArchiveFormats.databaseExtensions),
            ]
        ),
        FormatCategory(
            title: "文档与日志",
            symbol: "doc.text",
            items: [
                FormatItem(name: "Markdown", extensions: ["md", "markdown", "mdx"]),
                FormatItem(name: "reStructuredText", extensions: ["rst"]),
                FormatItem(name: "AsciiDoc", extensions: ["adoc", "asciidoc"]),
                FormatItem(name: "纯文本 / 日志", extensions: ["txt", "text", "log", "out"]),
                FormatItem(name: "CSV / TSV", extensions: ["csv", "tsv"]),
                FormatItem(name: "Diff / Patch", extensions: ["diff", "patch"]),
                FormatItem(name: "Jupyter Notebook", extensions: ["ipynb"]),
                FormatItem(name: "LaTeX", extensions: ["sty", "cls"]),
                FormatItem(name: "Org / Textile", extensions: ["org", "textile"]),
                FormatItem(name: "PO 本地化", extensions: ["po"]),
            ]
        ),
    ]

    static var allExtensions: Set<String> {
        Set(categories.flatMap { category in
            category.items.flatMap { $0.extensions }
        })
    }

    static var formatCount: Int {
        categories.reduce(0) { $0 + $1.items.count }
    }
}
