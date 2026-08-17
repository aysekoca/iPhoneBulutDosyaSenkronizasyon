import Foundation
import CryptoKit


private final class TransferIlerlemeDelegesi:
    NSObject,
    URLSessionDataDelegate,
    URLSessionTaskDelegate {

    enum Mod {
        case upload
        case download
    }

    private let mod: Mod
    private let ilerleme: (Double) -> Void

    private var gelenVeri = Data()
    private var cevap: URLResponse?

    private var continuation:
        CheckedContinuation<(Data, URLResponse), Error>?

    init(
        mod: Mod,
        ilerleme: @escaping (Double) -> Void
    ) {
        self.mod = mod
        self.ilerleme = ilerleme
    }

    func baslat(
        istek: URLRequest,
        yuklenecekVeri: Data? = nil
    ) async throws -> (Data, URLResponse) {

        try await withCheckedThrowingContinuation {
            continuation in

            self.continuation = continuation

            let session = URLSession(
                configuration: .default,
                delegate: self,
                delegateQueue: nil
            )

            let gorev: URLSessionTask

            if let yuklenecekVeri {
                var temizIstek = istek
                temizIstek.httpBody = nil

                gorev = session.uploadTask(
                    with: temizIstek,
                    from: yuklenecekVeri
                )
            } else {
                gorev = session.dataTask(
                    with: istek
                )
            }

            DispatchQueue.main.async {
                self.ilerleme(0)
            }

            gorev.resume()
        }
    }

    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler:
            @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        self.cevap = response
        completionHandler(.allow)
    }

    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive data: Data
    ) {
        gelenVeri.append(data)

        guard mod == .download else {
            return
        }

        let beklenenBoyut =
            dataTask.response?.expectedContentLength ?? 0

        guard beklenenBoyut > 0 else {
            return
        }

        let oran = min(
            Double(gelenVeri.count) /
            Double(beklenenBoyut),
            1
        )

        DispatchQueue.main.async {
            self.ilerleme(oran)
        }
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {
        guard
            mod == .upload,
            totalBytesExpectedToSend > 0
        else {
            return
        }

        let oran = min(
            Double(totalBytesSent) /
            Double(totalBytesExpectedToSend),
            1
        )

        DispatchQueue.main.async {
            self.ilerleme(oran)
        }
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        defer {
            session.finishTasksAndInvalidate()
        }

        if let error {
            continuation?.resume(
                throwing: error
            )
            continuation = nil
            return
        }

        guard let cevap else {
            continuation?.resume(
                throwing: APIHatasi.gecersizCevap
            )
            continuation = nil
            return
        }

        DispatchQueue.main.async {
            self.ilerleme(1)
        }

        continuation?.resume(
            returning: (
                gelenVeri,
                cevap
            )
        )

        continuation = nil
    }
}

final class APIService {

    static let shared = APIService()

    private let baseURL = "https://test.divvydrive.com/Test/Staj/"
    private let basicKullaniciAdi = "NDSServis"
    private let basicSifre = "ca5094ef-eae0-4bd5-a94a-14db3b8f3950"

    private init() { }

    // MARK: - Giriş

    func ticketAl(
        kullaniciAdi: String,
        sifre: String
    ) async throws -> Ticket {

        let url = try endpointURL("TicketAl")

        let kullanici = Kullanici(
            kullaniciAdi: kullaniciAdi,
            sifre: sifre
        )

        var istek = temelIstek(url: url)
        istek.httpMethod = "POST"
        istek.httpBody = try JSONEncoder().encode(kullanici)

        return try await istegiGonder(
            istek,
            donusTuru: Ticket.self
        )
    }

    // MARK: - Listeleme

    func klasorListesiniGetir(
        ticketID: UUID,
        klasorYolu: String
    ) async throws -> KlasorVeDosyaIslemleriDonenSonuc {

        let url = try listelemeURL(
            metodAdi: "KlasorListesiGetir",
            ticketID: ticketID,
            klasorYolu: klasorYolu
        )

        var istek = temelIstek(url: url)
        istek.httpMethod = "GET"

        return try await istegiGonder(
            istek,
            donusTuru: KlasorVeDosyaIslemleriDonenSonuc.self
        )
    }

    func dosyaListesiniGetir(
        ticketID: UUID,
        klasorYolu: String
    ) async throws -> KlasorVeDosyaIslemleriDonenSonuc {

        let url = try listelemeURL(
            metodAdi: "DosyaListesiGetir",
            ticketID: ticketID,
            klasorYolu: klasorYolu
        )

        var istek = temelIstek(url: url)
        istek.httpMethod = "GET"

        return try await istegiGonder(
            istek,
            donusTuru: KlasorVeDosyaIslemleriDonenSonuc.self
        )
    }

