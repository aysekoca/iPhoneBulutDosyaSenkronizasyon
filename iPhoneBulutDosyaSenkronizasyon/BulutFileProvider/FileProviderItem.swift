import FileProvider
import UniformTypeIdentifiers

final class FileProviderItem:
    NSObject,
    NSFileProviderItem {

    private let kayit:
        YerelFileProviderKaydi

    init(
        kayit:
            YerelFileProviderKaydi
    ) {
        self.kayit = kayit
        super.init()
    }

    // MARK: - Root

    static var kok:
        FileProviderItem {

        let kayit =
            YerelFileProviderKaydi(
                identifierRaw:
                    NSFileProviderItemIdentifier
                        .rootContainer
                        .rawValue,
                parentIdentifierRaw:
                    NSFileProviderItemIdentifier
                        .rootContainer
                        .rawValue,
                tur:
                    .klasor,
                sunucuID:
                    nil,
                ad:
                    "Bulut Dosyalarım",
                tamYol:
                    "",
                boyut:
                    nil
            )

        return FileProviderItem(
            kayit: kayit
        )
    }

    // MARK: - Kimlik

    var itemIdentifier:
        NSFileProviderItemIdentifier {

        kayit.identifier
    }

    var parentItemIdentifier:
        NSFileProviderItemIdentifier {

        if itemIdentifier ==
            .rootContainer {

            return .rootContainer
        }

        return kayit
            .parentIdentifier
    }

    // MARK: - Ad

    var filename:
        String {

        if itemIdentifier ==
            .rootContainer {

            return "Bulut Dosyalarım"
        }

        return kayit.ad
    }

    // MARK: - Tür

    var contentType:
        UTType {

        if kayit.tur ==
            .klasor {

            return .folder
        }

        let uzanti =
            (kayit.ad as NSString)
                .pathExtension
                .lowercased()

        guard !uzanti.isEmpty
        else {
            return .data
        }

        return UTType(
            filenameExtension:
                uzanti
        ) ?? .data
    }

    // MARK: - Boyut

    var documentSize:
        NSNumber? {

        guard
            kayit.tur ==
                .dosya,
            let boyut =
                kayit.boyut
        else {
            return nil
        }

        return NSNumber(
            value: boyut
        )
    }

    // MARK: - Yetkiler

    var capabilities:
        NSFileProviderItemCapabilities {

        switch kayit.tur {

        case .klasor:

            return [
                .allowsReading,
                .allowsContentEnumerating
            ]

        case .dosya:

            return [
                .allowsReading
            ]
        }
    }

    // MARK: - Sürüm

    var itemVersion:
        NSFileProviderItemVersion {

        let icerikSurumu =
            "icerik|\(kayit.tur.rawValue)|\(kayit.tamYol)|\(kayit.boyut ?? 0)"

        let metadataSurumu =
            "metadata|\(kayit.identifierRaw)|\(kayit.parentIdentifierRaw)|\(kayit.ad)"

        return NSFileProviderItemVersion(
            contentVersion:
                Data(
                    icerikSurumu.utf8
                ),
            metadataVersion:
                Data(
                    metadataSurumu.utf8
                )
        )
    }


}

