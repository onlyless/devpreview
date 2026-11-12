import Foundation

enum LanguageCatalog {
    static func language(for url: URL) -> LanguageProfile {
        let name = url.lastPathComponent.lowercased()

        if let special = specialNames[name] {
            return special
        }

        if name.hasPrefix("dockerfile") || name.hasPrefix("containerfile") {
            return .dockerfile
        }
        if name.hasPrefix("makefile") {
            return .makefile
        }
        if name.hasPrefix(".env") {
            return .ini
        }
        if name.hasPrefix(".git") {
            return .plain
        }

        let fileExtension = url.pathExtension.lowercased()
        if let language = extensionMap[fileExtension] {
            return language
        }

        return .plain
    }

    static func language(forShebang line: String) -> LanguageProfile? {
        let lowercased = line.lowercased()
        guard lowercased.hasPrefix("#!") else { return nil }

        if lowercased.contains("python") {
            return .python
        }
        if lowercased.contains("node") || lowercased.contains("deno") || lowercased.contains("bun") {
            return .javascript
        }
        if lowercased.contains("ruby") {
            return .ruby
        }
        if lowercased.contains("php") {
            return .php
        }
        if lowercased.contains("lua") {
            return .lua
        }
        if lowercased.contains("bash") || lowercased.contains("zsh") || lowercased.contains("fish") {
            return .shell
        }
        if lowercased.contains("/sh") || lowercased.hasSuffix(" sh") {
            return .shell
        }
        return nil
    }

    private static let specialNames: [String: LanguageProfile] = [
        "dockerfile": .dockerfile,
        "containerfile": .dockerfile,
        "makefile": .makefile,
        "gnumakefile": .makefile,
        "justfile": .makefile,
        "cmakelists.txt": .cmake,
        "gemfile": .ruby,
        "rakefile": .ruby,
        "podfile": .ruby,
        "brewfile": .ruby,
        "vagrantfile": .ruby,
        "guardfile": .ruby,
        "fastfile": .ruby,
        "appfile": .ruby,
        "dangerfile": .ruby,
        "berksfile": .ruby,
        "jenkinsfile": .groovy,
        "gradlew": .shell,
        "mvnw": .shell,
        "pipfile": .toml,
        "cargo.lock": .toml,
        "poetry.lock": .toml,
        "pipfile.lock": .json,
        "composer.lock": .json,
        "package.resolved": .json,
        "podfile.lock": .yaml,
        "gemfile.lock": .lockfile,
        "yarn.lock": .lockfile,
        "go.sum": .lockfile,
        "go.mod": .plain,
        "readme": .markdown,
        "changelog": .markdown,
        "contributing": .markdown,
        "license": .plain,
        "notice": .plain,
        "procfile": .plain,
        ".editorconfig": .ini,
        ".gitconfig": .ini,
        ".npmrc": .ini,
        ".yarnrc": .ini,
        ".swiftformat": .ini,
        ".clang-format": .yaml,
        ".clang-tidy": .yaml,
        ".bazelrc": .plain,
        ".babelrc": .json,
        ".eslintrc": .json,
        ".prettierrc": .json,
        ".swcrc": .json,
        ".gitignore": .plain,
        ".gitattributes": .plain,
        ".gitmodules": .plain,
        ".dockerignore": .plain,
        ".npmignore": .plain,
    ]

    private static let extensionMap: [String: LanguageProfile] = [
        "swift": .swift,
        "swiftinterface": .swift,
        "h": .objectiveC,
        "m": .objectiveC,
        "mm": .objectiveC,
        "c": .c,
        "cc": .cpp,
        "cpp": .cpp,
        "cxx": .cpp,
        "hpp": .cpp,
        "hh": .cpp,
        "hxx": .cpp,
        "cs": .csharp,
        "dart": .dart,
        "go": .go,
        "rs": .rust,
        "py": .python,
        "pyw": .python,
        "pyi": .python,
        "js": .javascript,
        "mjs": .javascript,
        "cjs": .javascript,
        "jsx": .javascript,
        "ts": .typescript,
        "mts": .typescript,
        "cts": .typescript,
        "tsx": .typescript,
        "vue": .vue,
        "svelte": .svelte,
        "java": .java,
        "kt": .kotlin,
        "kts": .kotlin,
        "rb": .ruby,
        "rake": .ruby,
        "gemspec": .ruby,
        "php": .php,
        "sh": .shell,
        "bash": .shell,
        "zsh": .shell,
        "fish": .shell,
        "ksh": .shell,
        "sql": .sql,
        "lua": .lua,
        "zig": .zig,
        "scala": .scala,
        "sc": .scala,
        "groovy": .groovy,
        "gradle": .groovy,
        "sbt": .scala,
        "bzl": .python,
        "bazel": .python,
        "ex": .elixir,
        "exs": .elixir,
        "erl": .erlang,
        "hrl": .erlang,
        "hs": .haskell,
        "lhs": .haskell,
        "clj": .clojure,
        "cljs": .clojure,
        "cljc": .clojure,
        "edn": .clojure,
        "sol": .solidity,
        "ps1": .powershell,
        "psm1": .powershell,
        "bat": .batch,
        "cmd": .batch,
        "asm": .assembly,
        "s": .assembly,
        "r": .r,
        "jl": .julia,
        "vim": .vim,
        "tex": .latex,
        "sty": .latex,
        "cls": .latex,
        "metal": .metal,
        "json": .json,
        "har": .json,
        "jsonc": .json,
        "json5": .json,
        "geojson": .json,
        "webmanifest": .json,
        "jsonl": .json,
        "ndjson": .json,
        "ipynb": .jupyter,
        "yaml": .yaml,
        "yml": .yaml,
        "toml": .toml,
        "xml": .xml,
        "xsl": .xml,
        "xslt": .xml,
        "plist": .xml,
        "entitlements": .xml,
        "stringsdict": .xml,
        "xcprivacy": .xml,
        "xcscheme": .xml,
        "xib": .xml,
        "storyboard": .xml,
        "mobileconfig": .xml,
        "csproj": .xml,
        "fsproj": .xml,
        "vbproj": .xml,
        "props": .xml,
        "targets": .xml,
        "resx": .xml,
        "xaml": .xml,
        "ini": .ini,
        "strings": .ini,
        "cfg": .ini,
        "conf": .ini,
        "properties": .ini,
        "env": .ini,
        "xcconfig": .ini,
        "dockerfile": .dockerfile,
        "containerfile": .dockerfile,
        "modulemap": .c,
        "podspec": .ruby,
        "ninja": .plain,
        "sln": .plain,
        "cshtml": .html,
        "razor": .html,
        "po": .plain,
        "mk": .makefile,
        "mak": .makefile,
        "tf": .terraform,
        "tfvars": .terraform,
        "hcl": .terraform,
        "graphql": .graphql,
        "graphqls": .graphql,
        "gql": .graphql,
        "proto": .protobuf,
        "jsonnet": .javascript,
        "libsonnet": .javascript,
        "prisma": .plain,
        "cmake": .cmake,
        "nix": .nix,
        "pbxproj": .xcodeProject,
        "lock": .lockfile,
        "http": .http,
        "md": .markdown,
        "markdown": .markdown,
        "mdx": .markdown,
        "rst": .rst,
        "adoc": .asciidoc,
        "asciidoc": .asciidoc,
        "txt": .plain,
        "text": .plain,
        "log": .log,
        "out": .log,
        "csv": .csv,
        "tsv": .csv,
        "diff": .diff,
        "patch": .diff,
        "org": .plain,
        "textile": .plain,
    ]
}
