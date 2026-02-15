import SwiftUI

struct SearchPanel: View {
    @EnvironmentObject var appState: AppState
    @FocusState private var isSearchFieldFocused: Bool
    @State private var selectedIndex: Int = 0

    var body: some View {
        ZStack {
            // Semi-transparent background that dismisses on tap
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    appState.toggleSearch()
                }

            // Centered floating panel
            VStack(spacing: 0) {
                // Search header
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16, weight: .medium))

                    TextField("Search documents... (⌘K)", text: $appState.searchQuery)
                        .textFieldStyle(.plain)
                        .font(.system(size: 16))
                        .focused($isSearchFieldFocused)
                        .onChange(of: appState.searchQuery) { oldValue, newValue in
                            appState.performSearch(newValue)
                            selectedIndex = 0
                        }

                    if !appState.searchQuery.isEmpty {
                        Button(action: {
                            appState.searchQuery = ""
                            appState.performSearch("")
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 16))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                Divider()

                // Results count badge
                if !appState.searchQuery.isEmpty {
                    HStack {
                        Text("\(appState.searchResults.count) results")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                    Divider()
                }

                // Results list
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: true) {
                        LazyVStack(spacing: 0) {
                            if appState.searchQuery.isEmpty {
                                // Empty state - type to search
                                VStack(spacing: 8) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 32))
                                        .foregroundColor(.secondary)
                                    Text("Type to search...")
                                        .font(.callout)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity, minHeight: 200)
                                .padding(.vertical, 40)
                            } else if appState.searchResults.isEmpty {
                                // No results state
                                VStack(spacing: 8) {
                                    Image(systemName: "magnifyingglass.circle")
                                        .font(.system(size: 32))
                                        .foregroundColor(.secondary)
                                    Text("No results found")
                                        .font(.callout)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity, minHeight: 200)
                                .padding(.vertical, 40)
                            } else {
                                // Results
                                ForEach(Array(appState.searchResults.enumerated()), id: \.element.id) { index, result in
                                    ResultRow(
                                        result: result,
                                        isSelected: index == selectedIndex
                                    )
                                    .id(index)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedIndex = index
                                        openSelectedResult()
                                    }
                                    .background(index == selectedIndex ? Color.accentColor.opacity(0.1) : Color.clear)

                                    if index < appState.searchResults.count - 1 {
                                        Divider()
                                            .padding(.leading, 16)
                                    }
                                }
                            }
                        }
                    }
                    .onChange(of: selectedIndex) { oldValue, newValue in
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }
            .frame(width: 650)
            .frame(maxHeight: 500)
            .background(.regularMaterial)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        }
        .onAppear {
            isSearchFieldFocused = true
        }
        .onKeyPress(.upArrow) {
            moveSelection(up: true)
            return .handled
        }
        .onKeyPress(.downArrow) {
            moveSelection(up: false)
            return .handled
        }
        .onKeyPress(.return) {
            openSelectedResult()
            return .handled
        }
        .onKeyPress(.escape) {
            appState.toggleSearch()
            return .handled
        }
    }

    private func moveSelection(up: Bool) {
        guard !appState.searchResults.isEmpty else { return }

        if up {
            selectedIndex = max(0, selectedIndex - 1)
        } else {
            selectedIndex = min(appState.searchResults.count - 1, selectedIndex + 1)
        }
    }

    private func openSelectedResult() {
        guard selectedIndex >= 0 && selectedIndex < appState.searchResults.count else { return }
        let result = appState.searchResults[selectedIndex]
        appState.openSearchResult(result)
    }
}

// MARK: - Result Row

struct ResultRow: View {
    let result: SearchResult
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Title
            Text(result.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)

            // Path
            Text(result.path)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)

            // Snippet with highlighted terms
            renderSnippet(result.snippet)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Parses the snippet string containing <b></b> tags and returns a Text view
    /// with the appropriate bold formatting for matched terms.
    func renderSnippet(_ snippet: String) -> Text {
        var resultText = Text("")
        var remaining = snippet

        while let openRange = remaining.range(of: "<b>"),
              let closeRange = remaining.range(of: "</b>") {
            // Text before the bold tag
            let beforeBold = String(remaining[..<openRange.lowerBound])
            if !beforeBold.isEmpty {
                resultText = resultText + Text(beforeBold)
            }

            // Bold text
            let boldText = String(remaining[openRange.upperBound..<closeRange.lowerBound])
            if !boldText.isEmpty {
                resultText = resultText + Text(boldText).bold()
            }

            // Update remaining string
            remaining = String(remaining[closeRange.upperBound...])
        }

        // Add any remaining text after the last bold tag
        if !remaining.isEmpty {
            resultText = resultText + Text(remaining)
        }

        return resultText
    }
}

// MARK: - Preview

#Preview {
    SearchPanel()
        .environmentObject(AppState())
}
