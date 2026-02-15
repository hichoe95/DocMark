import SwiftUI

struct QuickOpenPanel: View {
    @EnvironmentObject var appState: AppState
    @State private var query = ""
    @State private var selectedIndex = 0
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { appState.toggleQuickOpen() }

            VStack(spacing: 0) {
                searchField
                Divider()
                resultsList
            }
            .frame(width: 600)
            .frame(maxHeight: 420)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
            .padding(.top, 80)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.97)))
        .onAppear {
            isSearchFocused = true
            selectedIndex = 0
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.title3)

            TextField("Quick Open...", text: $query)
                .textFieldStyle(.plain)
                .font(.title3)
                .focused($isSearchFocused)
                .onChange(of: query) { _, newValue in
                    appState.performQuickOpen(newValue)
                    selectedIndex = 0
                }
                .onSubmit { openSelected() }
                .onKeyPress(.upArrow) {
                    if selectedIndex > 0 { selectedIndex -= 1 }
                    return .handled
                }
                .onKeyPress(.downArrow) {
                    if selectedIndex < appState.quickOpenResults.count - 1 {
                        selectedIndex += 1
                    }
                    return .handled
                }
                .onKeyPress(.escape) {
                    appState.toggleQuickOpen()
                    return .handled
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var resultsList: some View {
        Group {
            if appState.quickOpenResults.isEmpty {
                emptyState
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(appState.quickOpenResults.enumerated()), id: \.element.id) { index, result in
                                QuickOpenResultRow(
                                    result: result,
                                    isSelected: index == selectedIndex
                                )
                                .id(index)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    appState.openSearchResult(result)
                                    appState.toggleQuickOpen()
                                }
                                .onHover { hovering in
                                    if hovering { selectedIndex = index }
                                }
                            }
                        }
                    }
                    .onChange(of: selectedIndex) { _, newValue in
                        withAnimation(.easeOut(duration: 0.1)) {
                            proxy.scrollTo(newValue, anchor: .center)
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            if query.isEmpty {
                Text("Type to search documents...")
                    .foregroundStyle(.tertiary)
            } else {
                Text("No matching documents")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.subheadline)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private func openSelected() {
        guard !appState.quickOpenResults.isEmpty,
              selectedIndex < appState.quickOpenResults.count else { return }
        let result = appState.quickOpenResults[selectedIndex]
        appState.openSearchResult(result)
        appState.toggleQuickOpen()
    }
}

private struct QuickOpenResultRow: View {
    let result: SearchResult
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text")
                .foregroundStyle(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(result.title)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .lineLimit(1)

                Text(result.snippet)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
    }
}
