import AppKit
import Combine
import SwiftUI

struct ContentView: View {
    @StateObject private var model = ExtensionStatusModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                hero
                statusCard
                quickStart
                formatsSection
                footer
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 26)
            .frame(maxWidth: 920, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(background)
        .onAppear {
            model.refresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            model.refresh()
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(nsColor: .windowBackgroundColor),
                Color(nsColor: .underPageBackgroundColor).opacity(0.72),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var hero: some View {
        HStack(alignment: .center, spacing: 18) {
            AppIconView()

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    Text("DevPreview")
                        .font(.system(size: 30, weight: .bold, design: .rounded))

                    Text("QUICK LOOK")
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.accentColor.opacity(0.13))
                        )
                }

                Text("在 Finder 里按空格，直接看代码。")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)

                Text("语法高亮、行号、自动换行，也能直接看压缩包结构和 SQLite 表结构，全部在本机完成。")
                    .font(.system(size: 12.5))
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
    }

    private var statusCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 9) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 9, height: 9)

                    Text(model.state.title)
                        .font(.system(size: 15, weight: .semibold))

                    if model.isWorking {
                        ProgressView()
                            .controlSize(.small)
                    }

                    Spacer()

                    Button {
                        model.refresh()
                    } label: {
                        Label("刷新", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.borderless)
                    .font(.system(size: 12))
                    .disabled(model.isWorking)
                }

                Text(model.state.detail)
                    .font(.system(size: 12.5))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    Button {
                        model.enable()
                    } label: {
                        Label("启用扩展", systemImage: "switch.2")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.isWorking)

                    Button {
                        model.openSettings()
                    } label: {
                        Label("打开系统设置", systemImage: "gearshape")
                    }

                    Button {
                        model.testPreview()
                    } label: {
                        Label("测试预览", systemImage: "eye")
                    }

                    Spacer()

                    Button("重载缓存") {
                        model.reloadQuickLook()
                    }
                    .buttonStyle(.borderless)
                    .font(.system(size: 12))
                    .disabled(model.isWorking)
                }

                if let notice = model.notice {
                    Label(notice, systemImage: "checkmark.circle")
                        .font(.system(size: 12))
                        .foregroundStyle(.green)
                }

                if let error = model.lastError {
                    Text(error)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.red)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var quickStart: some View {
        HStack(spacing: 12) {
            StepCard(
                number: "1",
                title: "安装",
                detail: "把 DevPreview 放进「应用程序」文件夹"
            )
            StepCard(
                number: "2",
                title: "启用",
                detail: "系统设置 → 通用 → 登录项与扩展 → 快速查看"
            )
            StepCard(
                number: "3",
                title: "预览",
                detail: "Finder 选中文件，按空格键"
            )
        }
    }

    private var formatsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("支持的格式")
                    .font(.system(size: 19, weight: .bold))

                Text("\(SupportedFormats.formatCount) 类 · \(SupportedFormats.allExtensions.count) 种扩展名")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                Spacer()
            }

            ForEach(SupportedFormats.categories) { category in
                CategoryCard(category: category)
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.shield")
                .foregroundStyle(.tertiary)

            Text("预览完全在本机完成，不会上传文件内容。")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            Spacer()

            Text("v\(appVersion)")
                .font(.system(size: 10.5, design: .monospaced))
                .foregroundStyle(.tertiary)
        }
        .padding(.top, 2)
    }

    private var statusColor: Color {
        switch model.state {
        case .checking:
            return .gray
        case .enabled:
            return .green
        case .disabled, .notRegistered:
            return .orange
        case .failed:
            return .red
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

private struct AppIconView: View {
    var body: some View {
        Group {
            if let image = AppIconProvider.image ?? NSApp.applicationIconImage {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
            } else {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.indigo, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.white)
                    }
            }
        }
        .frame(width: 72, height: 72)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 14, y: 6)
    }
}

private struct StepCard: View {
    let number: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Circle().fill(Color.accentColor))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12.5, weight: .semibold))

                Text(detail)
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06))
        )
    }
}

private struct CategoryCard: View {
    let category: FormatCategory

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Label(category.title, systemImage: category.symbol)
                    .font(.system(size: 14, weight: .semibold))

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 230), spacing: 8)],
                    alignment: .leading,
                    spacing: 8
                ) {
                    ForEach(category.items) { item in
                        FormatChip(item: item)
                    }
                }
            }
        }
    }
}

private struct FormatChip: View {
    let item: FormatItem

    var body: some View {
        HStack(spacing: 8) {
            Text(item.name)
                .font(.system(size: 11.5, weight: .medium))
                .lineLimit(1)

            Spacer(minLength: 4)

            Text(item.extensionSummary)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color(nsColor: .textBackgroundColor).opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06))
        )
        .help(item.extensionSummary)
    }
}

private struct Card<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.07), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
    }
}
