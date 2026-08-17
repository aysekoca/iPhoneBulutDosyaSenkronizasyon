import Foundation

struct Dosya: Codable, Identifiable {

    let id: Int
    let adi: String
    let boyut: Int

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case adi = "Adi"
        case boyut = "Boyut"
    }
}
