import Foundation



struct Account: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var name: String
}
