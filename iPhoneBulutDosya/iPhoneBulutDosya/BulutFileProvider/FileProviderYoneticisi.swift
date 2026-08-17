import Foundation
import FileProvider

final class FileProviderYoneticisi {

    static let shared = FileProviderYoneticisi()

    private let eskiDomainID =
        NSFileProviderDomainIdentifier(
            "com.aysekoca.iPhoneBulutDosya.domain"
        )

    private let yeniDomainID =
        NSFileProviderDomainIdentifier(
            "com.aysekoca.iPhoneBulutDosya.domain2"
        )

    private init() { }

    func domainEkle() async throws {

        // Önce eski domain varsa kaldır
        let domainler = try await domainleriGetir()

        for domain in domainler {

            if domain.identifier == eskiDomainID ||
               domain.identifier == yeniDomainID {

                try await domainSil(domain)

                print(
                    "ESKİ DOMAIN SİLİNDİ:",
                    domain.identifier.rawValue
                )
            }
        }

        // Temiz, yeni domain oluştur
        let yeniDomain = NSFileProviderDomain(
            identifier: yeniDomainID,
            displayName: "Bulut Dosya"
        )

        try await domainOlustur(
            yeniDomain
        )

        print(
            "YENİ DOMAIN EKLENDİ:",
            yeniDomain.identifier.rawValue
        )
    }

    private func domainleriGetir() async throws
    -> [NSFileProviderDomain] {

        try await withCheckedThrowingContinuation {
            (
                continuation:
                CheckedContinuation<
                    [NSFileProviderDomain],
                    Error
                >
            ) in

            NSFileProviderManager.getDomainsWithCompletionHandler {
                domainler,
                hata in

                if let hata = hata {

                    continuation.resume(
                        throwing: hata
                    )

                } else {

                    continuation.resume(
                        returning:
                            domainler
                    )
                }
            }
        }
    }

    private func domainSil(
        _ domain: NSFileProviderDomain
    ) async throws {

        try await withCheckedThrowingContinuation {
            (
                continuation:
                CheckedContinuation<Void, Error>
            ) in

            NSFileProviderManager.remove(
                domain
            ) { hata in

                if let hata = hata {

                    continuation.resume(
                        throwing: hata
                    )

                } else {

                    continuation.resume(
                        returning: ()
                    )
                }
            }
        }
    }

    private func domainOlustur(
        _ domain: NSFileProviderDomain
    ) async throws {

        try await withCheckedThrowingContinuation {
            (
                continuation:
                CheckedContinuation<Void, Error>
            ) in

            NSFileProviderManager.add(
                domain
            ) { hata in

                if let hata = hata {

                    continuation.resume(
                        throwing: hata
                    )

                } else {

                    continuation.resume(
                        returning: ()
                    )
                }
            }
        }
    }
}
