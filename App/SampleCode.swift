import Foundation

enum SampleCode {
    static let swift = #"""
    import Foundation

    // DevPreview 示例：按 Esc 关闭 Quick Look 面板
    struct Greeting: Codable {
        let name: String
        let language: String

        func render() -> String {
            "Hello, \(name) — welcome to \(language)!"
        }
    }

    enum PreviewError: Error {
        case unsupportedEncoding
        case fileTooLarge
    }

    @MainActor
    final class GreetingStore {
        private(set) var greetings: [Greeting] = []

        func add(_ greeting: Greeting) {
            greetings.append(greeting)
        }

        func load(from url: URL) throws -> [Greeting] {
            let data = try Data(contentsOf: url)
            guard data.count < 8 * 1024 * 1024 else {
                throw PreviewError.fileTooLarge
            }
            return try JSONDecoder().decode([Greeting].self, from: data)
        }
    }

    let sample = Greeting(name: "Swift", language: "macOS")
    print(sample.render())
    """#
}
