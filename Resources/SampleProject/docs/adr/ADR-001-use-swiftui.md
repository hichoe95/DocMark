---
status: accepted
date: 2026-01-15
deciders: ["@docmark-team"]
tags: ["architecture", "ui"]
---

# ADR-001: Use SwiftUI for the UI Framework

## Context

We need to choose a UI framework for DocMark, a Mac-native markdown documentation reader. The main options are:

1. **SwiftUI** - Apple's modern declarative UI framework
2. **AppKit** - Apple's traditional imperative UI framework
3. **Electron** - Cross-platform web-based framework

## Decision

We chose **SwiftUI** as the primary UI framework, targeting macOS 14 (Sonoma) and later.

Key reasons:
- Declarative syntax aligns well with our read-only document rendering use case
- Native macOS look and feel without additional effort
- Built-in dark mode support
- Excellent integration with Combine for reactive state management
- `NavigationSplitView` provides the sidebar-detail layout we need
- `NSViewRepresentable` allows us to embed WKWebView for Mermaid/KaTeX when needed

## Consequences

### Positive
- Faster development with declarative UI patterns
- Automatic dark mode and accessibility support
- Smaller binary size compared to Electron
- Native performance and memory efficiency

### Negative
- Limited to macOS 14+ (no support for older macOS versions)
- Some advanced text rendering requires falling back to AppKit/WKWebView
- SwiftUI's `MarkdownView` library is less mature than web-based alternatives
