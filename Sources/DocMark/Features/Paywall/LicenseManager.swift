import Foundation
import Combine

enum Feature: Hashable, CaseIterable {
    case multiProject
    case crossProjectSearch
    case gitIntegration
    case mermaidDiagrams
    case mathEquations
    case admonitions
    case tableOfContents
    case tagCategories
    case exportPDF
}

final class LicenseManager: ObservableObject {
    static let shared = LicenseManager()
    
    @Published var isPro: Bool = false
    
    private let freeFeatures: Set<Feature> = [.gitIntegration]
    
    private init() {}
    
    func isEnabled(_ feature: Feature) -> Bool {
        isPro || freeFeatures.contains(feature)
    }
    
    func upgradeToPro() {
        isPro = true
    }
}
