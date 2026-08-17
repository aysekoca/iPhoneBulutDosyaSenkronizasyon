import Foundation

struct DosyaGuncelleModel: Codable {
    let ticketID: UUID
    let klasorYolu: String
    let dosyaAdi: String
    let yeniDosyaAdi: String
}
