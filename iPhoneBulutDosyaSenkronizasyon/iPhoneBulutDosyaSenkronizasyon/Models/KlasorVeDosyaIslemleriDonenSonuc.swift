import Foundation

struct KlasorVeDosyaIslemleriDonenSonuc: Codable {

    let mesaj: String?
    let sonuc: Bool
    let sonucKlasorListe: [Klasor]?
    let sonucDosyaListe: [Dosya]?

    enum CodingKeys: String, CodingKey {
        case mesaj = "Mesaj"
        case sonuc = "Sonuc"
        case sonucKlasorListe = "SonucKlasorListe"
        case sonucDosyaListe = "SonucDosyaListe"
    }
}
