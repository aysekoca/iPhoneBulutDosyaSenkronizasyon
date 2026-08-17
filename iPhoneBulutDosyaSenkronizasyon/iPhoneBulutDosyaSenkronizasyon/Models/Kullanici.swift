import Foundation

struct Kullanici: Codable {

    let kullaniciAdi: String
    let sifre: String

    enum CodingKeys: String, CodingKey {
        case kullaniciAdi = "KullaniciAdi"
        case sifre = "Sifre"
    }
}
