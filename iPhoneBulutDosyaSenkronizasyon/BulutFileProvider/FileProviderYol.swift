import FileProvider
import Foundation

enum OgeTuru: String, Codable {
    case klasor = "K"
    case dosya = "D"
}

/// File Provider öğelerinin kimliğini sunucudaki benzersiz ID ile üretir.
/// Böylece öğeler yalnızca dosya adına göre takip edilmez.
enum FileProviderYol {

    static func identifier(tur: OgeTuru, sunucuID: Int) -> NSFileProviderItemIdentifier {
        NSFileProviderItemIdentifier("\(tur.rawValue)_\(sunucuID)")
    }

    static func tur(_ identifier: NSFileProviderItemIdentifier) -> OgeTuru? {
        guard identifier != .rootContainer else { return .klasor }
        let parcalar = identifier.rawValue.split(separator: "_", maxSplits: 1)
        guard parcalar.count == 2 else { return nil }
        return OgeTuru(rawValue: String(parcalar[0]))
    }
}
