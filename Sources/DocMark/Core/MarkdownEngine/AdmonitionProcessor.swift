import Foundation

struct AdmonitionProcessor {
    enum AdmonitionType: String, CaseIterable {
        case note = "NOTE"
        case tip = "TIP"
        case important = "IMPORTANT"
        case warning = "WARNING"
        case caution = "CAUTION"

        var emoji: String {
            switch self {
            case .note: return "\u{2139}\u{FE0F}"
            case .tip: return "\u{1F4A1}"
            case .important: return "\u{2757}"
            case .warning: return "\u{26A0}\u{FE0F}"
            case .caution: return "\u{1F6D1}"
            }
        }

        var label: String {
            rawValue.capitalized
        }

        var color: String {
            switch self {
            case .note: return "#0969da"
            case .tip: return "#1a7f37"
            case .important: return "#8250df"
            case .warning: return "#9a6700"
            case .caution: return "#cf222e"
            }
        }
    }

    /// Converts `> [!NOTE]` callouts into styled blockquotes with emoji labels for MarkdownView.
    static func processForMarkdownView(_ markdown: String) -> String {
        let lines = markdown.components(separatedBy: "\n")
        var result: [String] = []
        var i = 0

        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if let admonitionType = parseAdmonitionHeader(trimmed) {
                var bodyLines: [String] = []
                i += 1
                while i < lines.count {
                    let nextTrimmed = lines[i].trimmingCharacters(in: .whitespaces)
                    if nextTrimmed.hasPrefix(">") {
                        var content = String(nextTrimmed.dropFirst())
                        if content.hasPrefix(" ") {
                            content = String(content.dropFirst())
                        }
                        bodyLines.append(content)
                    } else if nextTrimmed.isEmpty {
                        break
                    } else {
                        break
                    }
                    i += 1
                }

                let bodyText = bodyLines
                    .joined(separator: "\n")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                result.append("> **\(admonitionType.emoji) \(admonitionType.label)**")
                result.append(">")
                for bodyLine in bodyText.components(separatedBy: "\n") {
                    result.append("> \(bodyLine)")
                }
                result.append("")
            } else {
                result.append(line)
                i += 1
            }
        }

        return result.joined(separator: "\n")
    }

    /// Converts `> [!NOTE]` callouts into `<div class="admonition note">` HTML for WKWebView.
    static func processForWebView(_ markdown: String) -> String {
        let lines = markdown.components(separatedBy: "\n")
        var result: [String] = []
        var i = 0

        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if let admonitionType = parseAdmonitionHeader(trimmed) {
                var bodyLines: [String] = []
                i += 1
                while i < lines.count {
                    let nextTrimmed = lines[i].trimmingCharacters(in: .whitespaces)
                    if nextTrimmed.hasPrefix(">") {
                        var content = String(nextTrimmed.dropFirst())
                        if content.hasPrefix(" ") {
                            content = String(content.dropFirst())
                        }
                        bodyLines.append(content)
                    } else if nextTrimmed.isEmpty {
                        break
                    } else {
                        break
                    }
                    i += 1
                }

                let bodyText = bodyLines
                    .joined(separator: "\n")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                let typeClass = admonitionType.rawValue.lowercased()
                result.append("<div class=\"admonition \(typeClass)\">")
                result.append("<strong>\(admonitionType.emoji) \(admonitionType.label)</strong><br>")
                result.append(bodyText)
                result.append("</div>")
                result.append("")
            } else {
                result.append(line)
                i += 1
            }
        }

        return result.joined(separator: "\n")
    }

    private static func parseAdmonitionHeader(_ line: String) -> AdmonitionType? {
        guard line.hasPrefix(">") else { return nil }
        var content = String(line.dropFirst()).trimmingCharacters(in: .whitespaces)
        guard content.hasPrefix("[!") else { return nil }
        content = String(content.dropFirst(2))

        guard let closingBracket = content.firstIndex(of: "]") else { return nil }
        let typeString = String(content[content.startIndex..<closingBracket])
            .trimmingCharacters(in: .whitespaces)
            .uppercased()

        return AdmonitionType(rawValue: typeString)
    }
}
