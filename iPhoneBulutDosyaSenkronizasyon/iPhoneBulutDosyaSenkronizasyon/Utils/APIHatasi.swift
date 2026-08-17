import Foundation

enum APIHatasi: LocalizedError {

    case gecersizURL
    case kimlikBilgisiOlusturulamadi
    case gecersizCevap
    case sunucuHatasi(Int)

    var errorDescription: String? {
        switch self {

        case .gecersizURL:
            return "API adresi geçersiz."

        case .kimlikBilgisiOlusturulamadi:
            return "Kimlik bilgisi oluşturulamadı."

        case .gecersizCevap:
            return "Sunucudan geçerli bir cevap alınamadı."

        case .sunucuHatasi(let durumKodu):
            return "Sunucu hatası oluştu. Kod: \(durumKodu)"
        }
    }
}
