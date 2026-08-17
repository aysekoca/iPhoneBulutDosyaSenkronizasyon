import FileProvider
import UniformTypeIdentifiers

class FileProviderItem: NSObject, NSFileProviderItem {

    private let identifier: NSFileProviderItemIdentifier
    private let parentIdentifier: NSFileProviderItemIdentifier
    private let ad: String
    private let klasorMu: Bool
    private let boyut: Int

    init(identifier: NSFileProviderItemIdentifier) {

        self.identifier = identifier
        self.parentIdentifier = .rootContainer
        self.boyut = 0

        if identifier == .rootContainer {

            self.ad = "Bulut Dosya"
            self.klasorMu = true

        } else {

            self.ad = identifier.rawValue
            self.klasorMu = false
        }

        super.init()
    }

    init(
        klasor: Klasor,
        parentIdentifier: NSFileProviderItemIdentifier = .rootContainer
    ) {

        self.identifier =
            NSFileProviderItemIdentifier(
                "klasor_\(klasor.ID)"
            )

        self.parentIdentifier = parentIdentifier
        self.ad = klasor.Adi
        self.klasorMu = true
        self.boyut = 0

        super.init()
    }

    init(
        dosya: Dosya,
        parentIdentifier: NSFileProviderItemIdentifier = .rootContainer
    ) {

        self.identifier =
            NSFileProviderItemIdentifier(
                "dosya_\(dosya.ID)"
            )

        self.parentIdentifier = parentIdentifier
        self.ad = dosya.Adi
        self.klasorMu = false
        self.boyut = dosya.Boyut

        super.init()
    }

    var itemIdentifier: NSFileProviderItemIdentifier {
        identifier
    }

    var parentItemIdentifier: NSFileProviderItemIdentifier {
        parentIdentifier
    }

    var filename: String {
        ad
    }

    var contentType: UTType {

        if klasorMu {
            return .folder
        }

        let uzanti =
            (ad as NSString).pathExtension

        return UTType(
            filenameExtension: uzanti
        ) ?? .data
    }

    var documentSize: NSNumber? {

        if klasorMu {
            return nil
        }

        return NSNumber(
            value: boyut
        )
    }

    var capabilities: NSFileProviderItemCapabilities {

        if klasorMu {

            return [
                .allowsReading,
                .allowsContentEnumerating
            ]
        }

        return [
            .allowsReading
        ]
    }

    var itemVersion: NSFileProviderItemVersion {

        let surumMetni =
            "\(identifier.rawValue)-\(ad)-\(boyut)"

        let veri =
            surumMetni.data(using: .utf8)
            ?? Data()

        return NSFileProviderItemVersion(
            contentVersion: veri,
            metadataVersion: veri
        )
    }
}
