import FileProvider
import Foundation

final class FileProviderExtension:
    NSObject,
    NSFileProviderReplicatedExtension {

    private let depo =
        YerelFileProviderDeposu.shared

    required init(
        domain: NSFileProviderDomain
    ) {
        super.init()

        depo.rootuHazirla()

        print(
            "✅ BulutFileProvider başladı: \(domain.displayName)"
        )
    }

    func invalidate() {
        print(
            "ℹ️ FileProviderExtension invalidate edildi."
        )
    }

    // MARK: - ITEM

    func item(
        for identifier:
            NSFileProviderItemIdentifier,
        request:
            NSFileProviderRequest,
        completionHandler:
            @escaping (
                NSFileProviderItem?,
                Error?
            ) -> Void
    ) -> Progress {

        let progress =
            Progress(
                totalUnitCount: 1
            )

        print(
            "🔵 item(for:) çağrıldı -> \(identifier.rawValue)"
        )

        if identifier == .rootContainer {

            let root =
                FileProviderItem.kok

            print(
                "✅ ROOT item döndürülüyor"
            )

            print(
                "   itemIdentifier = \(root.itemIdentifier.rawValue)"
            )

            print(
                "   parentIdentifier = \(root.parentItemIdentifier.rawValue)"
            )

            print(
                "   filename = \(root.filename)"
            )

            print(
                "   contentType = \(root.contentType.identifier)"
            )

            print(
                "   capabilities = \(root.capabilities.rawValue)"
            )

            completionHandler(
                root,
                nil
            )

        } else if let kayit =
                    depo.kayit(
                        identifier
                    ) {

            print(
                "✅ item local DB'den bulundu -> \(kayit.tamYol)"
            )

            print(
                "   itemIdentifier = \(kayit.identifier.rawValue)"
            )

            print(
                "   parentIdentifier = \(kayit.parentIdentifier.rawValue)"
            )

            completionHandler(
                kayit.item,
                nil
            )

        } else {

            print(
                "❌ item bulunamadı -> \(identifier.rawValue)"
            )

            completionHandler(
                nil,
                NSFileProviderError(
                    .noSuchItem
                )
            )
        }

        progress.completedUnitCount = 1
        return progress
    }

    // MARK: - CONTENT

    func fetchContents(
        for itemIdentifier:
            NSFileProviderItemIdentifier,
        version requestedVersion:
            NSFileProviderItemVersion?,
        request:
            NSFileProviderRequest,
        completionHandler:
            @escaping (
                URL?,
                NSFileProviderItem?,
                Error?
            ) -> Void
    ) -> Progress {

        let progress =
            Progress(
                totalUnitCount: 100
            )

        guard
            let kayit =
                depo.kayit(
                    itemIdentifier
                ),
            kayit.tur == .dosya
        else {

            completionHandler(
                nil,
                nil,
                NSFileProviderError(
                    .noSuchItem
                )
            )

            return progress
        }

        Task {
            do {

                let ticket =
                    try await
                    OturumYoneticisi.shared
                        .ticketIDGetir()

                let ustKlasor =
                    (kayit.tamYol as NSString)
                        .deletingLastPathComponent

                let url =
                    try await
                    APIService.shared
                        .dosyaIndirGeciciKonuma(
                            ticketID:
                                ticket,
                            klasorYolu:
                                ustKlasor,
                            dosyaAdi:
                                kayit.ad
                        )

                progress.completedUnitCount = 100

                completionHandler(
                    url,
                    kayit.item,
                    nil
                )

            } catch {

                completionHandler(
                    nil,
                    nil,
                    error
                )
            }
        }

        return progress
    }

    // MARK: - CREATE

    func createItem(
        basedOn itemTemplate:
            NSFileProviderItem,
        fields:
            NSFileProviderItemFields,
        contents url:
            URL?,
        options:
            NSFileProviderCreateItemOptions = [],
        request:
            NSFileProviderRequest,
        completionHandler:
            @escaping (
                NSFileProviderItem?,
                NSFileProviderItemFields,
                Bool,
                Error?
            ) -> Void
    ) -> Progress {

        let progress =
            Progress(
                totalUnitCount: 1
            )

        completionHandler(
            nil,
            fields,
            false,
            CocoaError(
                .featureUnsupported
            )
        )

        return progress
    }

    // MARK: - MODIFY

    func modifyItem(
        _ item:
            NSFileProviderItem,
        baseVersion version:
            NSFileProviderItemVersion,
        changedFields:
            NSFileProviderItemFields,
        contents newContents:
            URL?,
        options:
            NSFileProviderModifyItemOptions = [],
        request:
            NSFileProviderRequest,
        completionHandler:
            @escaping (
                NSFileProviderItem?,
                NSFileProviderItemFields,
                Bool,
                Error?
            ) -> Void
    ) -> Progress {

        let progress =
            Progress(
                totalUnitCount: 1
            )

        completionHandler(
            nil,
            changedFields,
            false,
            CocoaError(
                .featureUnsupported
            )
        )

        return progress
    }

    // MARK: - DELETE

    func deleteItem(
        identifier:
            NSFileProviderItemIdentifier,
        baseVersion version:
            NSFileProviderItemVersion,
        options:
            NSFileProviderDeleteItemOptions = [],
        request:
            NSFileProviderRequest,
        completionHandler:
            @escaping (
                Error?
            ) -> Void
    ) -> Progress {

        let progress =
            Progress(
                totalUnitCount: 1
            )

        completionHandler(
            CocoaError(
                .featureUnsupported
            )
        )

        return progress
    }

    // MARK: - ENUMERATOR

    func enumerator(
        for containerItemIdentifier:
            NSFileProviderItemIdentifier,
        request:
            NSFileProviderRequest
    ) throws -> NSFileProviderEnumerator {

        print(
            "🟣 enumerator(for:) çağrıldı -> \(containerItemIdentifier.rawValue)"
        )

        if containerItemIdentifier == .rootContainer {

            print(
                "✅ ROOT için enumerator döndürülüyor."
            )

        } else if let kayit =
                    depo.kayit(
                        containerItemIdentifier
                    ) {

            print(
                "✅ Local DB'deki klasör için enumerator -> \(kayit.tamYol)"
            )

        } else {

            print(
                "⚠️ Enumerator istenen identifier local DB'de yok -> \(containerItemIdentifier.rawValue)"
            )
        }

        return FileProviderEnumerator(
            identifier:
                containerItemIdentifier
        )
    }
}

