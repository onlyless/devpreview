import AppKit
import Combine
import Foundation

private let extensionIdentifier = "com.zhangzheng.DevPreview.Extension"

enum ExtensionState: Equatable {
    case checking
    case enabled
    case disabled
    case notRegistered
    case failed(String)

    var title: String {
        switch self {
        case .checking:
            return "正在检查扩展状态"
        case .enabled:
            return "Quick Look 扩展已启用"
        case .disabled:
            return "Quick Look 扩展未启用"
        case .notRegistered:
            return "Quick Look 扩展尚未注册"
        case .failed:
            return "扩展状态检查失败"
        }
    }

    var detail: String {
        switch self {
        case .checking:
            return "正在向 macOS 查询 DevPreview 扩展的注册状态。"
        case .enabled:
            return "现在可以在 Finder 中选中代码或配置文件，按空格直接预览。"
        case .disabled:
            return "扩展已安装，但还没有在系统设置中启用。点击「启用扩展」即可。"
        case .notRegistered:
            return "建议先把 App 放进「应用程序」文件夹，再点击「启用扩展」完成注册。"
        case .failed:
            return "请查看下方的命令输出，必要时从「应用程序」文件夹重新打开 App。"
        }
    }
}

@MainActor
final class ExtensionStatusModel: ObservableObject {
    @Published private(set) var state: ExtensionState = .checking
    @Published private(set) var isWorking = false
    @Published private(set) var lastError: String?
    @Published private(set) var notice: String?

    private var testProcess: Process?

    func refresh() {
        guard !isWorking else { return }
        isWorking = true
        lastError = nil

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let newState = queryExtensionState()
            DispatchQueue.main.async {
                guard let self else { return }
                self.isWorking = false
                self.state = newState
                if case let .failed(message) = newState {
                    self.lastError = message
                }
            }
        }
    }

    func enable() {
        guard !isWorking else { return }
        isWorking = true
        lastError = nil
        notice = nil

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var registrationOutput = ""
            if let appexURL = Bundle.main.builtInPlugInsURL?.appendingPathComponent("DevPreviewExtension.appex"),
               FileManager.default.fileExists(atPath: appexURL.path) {
                let registration = Shell.run(
                    "/usr/bin/pluginkit",
                    ["-a", appexURL.path]
                )
                registrationOutput = registration.output
            }

            let enableResult = Shell.run(
                "/usr/bin/pluginkit",
                ["-e", "use", "-i", extensionIdentifier]
            )
            let newState = queryExtensionState()

            DispatchQueue.main.async {
                guard let self else { return }
                self.isWorking = false

                if newState == .enabled {
                    self.state = .enabled
                    self.notice = "扩展已启用，去 Finder 按空格试试。"
                    self.lastError = nil
                } else {
                    self.state = newState
                    let details = [registrationOutput, enableResult.output]
                        .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                        .joined(separator: "\n")
                    self.lastError = details.isEmpty
                        ? "启用失败，请打开系统设置手动开启「DevPreview」。"
                        : details
                }
            }
        }
    }

    func openSettings() {
        let settingsURL = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension")
        guard let settingsURL else { return }
        NSWorkspace.shared.open(settingsURL)
    }

    func reloadQuickLook() {
        guard !isWorking else { return }
        isWorking = true
        lastError = nil
        notice = nil

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let reset = Shell.run("/usr/bin/qlmanage", ["-r"])
            let cache = Shell.run("/usr/bin/qlmanage", ["-r", "cache"])

            DispatchQueue.main.async {
                guard let self else { return }
                self.isWorking = false
                if reset.exitCode == 0 || cache.exitCode == 0 {
                    self.notice = "Quick Look 缓存已重置。若 Finder 仍使用旧预览，请重启 Finder。"
                    self.lastError = nil
                } else {
                    let details = [reset.output, cache.output]
                        .filter { !$0.isEmpty }
                        .joined(separator: "\n")
                    self.lastError = details.isEmpty ? "重置 Quick Look 缓存失败。" : details
                }
            }
        }
    }

    func testPreview() {
        lastError = nil
        notice = nil

        do {
            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent("DevPreview", isDirectory: true)
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            let fileURL = directory.appendingPathComponent("DevPreviewSample.swift")
            try SampleCode.swift.write(to: fileURL, atomically: true, encoding: .utf8)

            let process = try Shell.launchDetached(
                "/usr/bin/qlmanage",
                ["-p", fileURL.path]
            )
            testProcess = process
            notice = "已打开 Quick Look 示例，按 Esc 关闭。"
        } catch {
            lastError = error.localizedDescription
        }
    }

}

private func queryExtensionState() -> ExtensionState {
    let result = Shell.run(
        "/usr/bin/pluginkit",
        ["-m", "-i", extensionIdentifier]
    )
    let output = result.output.trimmingCharacters(in: .whitespacesAndNewlines)

    if result.exitCode != 0, output.isEmpty {
        return .failed("pluginkit 返回退出码 \(result.exitCode)。")
    }

    let matchingLine = output
        .split(separator: "\n")
        .map(String.init)
        .first { $0.contains(extensionIdentifier) }

    guard let matchingLine else {
        return .notRegistered
    }

    let trimmed = matchingLine.trimmingCharacters(in: .whitespaces)
    if trimmed.hasPrefix("+") {
        return .enabled
    }
    return .disabled
}

private enum Shell {
    struct Result {
        let exitCode: Int32
        let output: String
    }

    static func run(_ executable: String, _ arguments: [String]) -> Result {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
        } catch {
            return Result(exitCode: -1, output: error.localizedDescription)
        }

        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        return Result(exitCode: process.terminationStatus, output: output)
    }

    static func launchDetached(_ executable: String, _ arguments: [String]) throws -> Process {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        return process
    }
}
