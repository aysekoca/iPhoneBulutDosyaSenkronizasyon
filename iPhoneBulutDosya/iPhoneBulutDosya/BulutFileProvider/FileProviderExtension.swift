import FileProvider
import Foundation

class FileProviderExtension:
    NSObject,
    NSFileProviderReplicatedExtension,
    NSFileProviderEnumerating {

    required init(domain: NSFileProviderDomain) {

        print("FILE PROVIDER EXTENSION BAŞLADI")
        print("DOMAIN:", domain.identifier.rawValue)
        print("DOMAIN ADI:", domain.displayName)

        super.init()
    }

    func invalidate() {

        print("FILE PROVIDER INVALIDATE")
    }

    func item(
        for identifier: NSFileProviderItemIdentifier,
        request: NSFileProviderRequest,
        completionHandler: @escaping (NSFileProviderItem?, Error?) -> Void
    ) -> Progress {

        print(
            "ITEM İSTENDİ:",
            identifier.rawValue
        )

        completionHandler(
            FileProviderItem(
                identifier: identifier
            ),
            nil
        )

        return Progress()
    }

    func fetchContents(
        for itemIdentifier: NSFileProviderItemIdentifier,
        version requestedVersion: NSFileProviderItemVersion?,
        request: NSFileProviderRequest,
        completionHandler: @escaping (
            URL?,
            NSFileProviderItem?,
            Error?
        ) -> Void
    ) -> Progress {

        print(
            "FETCH CONTENTS:",
            itemIdentifier.rawValue
        )

        completionHandler(
            nil,
            nil,
            NSError(
                domain: NSCocoaErrorDomain,
                code: NSFeatureUnsupportedError
            )
        )

        return Progress()
    }

    func createItem(
        basedOn itemTemplate: NSFileProviderItem,
        fields: NSFileProviderItemFields,
        contents url: URL?,
        options: NSFileProviderCreateItemOptions = [],
        request: NSFileProviderRequest,
        completionHandler: @escaping (
            NSFileProviderItem?,
            NSFileProviderItemFields,
            Bool,
            Error?
        ) -> Void
    ) -> Progress {

        completionHandler(
            nil,
            [],
            false,
            NSError(
                domain: NSCocoaErrorDomain,
                code: NSFeatureUnsupportedError
            )
        )

        return Progress()
    }

    func modifyItem(
        _ item: NSFileProviderItem,
        baseVersion version: NSFileProviderItemVersion,
        changedFields: NSFileProviderItemFields,
        contents newContents: URL?,
        options: NSFileProviderModifyItemOptions = [],
        request: NSFileProviderRequest,
        completionHandler: @escaping (
            NSFileProviderItem?,
            NSFileProviderItemFields,
            Bool,
            Error?
        ) -> Void
    ) -> Progress {

        completionHandler(
            nil,
            [],
            false,
            NSError(
                domain: NSCocoaErrorDomain,
                code: NSFeatureUnsupportedError
            )
        )

        return Progress()
    }

    func deleteItem(
        identifier: NSFileProviderItemIdentifier,
        baseVersion version: NSFileProviderItemVersion,
        options: NSFileProviderDeleteItemOptions = [],
        request: NSFileProviderRequest,
        completionHandler: @escaping (Error?) -> Void
    ) -> Progress {

        completionHandler(
            NSError(
                domain: NSCocoaErrorDomain,
                code: NSFeatureUnsupportedError
            )
        )

        return Progress()
    }

    func enumerator(
        for containerItemIdentifier: NSFileProviderItemIdentifier,
        request: NSFileProviderRequest
    ) throws -> NSFileProviderEnumerator {

        print(
            "ENUMERATOR OLUŞTURULUYOR:",
            containerItemIdentifier.rawValue
        )

        return FileProviderEnumerator(
            enumeratedItemIdentifier:
                containerItemIdentifier
        )
    }
}
