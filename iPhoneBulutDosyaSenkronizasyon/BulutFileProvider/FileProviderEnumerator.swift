import FileProvider
import Foundation
import os.log

private let logger = Logger(
    subsystem: "com.aysekoca.BulutFileProvider",
    category: "FileProviderEnumerator"
)

final class FileProviderEnumerator:
    NSObject,
    NSFileProviderEnumerator {

    private let identifier: NSFileProviderItemIdentifier
    private let depo = YerelFileProviderDeposu.shared

    init(identifier: NSFileProviderItemIdentifier) {
        self.identifier = identifier
        super.init()

        logger.info(
            "Enumerator oluşturuldu. ID: \(identifier.rawValue, privacy: .public)"
        )
    }

    func invalidate() {
        logger.info("Enumerator invalidate edildi.")
    }

    func enumerateItems(
        for observer: NSFileProviderEnumerationObserver,
        startingAt page: NSFileProviderPage
    ) {

        logger.info(
            "🚨 enumerateItems ÇAĞRILDI. ID: \(self.identifier.rawValue, privacy: .public)"
        )

        // ÖNEMLİ: Burada network beklemiyoruz.
        // iOS, enumerator(for:) sonrası cevap için
        // sadece birkaç saniye ("grace timer") veriyor.
        // Network isteği bu süreyi aşarsa sistem
        // extension'ı öldürüyor ve Files "Boş" görüyor.
        //
        // Bu yüzden: HEMEN yerel SQLite'taki veriyi
        // döndürüyoruz (ilk seferde boş olabilir),
        // sunucu güncellemesini ARKA PLANDA yapıp
        // bittiğinde signalEnumerator ile Files'a
        // "değişti, tekrar sor" diye haber veriyoruz.

        let kayitlar =
            depo.elemanlariGetir(for: identifier)

        logger.info(
            "✅ enumerateItems (yerel) -> \(kayitlar.count, privacy: .public) öğe."
        )

        let itemler =
            kayitlar.map { $0.item }

        observer.didEnumerate(itemler)
        observer.finishEnumerating(upTo: nil)

        // Sunucu güncellemesini arka planda, enumerator'ın
        // cevap vermesini bloklamadan başlat.
        Task.detached { [identifier] in
            await Self.sunucudanCekVeGuncelleVeSinyalGonder(
                identifier: identifier
            )
        }
    }

    func enumerateChanges(
        for observer: NSFileProviderChangeObserver,
        from anchor: NSFileProviderSyncAnchor
    ) {

        logger.info(
            "enumerateChanges çağrıldı. ID: \(self.identifier.rawValue, privacy: .public)"
        )

        let kayitlar =
            depo.elemanlariGetir(for: identifier)

        logger.info(
            "✅ enumerateChanges (yerel) -> \(kayitlar.count, privacy: .public) öğe."
        )

        if !kayitlar.isEmpty {
            observer.didUpdate(
                kayitlar.map { $0.item }
            )
        }

        observer.finishEnumeratingChanges(
            upTo: depo.guncelAnchor(),
            moreComing: false
        )

        Task.detached { [identifier] in
            await Self.sunucudanCekVeGuncelleVeSinyalGonder(
                identifier: identifier
            )
        }
    }

    func currentSyncAnchor(
        completionHandler: @escaping (NSFileProviderSyncAnchor?) -> Void
    ) {
        completionHandler(depo.guncelAnchor())
    }

    // MARK: - Sunucudan çekme (arka plan, bloklamıyor)

    private static func sunucudanCekVeGuncelleVeSinyalGonder(
        identifier: NSFileProviderItemIdentifier
    ) async {

        let depo = YerelFileProviderDeposu.shared

        do {
            let ticketID =
                try await OturumYoneticisi.shared
                    .ticketIDGetir()

            let parentYolu =
                depo.klasorYolu(identifier) ?? ""

            async let klasorSonucu =
                APIService.shared.klasorListesiniGetir(
                    ticketID: ticketID,
                    klasorYolu: parentYolu
                )

            async let dosyaSonucu =
                APIService.shared.dosyaListesiniGetir(
                    ticketID: ticketID,
                    klasorYolu: parentYolu
                )

            let (klasorlerSonuc, dosyalarSonuc) =
                try await (klasorSonucu, dosyaSonucu)

            depo.klasorIceriginiDegistir(
                parentIdentifier: identifier,
                parentYolu: parentYolu,
                klasorler: klasorlerSonuc.sonucKlasorListe ?? [],
                dosyalar: dosyalarSonuc.sonucDosyaListe ?? []
            )

            logger.info(
                "✅ Arka plan güncelleme tamamlandı, signalEnumerator gönderiliyor."
            )

            // Files'a "bu klasör değişti, tekrar sor" de.
            try? await NSFileProviderManager.default
                .signalEnumerator(for: identifier)

        } catch {
            logger.error(
                "Arka plan güncelleme hatası: \(error.localizedDescription, privacy: .public)"
            )
        }
    }
}
