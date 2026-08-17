import FileProvider
import Foundation

class FileProviderEnumerator: NSObject, NSFileProviderEnumerator {

    private let enumeratedItemIdentifier: NSFileProviderItemIdentifier

    private let appGroup =
        "group.com.aysekoca.iPhoneBulutDosya"

    private let anchor =
        NSFileProviderSyncAnchor(
            "anchor".data(using: .utf8)!
        )

    init(
        enumeratedItemIdentifier: NSFileProviderItemIdentifier
    ) {

        self.enumeratedItemIdentifier =
            enumeratedItemIdentifier

        super.init()
    }

    func invalidate() {
    }

    func enumerateItems(
        for observer: NSFileProviderEnumerationObserver,
        startingAt page: NSFileProviderPage
    ) {

        print(
            "ENUMERATOR ÇALIŞTI:",
            enumeratedItemIdentifier.rawValue
        )

        Task {

            do {

                guard let defaults =
                        UserDefaults(
                            suiteName: appGroup
                        )
                else {

                    print("APP GROUP AÇILAMADI")

                    observer.finishEnumeratingWithError(
                        NSFileProviderError(
                            .notAuthenticated
                        )
                    )

                    return
                }

                guard let ticketMetni =
                        defaults.string(
                            forKey: "ticketID"
                        )
                else {

                    print("TICKET BULUNAMADI")

                    observer.finishEnumeratingWithError(
                        NSFileProviderError(
                            .notAuthenticated
                        )
                    )

                    return
                }

                print(
                    "TICKET OKUNDU:",
                    ticketMetni
                )

                guard let ticketID =
                        UUID(
                            uuidString: ticketMetni
                        )
                else {

                    print("TICKET UUID'YE ÇEVRİLEMEDİ")

                    observer.finishEnumeratingWithError(
                        NSFileProviderError(
                            .notAuthenticated
                        )
                    )

                    return
                }

                print("API İSTEĞİ BAŞLIYOR")

                let klasorler =
                    try await APIServisi.shared
                        .klasorleriGetir(
                            ticketID: ticketID,
                            klasorYolu: ""
                        )

                print(
                    "KLASÖR SAYISI:",
                    klasorler.count
                )

                let dosyalar =
                    try await APIServisi.shared
                        .dosyalariGetir(
                            ticketID: ticketID,
                            klasorYolu: ""
                        )

                print(
                    "DOSYA SAYISI:",
                    dosyalar.count
                )

                var itemlar:
                    [NSFileProviderItem] = []

                for klasor in klasorler {

                    print(
                        "FP KLASÖR:",
                        klasor.Adi
                    )

                    itemlar.append(
                        FileProviderItem(
                            klasor: klasor,
                            parentIdentifier:
                                .rootContainer
                        )
                    )
                }

                for dosya in dosyalar {

                    print(
                        "FP DOSYA:",
                        dosya.Adi
                    )

                    itemlar.append(
                        FileProviderItem(
                            dosya: dosya,
                            parentIdentifier:
                                .rootContainer
                        )
                    )
                }

                print(
                    "TOPLAM ITEM:",
                    itemlar.count
                )

                observer.didEnumerate(
                    itemlar
                )

                observer.finishEnumerating(
                    upTo: nil
                )

                print(
                    "ENUMERATION TAMAMLANDI"
                )

            } catch {

                print(
                    "ENUMERATOR HATASI:",
                    error
                )

                observer.finishEnumeratingWithError(
                    error
                )
            }
        }
    }

    func enumerateChanges(
        for observer: NSFileProviderChangeObserver,
        from anchor: NSFileProviderSyncAnchor
    ) {

        observer.finishEnumeratingChanges(
            upTo: self.anchor,
            moreComing: false
        )
    }

    func currentSyncAnchor(
        completionHandler:
        @escaping (
            NSFileProviderSyncAnchor?
        ) -> Void
    ) {

        completionHandler(
            anchor
        )
    }
}
