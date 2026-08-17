import Foundation
import Security

// Keychain işlemleri sırasında oluşabilecek özel hata türlerini tanımlar.
// LocalizedError kullanıldığı için kullanıcıya okunabilir hata mesajı gösterebiliriz.
enum KeychainHatasi: LocalizedError {

    case veriDonusturulemedi
    case kaydetmeBasarisiz(OSStatus)
    case okumaBasarisiz(OSStatus)
    case silmeBasarisiz(OSStatus)

    // Her hata türü için ekranda veya loglarda gösterilebilecek açıklama döndürür.
    var errorDescription: String? {

        switch self {

        case .veriDonusturulemedi:
            return "Keychain verisi dönüştürülemedi."

        case .kaydetmeBasarisiz(let durum):
            return "Oturum kaydedilemedi. Kod: \(durum)"

        case .okumaBasarisiz(let durum):
            return "Oturum okunamadı. Kod: \(durum)"

        case .silmeBasarisiz(let durum):
            return "Oturum silinemedi. Kod: \(durum)"
        }
    }
}

// Kullanıcının oturum bilgilerini iOS Keychain üzerinde güvenli şekilde saklayan servis.
// Singleton yapısı sayesinde uygulama boyunca tek bir KeychainService nesnesi kullanılır.
final class KeychainService {

    // Uygulama genelinde ortak kullanılacak tek servis örneği.
    static let shared = KeychainService()

    // Keychain kayıtlarını diğer uygulama kayıtlarından ayırmak için kullanılan servis adı.
    private let servisAdi =
        "com.aysekoca.BulutDosyaSenkronizasyon"

    // Keychain içinde ticket ve kullanıcı adını ayrı anahtarlarla saklıyoruz.
    private let ticketAnahtari = "ticketID"
    private let kullaniciAdiAnahtari = "kullaniciAdi"

    // Dışarıdan yeni nesne oluşturulmasını engeller.
    private init() { }

    // MARK: - Oturum Kaydetme

    // Giriş başarılı olduğunda sunucudan gelen ticket ID ve kullanıcı adını Keychain'e kaydeder.
    func oturumuKaydet(
        ticketID: UUID,
        kullaniciAdi: String
    ) async throws {

        // UUID doğrudan saklanamadığı için String'e çevrilerek kaydedilir.
        try await degerKaydet(
            ticketID.uuidString,
            anahtar: ticketAnahtari
        )

        // Kullanıcı adı da ayrı bir anahtar altında saklanır.
        try await degerKaydet(
            kullaniciAdi,
            anahtar: kullaniciAdiAnahtari
        )
    }

    // MARK: - Ticket Okuma

    // Daha önce Keychain'e kaydedilmiş ticket değerini okur.
    // Otomatik giriş veya API isteklerinde tekrar kullanılabilir.
    func ticketIDOku() async throws -> UUID? {

        guard let ticketMetni =
                try await degerOku(
                    anahtar: ticketAnahtari
                )
        else {
            // Keychain'de ticket yoksa nil döndürülür.
            return nil
        }

        // String olarak saklanan ticket tekrar UUID türüne dönüştürülür.
        return UUID(
            uuidString: ticketMetni
        )
    }

    // MARK: - Kullanıcı Adı Okuma

    // Keychain'de saklanan kullanıcı adını geri getirir.
    func kullaniciAdiOku()
    async throws -> String? {

        try await degerOku(
            anahtar: kullaniciAdiAnahtari
        )
    }

    // MARK: - Oturumu Silme

    // Kullanıcı çıkış yaptığında hem ticket hem de kullanıcı adı Keychain'den silinir.
    func oturumuSil() async throws {

        try await degerSil(
            anahtar: ticketAnahtari
        )

        try await degerSil(
            anahtar: kullaniciAdiAnahtari
        )
    }

    // MARK: - Kaydetme

