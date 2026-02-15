import SwiftUI
import WebKit

struct WebViewDocumentRenderer: NSViewRepresentable {
    let markdown: String
    let baseURL: URL?
    @Environment(\.colorScheme) private var colorScheme

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        context.coordinator.webView = webView
        webView.setValue(false, forKey: "drawsBackground")
        webView.loadHTMLString(WebViewTemplate.html, baseURL: baseURL)
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        let theme = colorScheme == .dark ? "dark" : "light"
        context.coordinator.pendingTheme = theme
        context.coordinator.pendingMarkdown = markdown
        context.coordinator.flushIfReady()
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        weak var webView: WKWebView?
        var isPageLoaded = false
        var pendingTheme: String?
        var pendingMarkdown: String?

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isPageLoaded = true
            flushIfReady()
        }

        func flushIfReady() {
            guard isPageLoaded, let webView else { return }

            if let theme = pendingTheme {
                webView.evaluateJavaScript("window.setTheme('\(theme)');")
                self.pendingTheme = nil
            }

            if let md = pendingMarkdown {
                let escaped = Self.escapeForJavaScriptTemplateLiteral(md)
                webView.evaluateJavaScript("window.renderMarkdown(`\(escaped)`);")
                self.pendingMarkdown = nil
            }
        }

        private static func escapeForJavaScriptTemplateLiteral(_ text: String) -> String {
            var escaped = text.replacingOccurrences(of: "\\", with: "\\\\")
            escaped = escaped.replacingOccurrences(of: "`", with: "\\`")
            escaped = escaped.replacingOccurrences(of: "$", with: "\\$")
            escaped = escaped.replacingOccurrences(of: "\r\n", with: "\\n")
            escaped = escaped.replacingOccurrences(of: "\n", with: "\\n")
            escaped = escaped.replacingOccurrences(of: "\r", with: "\\n")
            return escaped
        }
    }
}
