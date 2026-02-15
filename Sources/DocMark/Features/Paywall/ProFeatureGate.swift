import SwiftUI

struct ProFeatureGate<Content: View>: View {
    @StateObject private var licenseManager = LicenseManager.shared
    
    let feature: Feature
    let content: Content
    
    init(feature: Feature, @ViewBuilder content: () -> Content) {
        self.feature = feature
        self.content = content()
    }
    
    var body: some View {
        if licenseManager.isEnabled(feature) {
            content
        } else {
            lockedOverlay
        }
    }
    
    private var lockedOverlay: some View {
        ZStack {
            Color(nsColor: .controlBackgroundColor)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                
                VStack(spacing: 8) {
                    Text(featureName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Upgrade to Pro")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Button(action: {
                    licenseManager.upgradeToPro()
                }) {
                    Text("Upgrade to Pro")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
                .tint(.blue)
            }
            .padding(32)
        }
    }
    
    private var featureName: String {
        switch feature {
        case .multiProject:
            "Multi-Project Library"
        case .crossProjectSearch:
            "Cross-Project Search"
        case .gitIntegration:
            "Git Integration"
        case .mermaidDiagrams:
            "Mermaid Diagrams"
        case .mathEquations:
            "Math Equations"
        case .admonitions:
            "Admonitions"
        case .tableOfContents:
            "Table of Contents"
        case .tagCategories:
            "Tag Categories"
        case .exportPDF:
            "PDF Export"
        }
    }
}

#Preview {
    ProFeatureGate(feature: .multiProject) {
        VStack {
            Text("This is Pro content")
                .font(.title)
            Text("Multi-project library feature")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
