import Foundation

struct Klasor: Codable, Identifiable {

    let id: Int
    let adi: String

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case adi = "Adi"
    }
}
