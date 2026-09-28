import Foundation



struct Account: Identifiable, Hashable, Codable {
    var id: String = UUID().uuidString
    var name: String
}
