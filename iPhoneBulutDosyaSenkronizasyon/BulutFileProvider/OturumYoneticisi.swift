import Foundation
import FileProvider

final class OturumYoneticisi {

    static let shared = OturumYoneticisi()

    private let appGroup =
        "group.com.aysekoca.iPhoneBulutDosyaSenkronizasyon"

    private let ticketAnahtari =
        "fileProviderTicketID"

    private init() { }

    func ticketIDGetir() async throws -> UUID {

        print("🔵 File Provider ticket okumaya başladı.")

        guard let defaults =
                UserDefaults(suiteName: appGroup) else {

            print("❌ APP GROUP AÇILAMADI")
            throw NSFileProviderError(.notAuthenticated)
        }

        print("✅ App Group açıldı.")

        guard let ticketMetni =
                defaults.string(forKey: ticketAnahtari) else {

            print("❌ APP GROUP İÇİNDE TICKET YOK")
            print("🔎 Anahtar: \(ticketAnahtari)")

            throw NSFileProviderError(.notAuthenticated)
        }

        print("✅ App Group'tan ticket metni geldi:")
        print(ticketMetni)

        guard let ticket =
                UUID(uuidString: ticketMetni) else {

            print("❌ TICKET UUID'YE ÇEVRİLEMEDİ")
            throw NSFileProviderError(.notAuthenticated)
        }

        print("✅✅✅ FILE PROVIDER TICKET'I BAŞARIYLA OKUDU:")
        print(ticket)

        return ticket
    }
}
