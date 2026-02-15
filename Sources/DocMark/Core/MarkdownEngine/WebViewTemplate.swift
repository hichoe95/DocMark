import Foundation

struct WebViewTemplate {
    static var html: String {
        #"""
        <!doctype html>
        <html lang="en">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.28/dist/katex.min.css">
          <link id="hljs-theme" rel="stylesheet" href="https://cdn.jsdelivr.net/npm/highlight.js@11.11.1/styles/github.min.css">
          <style>
            :root {
              --bg: #ffffff;
              --text: #1f2328;
              --muted: #59636e;
              --border: #d0d7de;
              --quote-border: #d0d7de;
              --code-bg: #f6f8fa;
              --inline-code-bg: rgba(175, 184, 193, 0.2);
              --link: #0969da;
              --table-stripe: #f6f8fa;
            }

            body.dark {
              --bg: #0d1117;
              --text: #e6edf3;
              --muted: #9da7b3;
              --border: #30363d;
              --quote-border: #3d444d;
              --code-bg: #161b22;
              --inline-code-bg: rgba(110, 118, 129, 0.4);
              --link: #58a6ff;
              --table-stripe: #0f141b;
            }

            * {
              box-sizing: border-box;
            }

            body {
              margin: 0;
              padding: 24px 40px;
              font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
              font-size: 16px;
              line-height: 1.7;
              background: var(--bg);
              color: var(--text);
              -webkit-font-smoothing: antialiased;
            }

            #content {
              width: 100%;
            }

            h1, h2, h3, h4, h5, h6 {
              line-height: 1.3;
              margin: 1.2em 0 0.6em;
            }

            p {
              margin: 0 0 1em;
            }

            a {
              color: var(--link);
            }

            hr {
              border: 0;
              border-top: 1px solid var(--border);
              margin: 1.5em 0;
            }

            blockquote {
              margin: 1em 0;
              padding: 0.25em 1em;
              border-left: 4px solid var(--quote-border);
              color: var(--muted);
            }

            pre {
              margin: 1em 0;
              border: 1px solid var(--border);
              border-radius: 10px;
              background: var(--code-bg);
              overflow-x: auto;
            }

            pre code {
              display: block;
              padding: 14px 16px;
              font-family: ui-monospace, SFMono-Regular, SF Mono, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;
              font-size: 0.92em;
              line-height: 1.55;
              background: transparent;
            }

            code {
              font-family: ui-monospace, SFMono-Regular, SF Mono, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;
              font-size: 0.9em;
              background: var(--inline-code-bg);
              border-radius: 6px;
              padding: 0.12em 0.35em;
            }

            pre code {
              border-radius: 0;
              padding: 14px 16px;
            }

            table {
              width: 100%;
              border-collapse: collapse;
              margin: 1em 0;
            }

            th, td {
              border: 1px solid var(--border);
              padding: 8px 12px;
              text-align: left;
              vertical-align: top;
            }

            tbody tr:nth-child(even) {
              background: var(--table-stripe);
            }

            img {
              max-width: 100%;
              height: auto;
            }

            ul, ol {
              margin: 0 0 1em;
              padding-left: 1.6em;
            }

            .mermaid {
              margin: 1.25em auto;
              text-align: center;
            }

            .katex-display {
              overflow-x: auto;
              overflow-y: hidden;
              padding: 0.2em 0;
            }

            .admonition {
              position: relative;
              border: 1px solid var(--border);
              border-left-width: 5px;
              border-radius: 8px;
              margin: 1em 0;
              padding: 12px 14px;
              background: color-mix(in srgb, var(--bg) 92%, var(--text) 8%);
            }

            .admonition::before {
              margin-right: 8px;
              font-weight: 700;
            }

