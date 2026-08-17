import Foundation

struct Ticket: Codable {

    let kullaniciAdi: String
    let id: UUID
    let sonuc: Bool

    enum CodingKeys: String, CodingKey {
        case kullaniciAdi = "KullaniciAdi"
        case id = "ID"
        case sonuc = "Sonuc"
    }
}

