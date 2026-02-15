import Foundation

struct SearchResult: Identifiable {
    let id: UUID = UUID()
    let documentId: UUID
    let title: String
    let path: String
    let snippet: String
    let rank: Double
}
