import SwiftUI
import MarkdownView
#if canImport(Highlightr)
import Highlightr
#endif

struct DocumentReaderView: View {
    let document: Document
    @EnvironmentObject var appState: AppState
    @StateObject private var licenseManager = LicenseManager.shared

    private var needsWebView: Bool {
        document.hasMermaid || document.hasMath
    }

    private var canUseWebView: Bool {
        if document.hasMermaid && !licenseManager.isEnabled(.mermaidDiagrams) {
            return false
        }
        if document.hasMath && !licenseManager.isEnabled(.mathEquations) {
            return false
        }
        return true
    }

    var body: some View {
        VStack(spacing: 0) {
            BreadcrumbBar(document: document)

            if needsWebView && canUseWebView {
                webViewRenderer
            } else {
                nativeRenderer
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(nsColor: .textBackgroundColor))
        .navigationTitle(document.displayTitle)
        .environment(\.openURL, OpenURLAction { url in
            handleLink(url)
        })
    }

    private var nativeRenderer: some View {
        ScrollView {
            MarkdownView(AdmonitionProcessor.processForMarkdownView(document.renderableContent))
                .codeBlockStyle(DocMarkCodeBlockStyle())
                .markdownBaseURL(document.directoryURL)
                .padding(.horizontal, 40)
                .padding(.vertical, 24)
        }
    }

    private var webViewRenderer: some View {
        WebViewDocumentRenderer(
            markdown: AdmonitionProcessor.processForWebView(document.renderableContent),
            baseURL: document.directoryURL
        )
    }

    private func handleLink(_ url: URL) -> OpenURLAction.Result {
        let urlString = url.absoluteString

        if urlString.hasSuffix(".md") || urlString.contains(".md#") {
            let path = urlString.components(separatedBy: "#").first ?? urlString
            let cleaned = path
                .replacingOccurrences(of: "file://", with: "")
                .removingPercentEncoding ?? path
            appState.navigateToDocument(fromCurrentDocument: cleaned)
            return .handled
        }

        if url.scheme == nil || url.scheme == "file" {
            if let ext = url.pathExtension.nilIfEmpty, ext != "md" {
                return .systemAction
            }
            appState.navigateToDocument(fromCurrentDocument: urlString)
            return .handled
        }

        return .systemAction
    }
}

// MARK: - Code Block Style with Copy Button

struct DocMarkCodeBlockStyle: CodeBlockStyle {
    func makeBody(configuration: Configuration) -> some View {
        DocMarkCodeBlock(configuration: configuration)
    }
}

private struct DocMarkCodeBlock: View {
    private static var cachedHighlightr: AnyObject? = {
        #if canImport(Highlightr)
        return Highlightr()
        #else
        return nil
        #endif
    }()

    let configuration: CodeBlockStyleConfiguration
    @State private var isHovering = false
    @State private var copied = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let language = configuration.language, !language.isEmpty {
                HStack {
                    Text(language)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)

                    Spacer()

                    copyButton
                        .padding(.trailing, 8)
                        .padding(.vertical, 2)
                }
                .background(codeHeaderBackground)

                Divider().opacity(0.5)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                Text(highlightedCode)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .overlay(alignment: .topTrailing) {
                if configuration.language == nil || configuration.language?.isEmpty == true {
                    copyButton
                        .padding(8)
                        .opacity(isHovering ? 1 : 0)
                }
            }
        }
        .background(codeBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(codeBorder, lineWidth: 0.5)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }

    private var copyButton: some View {
        Button {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(configuration.code, forType: .string)
            copied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                copied = false
            }
        } label: {
            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                .font(.caption)
                .foregroundStyle(copied ? .green : .secondary)
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(copied ? "Copied!" : "Copy code")
    }

    private var highlightedCode: AttributedString {
        #if canImport(Highlightr)
        if let highlightr = Self.cachedHighlightr as? Highlightr {
            let themeName = colorScheme == .dark ? "atom-one-dark" : "xcode"
            highlightr.setTheme(to: themeName)
            if let language = configuration.language,
               highlightr.supportedLanguages().contains(language),
               let highlighted = highlightr.highlight(configuration.code, as: language) {
                return AttributedString(highlighted)
            }
        }
        #endif
        return AttributedString(configuration.code)
    }

    private var codeBackground: Color {
        colorScheme == .dark
            ? Color(nsColor: NSColor(white: 0.12, alpha: 1.0))
            : Color(nsColor: NSColor(white: 0.96, alpha: 1.0))
    }

    private var codeHeaderBackground: Color {
        colorScheme == .dark
            ? Color(nsColor: NSColor(white: 0.15, alpha: 1.0))
            : Color(nsColor: NSColor(white: 0.93, alpha: 1.0))
    }

    private var codeBorder: Color {
        colorScheme == .dark
            ? Color(nsColor: NSColor(white: 0.25, alpha: 1.0))
            : Color(nsColor: NSColor(white: 0.85, alpha: 1.0))
    }
}

// MARK: - Breadcrumb Bar

struct BreadcrumbBar: View {
    let document: Document
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(breadcrumbs.enumerated()), id: \.offset) { index, component in
                if index > 0 {
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.quaternary)
                }

                if index < breadcrumbs.count - 1 {
                    Button(component) {
                        navigateToFolder(at: index)
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .onHover { hovering in
                        if hovering {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                } else {
                    Text(component)
                        .font(.caption)
                        .foregroundStyle(.primary)
                }
            }
            Spacer()

            Text("\(document.lineCount) lines")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private var breadcrumbs: [String] {
        document.relativePath
            .replacingOccurrences(of: ".md", with: "")
            .components(separatedBy: "/")
    }

    private func navigateToFolder(at index: Int) {
        let folderComponents = Array(breadcrumbs.prefix(index + 1))
        let folderPath = folderComponents.joined(separator: "/")
        appState.navigateToDocument(withRelativePath: folderPath + "/README.md")
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