            .admonition.note { border-left-color: #0969da; }
            .admonition.note::before { content: "i"; color: #0969da; }

            .admonition.tip { border-left-color: #1a7f37; }
            .admonition.tip::before { content: "!"; color: #1a7f37; }

            .admonition.important { border-left-color: #8250df; }
            .admonition.important::before { content: "*"; color: #8250df; }

            .admonition.warning { border-left-color: #9a6700; }
            .admonition.warning::before { content: "!"; color: #9a6700; }

            .admonition.caution { border-left-color: #cf222e; }
            .admonition.caution::before { content: "x"; color: #cf222e; }
          </style>

          <script src="https://cdn.jsdelivr.net/npm/marked@15.0.7/lib/marked.umd.min.js"></script>
          <script src="https://cdn.jsdelivr.net/npm/highlight.js@11.11.1/build/highlight.min.js"></script>
          <script src="https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.min.js"></script>
          <script src="https://cdn.jsdelivr.net/npm/katex@0.16.28/dist/katex.min.js"></script>
          <script src="https://cdn.jsdelivr.net/npm/katex@0.16.28/dist/contrib/auto-render.min.js"></script>
        </head>
        <body>
          <div id="content"></div>

          <script>
            (function () {
              const hljsThemeLight = "https://cdn.jsdelivr.net/npm/highlight.js@11.11.1/styles/github.min.css";
              const hljsThemeDark = "https://cdn.jsdelivr.net/npm/highlight.js@11.11.1/styles/github-dark.min.css";
              let currentTheme = "light";

              function escapeHtml(value) {
                return value
                  .replaceAll("&", "&amp;")
                  .replaceAll("<", "&lt;")
                  .replaceAll(">", "&gt;")
                  .replaceAll('"', "&quot;")
                  .replaceAll("'", "&#39;");
              }

              function extractMath(markdown) {
                const placeholders = [];
                const tokenPrefix = "__DOCMARK_MATH_";
                const mathPattern = /\$\$[\s\S]+?\$\$|\$(?:\\.|[^$\\\n])+\$|\\\[[\s\S]+?\\\]|\\\((?:\\.|[^\\])+?\\\)/g;
                const withPlaceholders = markdown.replace(mathPattern, function (match) {
                  const token = tokenPrefix + placeholders.length + "__";
                  placeholders.push(match);
                  return token;
                });

                return {
                  text: withPlaceholders,
                  restore: function (html) {
                    return html.replace(/__DOCMARK_MATH_(\d+)__/g, function (_, idx) {
                      const value = placeholders[Number(idx)];
                      return value == null ? "" : value;
                    });
                  }
                };
              }

              function createMarkedRenderer() {
                const renderer = new marked.Renderer();

                renderer.code = function ({ text, lang }) {
                  const language = (lang || "").trim().toLowerCase();
                  if (language === "mermaid") {
                    return "<div class=\"mermaid\">" + text + "</div>\n";
                  }

                  let highlighted = text;
                  if (language && hljs.getLanguage(language)) {
                    highlighted = hljs.highlight(text, { language: language }).value;
                  } else {
                    highlighted = hljs.highlightAuto(text).value;
                  }

                  const className = language ? "language-" + language : "";
                  return "<pre><code class=\"hljs " + className + "\">" + highlighted + "</code></pre>\n";
                };

                return renderer;
              }

              function applyTheme(theme) {
                currentTheme = theme === "dark" ? "dark" : "light";
                document.body.classList.toggle("dark", currentTheme === "dark");

                const themeLink = document.getElementById("hljs-theme");
                if (themeLink) {
                  themeLink.setAttribute("href", currentTheme === "dark" ? hljsThemeDark : hljsThemeLight);
                }

                mermaid.initialize({
                  startOnLoad: false,
                  theme: currentTheme === "dark" ? "dark" : "default",
                  securityLevel: "loose"
                });
              }

              function renderMarkdown(markdownText) {
                const markdown = typeof markdownText === "string" ? markdownText : "";
                const extracted = extractMath(markdown);
                const renderer = createMarkedRenderer();

                marked.setOptions({
                  gfm: true,
                  breaks: true,
                  renderer: renderer
                });

                const parsed = marked.parse(extracted.text);
                const restored = extracted.restore(parsed);
                const contentElement = document.getElementById("content");
                if (!contentElement) {
                  return;
                }

                contentElement.innerHTML = restored;

                renderMathInElement(contentElement, {
                  delimiters: [
                    { left: "$$", right: "$$", display: true },
                    { left: "$", right: "$", display: false },
                    { left: "\\[", right: "\\]", display: true },
                    { left: "\\(", right: "\\)", display: false }
                  ],
                  throwOnError: false,
                  ignoredTags: ["script", "noscript", "style", "textarea", "pre", "code"]
                });

                const mermaidNodes = contentElement.querySelectorAll("div.mermaid");
                if (mermaidNodes.length > 0) {
                  mermaid.run({ nodes: mermaidNodes });
                }
              }

              window.setTheme = function (theme) {
                applyTheme(theme);
              };

              window.renderMarkdown = function (markdownText) {
                renderMarkdown(markdownText);
              };

              applyTheme("light");
            })();
          </script>
        </body>
        </html>
        """#
    }
}
