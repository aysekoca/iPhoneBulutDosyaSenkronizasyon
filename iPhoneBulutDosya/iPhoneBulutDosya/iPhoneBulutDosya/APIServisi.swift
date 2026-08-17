import Foundation

struct Kullanici: Codable {
    let KullaniciAdi: String
    let Sifre: String
}

struct Ticket: Codable {
    let KullaniciAdi: String
    let ID: UUID
    let Sonuc: Bool
}

struct Klasor: Codable {
    let ID: Int
    let Adi: String
}

struct Dosya: Codable {
    let ID: Int
    let Adi: String
    let Boyut: Int
}

struct KlasorVeDosyaSonuc: Codable {
    let Mesaj: String?
    let Sonuc: Bool
    let SonucKlasorListe: [Klasor]?
    let SonucDosyaListe: [Dosya]?
}

final class APIServisi {

    static let shared = APIServisi()

    private let baseURL = "https://test.divvydrive.com/Test/Staj/"

    private let servisKullanicisi = "NDSServis"
    private let servisSifresi = "ca5094ef-eae0-4bd5-a94a-14db3b8f3950"

    private init() { }

    private func basicAuthEkle(_ istek: inout URLRequest) {

        let metin = "\(servisKullanicisi):\(servisSifresi)"

        let kodlanmis = Data(metin.utf8)
            .base64EncodedString()

        istek.setValue(
            "Basic \(kodlanmis)",
            forHTTPHeaderField: "Authorization"
        )
    }

    func ticketAl(
        kullaniciAdi: String,
        sifre: String
    ) async throws -> Ticket {

        guard let url = URL(string: baseURL + "TicketAl") else {
            throw URLError(.badURL)
        }

        var istek = URLRequest(url: url)

        istek.httpMethod = "POST"

        istek.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        basicAuthEkle(&istek)

        let kullanici = Kullanici(
            KullaniciAdi: kullaniciAdi,
            Sifre: sifre
        )

        istek.httpBody = try JSONEncoder().encode(kullanici)

        let (veri, cevap) = try await URLSession.shared.data(for: istek)

        guard let httpCevap = cevap as? HTTPURLResponse,
              (200...299).contains(httpCevap.statusCode)
        else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(
            Ticket.self,
            from: veri
        )
    }

    func klasorleriGetir(
        ticketID: UUID,
        klasorYolu: String = ""
    ) async throws -> [Klasor] {

        var components = URLComponents(
            string: baseURL + "KlasorListesiGetir"
        )

        components?.queryItems = [
            URLQueryItem(
                name: "ticketID",
                value: ticketID.uuidString
            ),
            URLQueryItem(
                name: "klasorYolu",
                value: klasorYolu
            )
        ]

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        var istek = URLRequest(url: url)

        istek.httpMethod = "GET"

        basicAuthEkle(&istek)

        let (veri, cevap) = try await URLSession.shared.data(for: istek)

        guard let httpCevap = cevap as? HTTPURLResponse,
              (200...299).contains(httpCevap.statusCode)
        else {
            throw URLError(.badServerResponse)
        }

        let sonuc = try JSONDecoder().decode(
            KlasorVeDosyaSonuc.self,
            from: veri
        )

        return sonuc.SonucKlasorListe ?? []
    }

    func dosyalariGetir(
        ticketID: UUID,
        klasorYolu: String = ""
    ) async throws -> [Dosya] {

        var components = URLComponents(
            string: baseURL + "DosyaListesiGetir"
        )

        components?.queryItems = [
            URLQueryItem(
                name: "ticketID",
                value: ticketID.uuidString
            ),
            URLQueryItem(
                name: "klasorYolu",
                value: klasorYolu
            )
        ]

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        var istek = URLRequest(url: url)

        istek.httpMethod = "GET"

        basicAuthEkle(&istek)

        let (veri, cevap) = try await URLSession.shared.data(for: istek)

        guard let httpCevap = cevap as? HTTPURLResponse,
              (200...299).contains(httpCevap.statusCode)
        else {
            throw URLError(.badServerResponse)
        }

        let sonuc = try JSONDecoder().decode(
            KlasorVeDosyaSonuc.self,
            from: veri
        )

        return sonuc.SonucDosyaListe ?? []
    }
}
