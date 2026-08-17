import UIKit
import Foundation
import UniformTypeIdentifiers

final class DosyaSecmeServisi: NSObject, UIDocumentPickerDelegate {

    static let shared = DosyaSecmeServisi()

    private var devam: CheckedContinuation<URL?, Never>?

    private override init() { }

    @MainActor
    func dosyaSec() async -> URL? {
        await withCheckedContinuation { devam in
            self.devam = devam

            let picker = UIDocumentPickerViewController(
                forOpeningContentTypes: [.item],
                asCopy: true
            )

            picker.allowsMultipleSelection = false
            picker.delegate = self

            guard let pencere = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first?.keyWindow,
                  let controller = pencere.rootViewController else {
                devam.resume(returning: nil)
                self.devam = nil
                return
            }

            controller.present(picker, animated: true)
        }
    }

    func documentPicker(
        _ controller: UIDocumentPickerViewController,
        didPickDocumentsAt urls: [URL]
    ) {
        devam?.resume(returning: urls.first)
        devam = nil
    }

    func documentPickerWasCancelled(
        _ controller: UIDocumentPickerViewController
    ) {
        devam?.resume(returning: nil)
        devam = nil
    }
}