    // MARK: - Klasör İşlemleri

    func klasorOlustur(
        ticketID: UUID,
        klasorAdi: String,
        klasorYolu: String
    ) async throws -> KlasorVeDosyaIslemleriDonenSonuc {

        let model = KlasorOlusturModel(
            ticketID: ticketID,
            klasorAdi: klasorAdi,
            klasorYolu: klasorYolu
        )

        return try await govdeliIstek(
            metodAdi: "KlasorOlustur",
            httpMetodu: "POST",
            model: model
        )
    }

    func klasorSil(
        ticketID: UUID,
        klasorAdi: String,
        klasorYolu: String
    ) async throws -> KlasorVeDosyaIslemleriDonenSonuc {

        let model = KlasorSilModel(
            ticketID: ticketID,
            klasorAdi: klasorAdi,
            klasorYolu: klasorYolu
        )

        return try await govdeliIstek(
            metodAdi: "KlasorSil",
            httpMetodu: "DELETE",
            model: model
        )
    }

    func klasorGuncelle(
        ticketID: UUID,
        klasorAdi: String,
        klasorYolu: String,
        yeniKlasorAdi: String
    ) async throws -> KlasorVeDosyaIslemleriDonenSonuc {

        let model = KlasorGuncelleModel(
            ticketID: ticketID,
            klasorAdi: klasorAdi,
            klasorYolu: klasorYolu,
            yeniKlasorAdi: yeniKlasorAdi
        )

        return try await govdeliIstek(
            metodAdi: "KlasorGuncelle",
            httpMetodu: "PUT",
            model: model
        )
    }

    func klasorTasi(
        ticketID: UUID,
        klasorAdi: String,
        klasorYolu: String,
        yeniKlasorYolu: String
    ) async throws -> KlasorVeDosyaIslemleriDonenSonuc {

        let model = KlasorTasiModel(
            ticketID: ticketID,
            klasorAdi: klasorAdi,
            klasorYolu: klasorYolu,
            yeniKlasorYolu: yeniKlasorYolu
        )

        return try await govdeliIstek(
            metodAdi: "KlasorTasi",
            httpMetodu: "PUT",
            model: model
        )
    }

    // MARK: - Dosya CRUD

    func dosyaOlustur(
        ticketID: UUID,
        klasorYolu: String,
        dosyaAdi: String
    ) async throws -> KlasorVeDosyaIslemleriDonenSonuc {

        let model = DosyaOlusturModel(
            ticketID: ticketID,
            klasorYolu: klasorYolu,
            dosyaAdi: dosyaAdi
        )

        return try await govdeliIstek(
            metodAdi: "DosyaOlustur",
            httpMetodu: "POST",
            model: model
        )
    }

    func dosyaSil(
        ticketID: UUID,
        klasorYolu: String,
        dosyaAdi: String
    ) async throws -> KlasorVeDosyaIslemleriDonenSonuc {

        let model = DosyaSilModel(
            ticketID: ticketID,
            klasorYolu: klasorYolu,
            dosyaAdi: dosyaAdi
        )

        return try await govdeliIstek(
            metodAdi: "DosyaSil",
            httpMetodu: "DELETE",
            model: model
        )
    }

    func dosyaGuncelle(
        ticketID: UUID,
        klasorYolu: String,
        dosyaAdi: String,
        yeniDosyaAdi: String
    ) async throws -> KlasorVeDosyaIslemleriDonenSonuc {

        let model = DosyaGuncelleModel(
            ticketID: ticketID,
            klasorYolu: klasorYolu,
            dosyaAdi: dosyaAdi,
            yeniDosyaAdi: yeniDosyaAdi
        )

        return try await govdeliIstek(
            metodAdi: "DosyaGuncelle",
            httpMetodu: "PUT",
            model: model
        )
    }

    func dosyaTasi(
        ticketID: UUID,
        klasorYolu: String,
        dosyaAdi: String,
        yeniDosyaYolu: String
    ) async throws -> KlasorVeDosyaIslemleriDonenSonuc {

        let model = DosyaTasiModel(
            ticketID: ticketID,
            klasorYolu: klasorYolu,
            dosyaAdi: dosyaAdi,
            yeniDosyaYolu: yeniDosyaYolu
        )

        return try await govdeliIstek(
            metodAdi: "DosyaTasi",
            httpMetodu: "PUT",
            model: model
        )
    }

    // MARK: - Dosya İndirme

