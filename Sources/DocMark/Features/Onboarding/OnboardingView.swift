import SwiftUI

struct OnboardingView: View {
    enum Page: Int, CaseIterable {
        case welcome
        case features
        case getStarted

        var label: String {
            switch self {
            case .welcome:
                return "Welcome"
            case .features:
                return "Features"
            case .getStarted:
                return "Get Started"
            }
        }
    }

    struct Feature: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let description: String
    }

    @Environment(\.dismiss) private var dismiss
    @State private var page: Page = .welcome
    private let onOpenFolder: (() -> Void)?

    private let featureItems: [Feature] = [
        Feature(icon: "folder", title: "Project management", description: "Organize and switch between documentation roots."),
        Feature(icon: "text.book.closed", title: "Beautiful rendering", description: "Read markdown with polished typography and structure."),
        Feature(icon: "magnifyingglass", title: "Search", description: "Find sections and terms across your opened project."),
        Feature(icon: "cpu", title: "AI integration", description: "Connect to local and remote copilots for summaries."),
    ]

    init(onOpenFolder: (() -> Void)? = nil) {
        self.onOpenFolder = onOpenFolder
    }

    static func shouldShow() -> Bool {
        !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(nsColor: .underPageBackgroundColor), location: 0),
                    .init(color: Color(red: 0.96, green: 0.98, blue: 1.0), location: 1)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {
                Spacer()

                pageContent

                HStack(spacing: 10) {
                    ForEach(Page.allCases, id: \.self) { item in
                        Circle()
                            .fill(item == page ? Color.accentColor : Color.primary.opacity(0.25))
                            .frame(width: 9, height: 9)
                            .animation(.easeInOut(duration: 0.2), value: page)
                    }
                }

                HStack {
                    Button("Back") {
                        navigate(to: page.rawValue - 1)
                    }
                    .buttonStyle(.bordered)
                    .disabled(page == .welcome)

                    Spacer()

                    if page == .getStarted {
                        Button("Open Folder") {
                            onOpenFolder?()
                            completeOnboarding()
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button("Next") {
                            navigate(to: page.rawValue + 1)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .frame(width: 430)
                Spacer()
            }
            .padding(30)
            .frame(width: 560)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .frame(width: 680, height: 420)
    }

    @ViewBuilder
    private var pageContent: some View {
        VStack(spacing: 24) {
            Text(page.label)
                .font(.title.bold())

            Group {
                switch page {
                case .welcome:
                    VStack(spacing: 12) {
                        Image(systemName: "doc.richtext")
                            .font(.system(size: 72, weight: .semibold))
                            .foregroundStyle(.blue)

                        Text("DocMark")
                            .font(.system(size: 46, weight: .bold, design: .rounded))

                        Text("Beautiful documentation reader for your projects")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                case .features:
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(featureItems) { item in
                            HStack(alignment: .top, spacing: 14) {
                                Image(systemName: item.icon)
                                    .font(.title2)
                                    .foregroundStyle(.blue)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.title)
                                        .font(.headline)

                                    Text(item.description)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                case .getStarted:
                    VStack(spacing: 12) {
                        Text("Open a project folder to begin")
                            .font(.title2)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .frame(minHeight: 220)
            .frame(maxWidth: 430)
            .animation(.easeInOut(duration: 0.25), value: page)
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 4)
    }

    private func navigate(to value: Int) {
        guard let target = Page(rawValue: value) else { return }
        withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
            page = target
        }
    }

    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        dismiss()
    }
}

#Preview {
    OnboardingView()
}