    // Verilen String değeri belirtilen anahtar ile Keychain'e kaydeden yardımcı fonksiyon.
    private func degerKaydet(
        _ deger: String,
        anahtar: String
    ) async throws {

        // Keychain veriyi Data olarak istediği için String UTF-8 Data'ya dönüştürülür.
        guard let veri =
                deger.data(using: .utf8)
        else {
            throw KeychainHatasi
                .veriDonusturulemedi
        }

        // NOT: kSecAttrAccessGroup kasıtlı olarak
        // belirtilmiyor. Ana uygulama ve extension
        // Keychain Sharing capability ile AYNI TEK
        // access group'a sahip olduğu için, iOS
        // otomatik olarak o grubu kullanır. Böylece
        // Team ID'yi kod içine gömmeye gerek kalmaz.

        // Keychain'de hangi kaydın aranacağını belirleyen sorgu oluşturulur.
        let aramaSorgusu:
            [String: Any] = [

            // Generic Password türünde kayıt kullanıyoruz.
            kSecClass as String:
                kSecClassGenericPassword,

            // Kayıtların ait olduğu servis adı.
            kSecAttrService as String:
                servisAdi,

            // Ticket veya kullanıcı adı gibi kaydı ayıran anahtar.
            kSecAttrAccount as String:
                anahtar
        ]

        // Aynı anahtarla eski bir kayıt varsa önce silinir.
        // Böylece yeni değer temiz şekilde eklenir.
        SecItemDelete(
            aramaSorgusu as CFDictionary
        )

        // Arama sorgusu temel alınarak kaydetme sorgusu hazırlanır.
        var kaydetmeSorgusu =
            aramaSorgusu

        // Saklanacak gerçek veri sorguya eklenir.
        kaydetmeSorgusu[
            kSecValueData as String
        ] = veri

        // Cihaz ilk kez açılıp kilit çözüldükten sonra veriye erişilebilmesini sağlar.
        kaydetmeSorgusu[
            kSecAttrAccessible as String
        ] = kSecAttrAccessibleAfterFirstUnlock

        // Hazırlanan kayıt Keychain'e eklenir.
        let durum =
            SecItemAdd(
                kaydetmeSorgusu
                    as CFDictionary,
                nil
            )

        // İşlem başarılı değilse hata fırlatılır.
        guard durum == errSecSuccess
        else {
            throw KeychainHatasi
                .kaydetmeBasarisiz(
                    durum
                )
        }
    }

    // MARK: - Okuma

    // Belirli bir anahtara ait değeri Keychain'den okuyan yardımcı fonksiyon.
    private func degerOku(
        anahtar: String
    ) async throws -> String? {

        // Keychain'de aranacak kaydın özellikleri belirtilir.
        let sorgu:
            [String: Any] = [

            kSecClass as String:
                kSecClassGenericPassword,

            kSecAttrService as String:
                servisAdi,

            kSecAttrAccount as String:
                anahtar,

            // Bulunan kaydın Data olarak geri döndürülmesini ister.
            kSecReturnData as String:
                true,

            // İlk eşleşen tek kayıt yeterlidir.
            kSecMatchLimit as String:
                kSecMatchLimitOne
        ]

        // Keychain'den dönecek sonucu tutacak değişken.
        var sonuc: CFTypeRef?

        // Sorgu çalıştırılarak eşleşen kayıt aranır.
        let durum =
            SecItemCopyMatching(
                sorgu as CFDictionary,
                &sonuc
            )

        // Kayıt bulunamadıysa bunu hata saymayıp nil döndürüyoruz.
        if durum ==
            errSecItemNotFound {

            return nil
        }

        // Bunun dışındaki başarısız durumlarda hata fırlatılır.
        guard durum == errSecSuccess
        else {
            throw KeychainHatasi
                .okumaBasarisiz(
                    durum
                )
        }

        // Keychain'den gelen Data tekrar String'e dönüştürülür.
        guard
            let veri =
                sonuc as? Data,

            let metin =
                String(
                    data: veri,
                    encoding: .utf8
                )
        else {
            throw KeychainHatasi
                .veriDonusturulemedi
        }

        // Okunan değer çağıran fonksiyona döndürülür.
        return metin
    }

    // MARK: - Silme

    // Belirli bir anahtara ait Keychain kaydını silen yardımcı fonksiyon.
    private func degerSil(
        anahtar: String
    ) async throws {

        // Silinecek kaydı belirlemek için sorgu hazırlanır.
        let sorgu:
            [String: Any] = [

            kSecClass as String:
                kSecClassGenericPassword,

            kSecAttrService as String:
                servisAdi,

            kSecAttrAccount as String:
                anahtar
        ]

        // Eşleşen kayıt Keychain'den silinir.
        let durum =
            SecItemDelete(
                sorgu as CFDictionary
            )

        // Silme başarılıysa veya zaten böyle bir kayıt yoksa işlem başarılı kabul edilir.
        guard
            durum == errSecSuccess ||
            durum == errSecItemNotFound
        else {
            throw KeychainHatasi
                .silmeBasarisiz(
                    durum
                )
        }
    }
}