    func dosyaIndir(
        ticketID: UUID,
        klasorYolu: String,
        dosyaAdi: String,
        ilerleme: @escaping (Double) -> Void = { _ in }
    ) async throws -> URL {

        let url = try endpointURL("DosyaIndir")

        guard let belgelerKlasoru = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first else {
            throw APIHatasi.gecersizCevap
        }

        if !FileManager.default.fileExists(atPath: belgelerKlasoru.path) {
            try FileManager.default.createDirectory(
                at: belgelerKlasoru,
                withIntermediateDirectories: true
            )
        }

        let hedefURL = benzersizDosyaURL(
            klasor: belgelerKlasoru,
            dosyaAdi: dosyaAdi
        )

        let model = DosyaIndirModel(
            ticketID: ticketID,
            indirilecekYol: belgelerKlasoru.path,
            klasorYolu: klasorYolu,
            dosyaAdi: dosyaAdi
        )

        var istek = temelIstek(url: url)
        istek.httpMethod = "POST"
        istek.httpBody = try JSONEncoder().encode(model)

        let transfer =
            TransferIlerlemeDelegesi(
                mod: .download,
                ilerleme: ilerleme
            )

        let (veri, cevap) =
            try await transfer.baslat(
                istek: istek
            )

        try cevabiKontrolEt(cevap)

        guard !veri.isEmpty else {
            throw NSError(
                domain: "DosyaIndirme",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Sunucudan boş dosya içeriği geldi."
                ]
            )
        }

        try veri.write(
            to: hedefURL,
            options: .atomic
        )

        print("DOSYA İNDİRİLDİ:", dosyaAdi)
        print("BOYUT:", veri.count)
        print("KAYIT YOLU:", hedefURL.path)

        return hedefURL
    }

    func dosyaIndirGeciciKonuma(
        ticketID: UUID,
        klasorYolu: String,
        dosyaAdi: String
    ) async throws -> URL {

        let url = try endpointURL("DosyaIndir")

        let temizKlasorYolu =
            klasorYolu.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let temizDosyaAdi =
            dosyaAdi.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !temizDosyaAdi.isEmpty else {
            throw NSError(
                domain: "DosyaIndirme",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Dosya adı boş olamaz."
                ]
            )
        }

        let geciciKlasor =
            FileManager.default.temporaryDirectory
                .appendingPathComponent(
                    UUID().uuidString,
                    isDirectory: true
                )

        try FileManager.default.createDirectory(
            at: geciciKlasor,
            withIntermediateDirectories: true
        )

        let hedefURL =
            geciciKlasor.appendingPathComponent(
                temizDosyaAdi
            )

        let model = DosyaIndirModel(
            ticketID: ticketID,
            indirilecekYol: geciciKlasor.path,
            klasorYolu: temizKlasorYolu,
            dosyaAdi: temizDosyaAdi
        )

        var istek = temelIstek(url: url)
        istek.httpMethod = "POST"
        istek.httpBody = try JSONEncoder().encode(model)

        let (veri, cevap) =
            try await URLSession.shared.data(for: istek)

        try cevabiKontrolEt(cevap)

        guard !veri.isEmpty else {
            throw NSError(
                domain: "DosyaIndirme",
                code: 2,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Sunucu boş dosya içeriği döndürdü."
                ]
            )
        }

        try veri.write(
            to: hedefURL,
            options: .atomic
        )

        return hedefURL
    }

    // MARK: - Dosya Direkt Yükleme

    func dosyaDirektYukle(
        ticketID: UUID,
        klasorYolu: String,
        dosyaURL: URL,
        ilerleme: @escaping (Double) -> Void = { _ in }
    ) async throws -> KlasorVeDosyaIslemleriDonenSonuc {

        let erisimBasladi =
            dosyaURL.startAccessingSecurityScopedResource()

        defer {
            if erisimBasladi {
                dosyaURL.stopAccessingSecurityScopedResource()
            }
        }

        let dosyaVerisi = try Data(contentsOf: dosyaURL)
        let dosyaAdi = dosyaURL.lastPathComponent

        let dosyaHash = md5Hesapla(dosyaVerisi)

        var bilesenler = URLComponents(
            string: baseURL + "DosyaDirektYukle"
        )

        bilesenler?.queryItems = [
            URLQueryItem(name: "ticketID", value: ticketID.uuidString),
            URLQueryItem(name: "dosyaAdi", value: dosyaAdi),
            URLQueryItem(name: "klasorYolu", value: klasorYolu),
            URLQueryItem(name: "dosyaHash", value: dosyaHash)
        ]

        guard let url = bilesenler?.url else {
            throw APIHatasi.gecersizURL
        }

        var istek = temelIstek(url: url)
        istek.httpMethod = "POST"
        istek.setValue(
            "application/octet-stream",
            forHTTPHeaderField: "Content-Type"
        )

        let transfer =
            TransferIlerlemeDelegesi(
                mod: .upload,
                ilerleme: ilerleme
            )

        let (veri, cevap) =
            try await transfer.baslat(
                istek: istek,
                yuklenecekVeri: dosyaVerisi
            )

        try cevabiKontrolEt(cevap)

        do {
            return try JSONDecoder().decode(
                KlasorVeDosyaIslemleriDonenSonuc.self,
                from: veri
            )
        } catch {
            if let sunucuMetni =
                String(
                    data: veri,
                    encoding: .utf8
                ) {

                print(
                    "Sunucu cevabı:",
                    sunucuMetni
                )
            }

            throw error
        }
    }

    // MARK: - Ortak İstekler

    private func govdeliIstek<T: Encodable>(
        metodAdi: String,
        httpMetodu: String,
        model: T
    ) async throws -> KlasorVeDosyaIslemleriDonenSonuc {

        let url = try endpointURL(metodAdi)

        var istek = temelIstek(url: url)
        istek.httpMethod = httpMetodu
        istek.httpBody = try JSONEncoder().encode(model)

        return try await istegiGonder(
            istek,
            donusTuru: KlasorVeDosyaIslemleriDonenSonuc.self
        )
    }

    private func istegiGonder<T: Decodable>(
        _ istek: URLRequest,
        donusTuru: T.Type
    ) async throws -> T {

        let (veri, cevap) =
            try await URLSession.shared.data(for: istek)

        try cevabiKontrolEt(cevap)

        do {
            return try JSONDecoder().decode(donusTuru, from: veri)
        } catch {
            if let sunucuMetni = String(data: veri, encoding: .utf8) {
                print("Sunucu cevabı:", sunucuMetni)
            }

            throw error
        }
    }

    private func temelIstek(url: URL) -> URLRequest {
        var istek = URLRequest(url: url)

        istek.setValue(
            "application/json",
            forHTTPHeaderField: "Accept"
        )

        istek.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        istek.setValue(
            basicYetkilendirmeDegeri(),
            forHTTPHeaderField: "Authorization"
        )

        istek.timeoutInterval = 120
        return istek
    }

    // MARK: - URL

    private func endpointURL(_ metodAdi: String) throws -> URL {
        guard let url = URL(string: baseURL + metodAdi) else {
            throw APIHatasi.gecersizURL
        }

        return url
    }

    private func listelemeURL(
        metodAdi: String,
        ticketID: UUID,
        klasorYolu: String
    ) throws -> URL {

        var bilesenler = URLComponents(
            string: baseURL + metodAdi
        )

        bilesenler?.queryItems = [
            URLQueryItem(
                name: "ticketID",
                value: ticketID.uuidString
            ),
            URLQueryItem(
                name: "klasorYolu",
                value: klasorYolu
            )
        ]

        guard let url = bilesenler?.url else {
            throw APIHatasi.gecersizURL
        }

        return url
    }

    // MARK: - Yetkilendirme

    private func basicYetkilendirmeDegeri() -> String {
        let kimlikBilgisi =
            "\(basicKullaniciAdi):\(basicSifre)"

        let kimlikVerisi =
            kimlikBilgisi.data(using: .utf8) ?? Data()

        return "Basic \(kimlikVerisi.base64EncodedString())"
    }

    // MARK: - Kontrol

    private func cevabiKontrolEt(_ cevap: URLResponse) throws {
        guard let httpCevabi = cevap as? HTTPURLResponse else {
            throw APIHatasi.gecersizCevap
        }

        guard (200...299).contains(httpCevabi.statusCode) else {
            throw APIHatasi.sunucuHatasi(httpCevabi.statusCode)
        }
    }

    // MARK: - Hash

    private func md5Hesapla(_ veri: Data) -> String {
        let hash = Insecure.MD5.hash(data: veri)

        return hash.map {
            String(format: "%02x", $0)
        }
        .joined()
    }

    // MARK: - Benzersiz Dosya Adı

    private func benzersizDosyaURL(
        klasor: URL,
        dosyaAdi: String
    ) -> URL {

        let ilkURL = klasor.appendingPathComponent(dosyaAdi)

        if !FileManager.default.fileExists(atPath: ilkURL.path) {
            return ilkURL
        }

        let dosyaURL = URL(fileURLWithPath: dosyaAdi)
        let uzanti = dosyaURL.pathExtension

        let anaAd = dosyaURL
            .deletingPathExtension()
            .lastPathComponent

        var sayac = 1

        while true {
            let yeniAd: String

            if uzanti.isEmpty {
                yeniAd = "\(anaAd) (\(sayac))"
            } else {
                yeniAd = "\(anaAd) (\(sayac)).\(uzanti)"
            }

            let yeniURL = klasor.appendingPathComponent(yeniAd)

            if !FileManager.default.fileExists(atPath: yeniURL.path) {
                return yeniURL
            }

            sayac += 1
        }
    }
}

