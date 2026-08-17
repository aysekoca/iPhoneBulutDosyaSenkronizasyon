import SwiftUI
import Foundation
import FileProvider

struct ContentView: View {

    // MARK: - Oturum

    @State private var kullaniciAdi = "Test"
    @State private var sifre = "123456Abc."
    @State private var ticketID: UUID?

    // MARK: - Bulut İçeriği

    @State private var klasorler: [Klasor] = []
    @State private var dosyalar: [Dosya] = []

    @State private var klasorYolu = ""
    @State private var yolGecmisi: [String] = []

    // MARK: - Arayüz Durumları

    @State private var yukleniyor = false
    @State private var mesaj = ""
    @State private var hataMesaji = ""
    @State private var aramaMetni = ""

    @State private var otomatikOturumKontrolEdildi = false

    // MARK: - Yeni Klasör

    @State private var yeniKlasorAdi = ""
    @State private var yeniKlasorPenceresi = false

    // MARK: - Klasör Düzenleme

    @State private var secilenKlasor: Klasor?
    @State private var yeniKlasorAdiDuzenleme = ""
    @State private var klasorDuzenlemePenceresi = false
    @State private var klasorSilmeOnayi = false

    // MARK: - Dosya Düzenleme

    @State private var secilenDosya: Dosya?
    @State private var yeniDosyaAdiDuzenleme = ""
    @State private var dosyaDuzenlemePenceresi = false
    @State private var dosyaSilmeOnayi = false

    var body: some View {
        NavigationStack {
            ZStack {
                arkaPlan

                if ticketID == nil {
                    girisEkrani
                } else {
                    anaEkran
                }

                if yukleniyor {
                    yukleniyorKatmani
                }
            }
        }
        .task {
            guard !otomatikOturumKontrolEdildi else { return }
            otomatikOturumKontrolEdildi = true
            await kayitliOturumuYukle()
        }
        .alert("Yeni Klasör", isPresented: $yeniKlasorPenceresi) {
            TextField("Klasör adı", text: $yeniKlasorAdi)

            Button("Vazgeç", role: .cancel) {
                yeniKlasorAdi = ""
            }

            Button("Oluştur") {
                Task {
                    await yeniKlasorOlustur()
                }
            }
        } message: {
            Text("Bulut alanında yeni bir klasör oluşturun.")
        }
        .alert("Klasörü Yeniden Adlandır", isPresented: $klasorDuzenlemePenceresi) {
            TextField("Yeni klasör adı", text: $yeniKlasorAdiDuzenleme)

            Button("Vazgeç", role: .cancel) { }

            Button("Kaydet") {
                Task {
                    await secilenKlasoruYenidenAdlandir()
                }
            }
        }
        .alert("Dosyayı Yeniden Adlandır", isPresented: $dosyaDuzenlemePenceresi) {
            TextField("Yeni dosya adı", text: $yeniDosyaAdiDuzenleme)

            Button("Vazgeç", role: .cancel) { }

            Button("Kaydet") {
                Task {
                    await secilenDosyayiYenidenAdlandir()
                }
            }
        }
        .alert("Klasör Silinsin mi?", isPresented: $klasorSilmeOnayi) {
            Button("Vazgeç", role: .cancel) { }

            Button("Sil", role: .destructive) {
                Task {
                    await secilenKlasoruSil()
                }
            }
        } message: {
            Text("\(secilenKlasor?.adi ?? "") klasörü silinecek.")
        }
        .alert("Dosya Silinsin mi?", isPresented: $dosyaSilmeOnayi) {
            Button("Vazgeç", role: .cancel) { }

            Button("Sil", role: .destructive) {
                Task {
                    await secilenDosyayiSil()
                }
            }
        } message: {
            Text("\(secilenDosya?.adi ?? "") dosyası silinecek.")
        }
        .alert("Bilgi", isPresented: Binding(
            get: { !hataMesaji.isEmpty },
            set: { yeniDeger in
                if !yeniDeger {
                    hataMesaji = ""
                }
            }
        )) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text(hataMesaji)
        }
    }

    // MARK: - Arka Plan

    private var arkaPlan: some View {
        LinearGradient(
            colors: [
                Color.blue.opacity(0.16),
                Color.cyan.opacity(0.08),
                Color(.systemBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Giriş Ekranı

    private var girisEkrani: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer(minLength: 70)

                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.blue.opacity(0.20),
                                    Color.cyan.opacity(0.12)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 124, height: 124)

                    Image(systemName: "icloud.fill")
                        .font(.system(size: 58, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(spacing: 8) {
                    Text("Bulut Dosyalarım")
                        .font(.system(size: 34, weight: .bold, design: .rounded))

                    Text("Dosyalarınıza güvenli şekilde erişin")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 16) {
                    girisAlani(
                        ikon: "person.fill",
                        baslik: "Kullanıcı adı"
                    ) {
                        TextField("Kullanıcı adı", text: $kullaniciAdi)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }

                    girisAlani(
                        ikon: "lock.fill",
                        baslik: "Şifre"
                    ) {
                        SecureField("Şifre", text: $sifre)
                    }

                    Button {
                        Task {
                            await girisYap()
                        }
                    } label: {
                        HStack(spacing: 10) {
                            if yukleniyor {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "arrow.right.circle.fill")
                            }

                            Text(yukleniyor ? "Giriş Yapılıyor..." : "Giriş Yap")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.roundedRectangle(radius: 16))
                    .disabled(yukleniyor)

                    if !mesaj.isEmpty {
                        Text(mesaj)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(22)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .shadow(
                    color: Color.black.opacity(0.08),
                    radius: 18,
                    x: 0,
                    y: 8
                )
                .padding(.horizontal, 22)

                HStack(spacing: 7) {
                    Image(systemName: "lock.shield.fill")
                    Text("Oturum bilgileri Keychain ile korunur")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                Spacer(minLength: 30)
            }
        }
    }

    private func girisAlani<Content: View>(
        ikon: String,
        baslik: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(baslik)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Image(systemName: ikon)
                    .frame(width: 22)
                    .foregroundStyle(.blue)

                content()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    // MARK: - Ana Ekran

    private var anaEkran: some View {
        VStack(spacing: 0) {
            ustBilgiAlani

            Divider()
                .opacity(0.5)

            if filtrelenmisKlasorler.isEmpty &&
                filtrelenmisDosyalar.isEmpty &&
                !yukleniyor {

                bosKlasorEkrani
            } else {
                dosyaListesi
            }
        }
        .navigationTitle("Bulut Dosyalarım")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $aramaMetni,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Dosya veya klasör ara"
        )
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if !yolGecmisi.isEmpty {
                    Button {
                        Task {
                            await geriGit()
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }
            }

            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    Button {
                        yeniKlasorAdi = ""
                        yeniKlasorPenceresi = true
                    } label: {
                        Label("Yeni Klasör", systemImage: "folder.badge.plus")
                    }

                    Button {
                        Task {
                            await dosyaYukle()
                        }
                    } label: {
                        Label("Dosya Yükle", systemImage: "arrow.up.doc")
                    }

                    Divider()

                    Button {
                        Task {
                            await klasorIceriginiGetir()
                        }
                    } label: {
                        Label("Yenile", systemImage: "arrow.clockwise")
                    }

                    Button(role: .destructive) {
                        Task {
                            await cikisYap()
                        }
                    } label: {
                        Label("Çıkış Yap", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                }
            }
        }
    }

    private var ustBilgiAlani: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.blue.opacity(0.12))
                        .frame(width: 52, height: 52)

                    Image(systemName: "icloud.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(
                        klasorYolu.isEmpty
                        ? "Kök Klasör"
                        : (klasorYolu as NSString).lastPathComponent
                    )
                    .font(.headline)

                    Text(
                        klasorYolu.isEmpty
                        ? "Bulut alanınız"
                        : klasorYolu
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }

                Spacer()
            }

            HStack(spacing: 10) {
                bilgiRozeti(
                    ikon: "folder.fill",
                    metin: "\(klasorler.count) klasör"
                )

                bilgiRozeti(
                    ikon: "doc.fill",
                    metin: "\(dosyalar.count) dosya"
                )

                Spacer()

                Button {
                    Task {
                        await klasorIceriginiGetir()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
            }

            if !mesaj.isEmpty {
                HStack(spacing: 7) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)

                    Text(mesaj)
                        .lineLimit(1)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 14)
    }

    private func bilgiRozeti(
        ikon: String,
        metin: String
    ) -> some View {
        Label(metin, systemImage: ikon)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(Color(.secondarySystemBackground))
            .clipShape(Capsule())
    }

    // MARK: - Dosya / Klasör Listesi

    private var dosyaListesi: some View {
        List {
            if !filtrelenmisKlasorler.isEmpty {
                Section {
                    ForEach(filtrelenmisKlasorler) { klasor in
                        klasorSatiri(klasor)
                    }
                } header: {
                    Text("Klasörler")
                }
            }

            if !filtrelenmisDosyalar.isEmpty {
                Section {
                    ForEach(filtrelenmisDosyalar) { dosya in
                        dosyaSatiri(dosya)
                    }
                } header: {
                    Text("Dosyalar")
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .refreshable {
            await klasorIceriginiGetir()
        }
    }

    private func klasorSatiri(
        _ klasor: Klasor
    ) -> some View {
        Button {
            Task {
                await klasoreGir(klasor)
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.yellow.opacity(0.18))
                        .frame(width: 46, height: 46)

                    Image(systemName: "folder.fill")
                        .font(.title3)
                        .foregroundStyle(.yellow)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(klasor.adi)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text("Klasör")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                secilenKlasor = klasor
                yeniKlasorAdiDuzenleme = klasor.adi
                klasorDuzenlemePenceresi = true
            } label: {
                Label("Yeniden Adlandır", systemImage: "pencil")
            }

            Button(role: .destructive) {
                secilenKlasor = klasor
                klasorSilmeOnayi = true
            } label: {
                Label("Sil", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                secilenKlasor = klasor
                klasorSilmeOnayi = true
            } label: {
                Label("Sil", systemImage: "trash")
            }

            Button {
                secilenKlasor = klasor
                yeniKlasorAdiDuzenleme = klasor.adi
                klasorDuzenlemePenceresi = true
            } label: {
                Label("Adlandır", systemImage: "pencil")
            }
        }
    }

    private func dosyaSatiri(
        _ dosya: Dosya
    ) -> some View {
        Button {
            secilenDosya = dosya

            Task {
                await secilenDosyayiIndir()
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(dosyaRengi(dosya.adi).opacity(0.12))
                        .frame(width: 46, height: 46)

                    Image(systemName: dosyaIkonu(dosya.adi))
                        .font(.title3)
                        .foregroundStyle(dosyaRengi(dosya.adi))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(dosya.adi)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Text(dosyaTuru(dosya.adi))

                        Text("•")

                        Text(boyutuFormatla(dosya.boyut))
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "arrow.down.circle")
                    .font(.title3)
                    .foregroundStyle(.blue)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                secilenDosya = dosya

                Task {
                    await secilenDosyayiIndir()
                }
            } label: {
                Label("İndir", systemImage: "arrow.down.circle")
            }

            Button {
                secilenDosya = dosya
                yeniDosyaAdiDuzenleme = dosya.adi
                dosyaDuzenlemePenceresi = true
            } label: {
                Label("Yeniden Adlandır", systemImage: "pencil")
            }

            Button(role: .destructive) {
                secilenDosya = dosya
                dosyaSilmeOnayi = true
            } label: {
                Label("Sil", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                secilenDosya = dosya
                dosyaSilmeOnayi = true
            } label: {
                Label("Sil", systemImage: "trash")
            }

            Button {
                secilenDosya = dosya
                yeniDosyaAdiDuzenleme = dosya.adi
                dosyaDuzenlemePenceresi = true
            } label: {
                Label("Adlandır", systemImage: "pencil")
            }
        }
    }

    private var bosKlasorEkrani: some View {
        VStack(spacing: 18) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.09))
                    .frame(width: 110, height: 110)

                Image(systemName: aramaMetni.isEmpty ? "folder" : "magnifyingglass")
                    .font(.system(size: 45))
                    .foregroundStyle(.blue.opacity(0.8))
            }

            VStack(spacing: 7) {
                Text(
                    aramaMetni.isEmpty
                    ? "Bu klasör boş"
                    : "Sonuç bulunamadı"
                )
                .font(.title3)
                .fontWeight(.semibold)

                Text(
                    aramaMetni.isEmpty
                    ? "Yeni klasör oluşturabilir veya cihazınızdan dosya yükleyebilirsiniz."
                    : "Farklı bir arama sözcüğü deneyin."
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 38)
            }

            if aramaMetni.isEmpty {
                Button {
                    Task {
                        await dosyaYukle()
                    }
                } label: {
                    Label("Dosya Yükle", systemImage: "arrow.up.doc")
                }
                .buttonStyle(.borderedProminent)
            }

            Spacer()
        }
    }

    // MARK: - Yükleniyor Katmanı

    private var yukleniyorKatmani: some View {
        ZStack {
            Color.black.opacity(0.08)
                .ignoresSafeArea()

            VStack(spacing: 13) {
                ProgressView()
                    .controlSize(.large)

                Text("İşlem yapılıyor...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 24)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(
                color: Color.black.opacity(0.10),
                radius: 16,
                x: 0,
                y: 8
            )
        }
    }

    // MARK: - Filtre

    private var filtrelenmisKlasorler: [Klasor] {
        guard !aramaMetni.isEmpty else {
            return klasorler
        }

        return klasorler.filter {
            $0.adi.localizedCaseInsensitiveContains(aramaMetni)
        }
    }

    private var filtrelenmisDosyalar: [Dosya] {
        guard !aramaMetni.isEmpty else {
            return dosyalar
        }

        return dosyalar.filter {
            $0.adi.localizedCaseInsensitiveContains(aramaMetni)
        }
    }

    // MARK: - Giriş / Oturum

    private let fileProviderAppGroup =
        "group.com.aysekoca.iPhoneBulutDosyaSenkronizasyon"

    private let fileProviderTicketAnahtari =
        "fileProviderTicketID"

    private let fileProviderDomainID =
        "com.aysekoca.iPhoneBulutDosyaSenkronizasyon.BulutFileProvider.v2"

    @MainActor
    private func girisYap() async {

        let temizKullaniciAdi =
            kullaniciAdi.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !temizKullaniciAdi.isEmpty,
              !sifre.isEmpty else {
            hataMesaji = "Kullanıcı adı ve şifre boş bırakılamaz."
            return
        }

        yukleniyor = true
        mesaj = ""

        do {
            let ticket =
                try await APIService.shared.ticketAl(
                    kullaniciAdi: temizKullaniciAdi,
                    sifre: sifre
                )

            guard ticket.sonuc else {
                hataMesaji =
                    "Giriş başarısız. Kullanıcı bilgilerinizi kontrol edin."
                yukleniyor = false
                return
            }

            // Ana uygulama oturumunu güvenli biçimde Keychain'de tutar.
            try await KeychainService.shared.oturumuKaydet(
                ticketID: ticket.id,
                kullaniciAdi: temizKullaniciAdi
            )

            // Extension Keychain'i değil, ortak App Group alanını okuyacak.
            try fileProviderTicketKaydet(ticket.id)

            ticketID = ticket.id
            kullaniciAdi = temizKullaniciAdi

            // Eski FP -1000 durumunu temizlemek için girişte domain'i sıfırla.
            await fileProviderDomaniKaydet()

            await klasorIceriginiGetir()

            mesaj = "Giriş başarılı."

        } catch {
            hataMesaji =
                "Giriş hatası: \(error.localizedDescription)"
        }

        yukleniyor = false
    }

    // MARK: - File Provider Ticket

    private func fileProviderTicketKaydet(_ ticket: UUID) throws {

        guard let defaults =
                UserDefaults(suiteName: fileProviderAppGroup) else {
            throw NSError(
                domain: "FileProviderAppGroup",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "App Group UserDefaults açılamadı."
                ]
            )
        }

        defaults.set(
            ticket.uuidString,
            forKey: fileProviderTicketAnahtari
        )

        // Extension başka bir process olduğu için yazımı hemen görünür kıl.
        defaults.synchronize()

        guard
            let geriOkunan =
                defaults.string(forKey: fileProviderTicketAnahtari),
            geriOkunan == ticket.uuidString
        else {
            throw NSError(
                domain: "FileProviderAppGroup",
                code: 2,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Ticket App Group'a yazıldıktan sonra geri okunamadı."
                ]
            )
        }

        print("✅ Ticket App Group'a yazıldı ve geri okundu: \(ticket)")
    }

    private func fileProviderTicketSil() {

        guard let defaults =
                UserDefaults(suiteName: fileProviderAppGroup) else {
            return
        }

        defaults.removeObject(
            forKey: fileProviderTicketAnahtari
        )

        defaults.synchronize()

        print("✅ File Provider ticket App Group'tan silindi.")
    }

    // MARK: - File Provider Domain

    private func fileProviderDomainOlustur() -> NSFileProviderDomain {
        NSFileProviderDomain(
            identifier: NSFileProviderDomainIdentifier(
                rawValue: fileProviderDomainID
            ),
            displayName: "Bulut Dosyalarım"
        )
    }

    @MainActor
    private func fileProviderDomaniKaydet(
        sifirla: Bool = false
    ) async {

        let domain = fileProviderDomainOlustur()

        do {
            let mevcutDomainler =
                try await NSFileProviderManager.domains()

            let kayitliDomain =
                mevcutDomainler.first {
                    $0.identifier == domain.identifier
                }

            let kullanilacakDomain: NSFileProviderDomain

            if let kayitliDomain {
                kullanilacakDomain = kayitliDomain
                print("ℹ️ File Provider domain zaten kayıtlı.")
            } else {
                // iOS'ta mevcut domainleri silmeye çalışmak
                // "Operation not permitted" üretebildiği için burada
                // sadece ihtiyaç varsa yeni domain ekliyoruz.
                try await NSFileProviderManager.add(domain)
                kullanilacakDomain = domain
                print("✅ File Provider domain eklendi.")
            }

            guard let manager =
                    NSFileProviderManager(for: kullanilacakDomain) else {
                print("❌ File Provider domain manager alınamadı.")
                return
            }

            do {
                try await manager.signalErrorResolved(
                    NSFileProviderError(.notAuthenticated)
                )
                print("✅ FP -1000 authentication durumu temizlendi.")
            } catch {
                print(
                    "⚠️ FP -1000 temizleme atlandı: \(error.localizedDescription)"
                )
            }

            do {
                try await manager.signalEnumerator(
                    for: .rootContainer
                )
                print("✅ Kök klasör yeniden listeleme sinyali gönderildi.")
            } catch {
                print(
                    "⚠️ Kök listeleme sinyali gönderilemedi: \(error.localizedDescription)"
                )
            }

        } catch {
            print(
                "❌ File Provider domain işlemi başarısız: \(error.localizedDescription)"
            )
        }
    }

    @MainActor
    private func kayitliOturumuYukle() async {

        do {
            guard let kayitliTicket =
                    try await KeychainService.shared.ticketIDOku()
            else {
                return
            }

            // File Provider ticket'ını HER AÇILIŞTA yeniden garantiye al.
            try fileProviderTicketKaydet(kayitliTicket)

            ticketID = kayitliTicket

            // Kullanıcı adı okunamazsa oturumu/ticket'ı silme.
            do {
                if let kayitliKullaniciAdi =
                    try await KeychainService.shared.kullaniciAdiOku() {
                    kullaniciAdi = kayitliKullaniciAdi
                }
            } catch {
                print(
                    "⚠️ Kullanıcı adı Keychain'den okunamadı, ticket korunuyor: \(error.localizedDescription)"
                )
            }

            await fileProviderDomaniKaydet()

            await klasorIceriginiGetir()

        } catch {
            // KRİTİK:
            // Önceki sürüm burada App Group ticket'ını siliyordu.
            // Bu da File Provider'ın hemen FP -1000'e düşmesine neden oluyordu.
            print(
                "⚠️ Kayıtlı oturum yüklenemedi, File Provider ticket silinmedi: \(error.localizedDescription)"
            )

            ticketID = nil
        }
    }

    @MainActor
    private func cikisYap() async {

        yukleniyor = true

        do {
            try await KeychainService.shared.oturumuSil()
        } catch {
            hataMesaji =
                "Oturum temizlenirken hata oluştu: \(error.localizedDescription)"
        }

        // Ana uygulama çıkış yaptığında extension ticket'ı da silinir.
        fileProviderTicketSil()

        ticketID = nil
        klasorler = []
        dosyalar = []
        klasorYolu = ""
        yolGecmisi = []
        aramaMetni = ""
        mesaj = ""

        yukleniyor = false
    }

    // MARK: - Listeleme / Gezinme

    @MainActor
    private func klasorIceriginiGetir() async {
        guard let ticketID else { return }

        yukleniyor = true

        do {
            async let klasorCevabi =
                APIService.shared.klasorListesiniGetir(
                    ticketID: ticketID,
                    klasorYolu: klasorYolu
                )

            async let dosyaCevabi =
                APIService.shared.dosyaListesiniGetir(
                    ticketID: ticketID,
                    klasorYolu: klasorYolu
                )

            let (gelenKlasorler, gelenDosyalar) =
                try await (klasorCevabi, dosyaCevabi)

            klasorler =
                gelenKlasorler.sonucKlasorListe ?? []

            dosyalar =
                gelenDosyalar.sonucDosyaListe ?? []

            mesaj = "İçerik güncel."

        } catch {
            hataMesaji =
                "Dosyalar alınamadı: \(error.localizedDescription)"
        }

        yukleniyor = false
    }

    @MainActor
    private func klasoreGir(
        _ klasor: Klasor
    ) async {
        yolGecmisi.append(klasorYolu)

        if klasorYolu.isEmpty {
            klasorYolu = klasor.adi
        } else {
            klasorYolu += "/\(klasor.adi)"
        }

        aramaMetni = ""

        await klasorIceriginiGetir()
    }

    @MainActor
    private func geriGit() async {
        guard let oncekiYol = yolGecmisi.popLast() else {
            return
        }

        klasorYolu = oncekiYol
        aramaMetni = ""

        await klasorIceriginiGetir()
    }

    // MARK: - Klasör İşlemleri

    @MainActor
    private func yeniKlasorOlustur() async {
        guard let ticketID else { return }

        let temizAd =
            yeniKlasorAdi.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !temizAd.isEmpty else {
            hataMesaji = "Klasör adı boş olamaz."
            return
        }

        yukleniyor = true

        do {
            let cevap =
                try await APIService.shared.klasorOlustur(
                    ticketID: ticketID,
                    klasorAdi: temizAd,
                    klasorYolu: klasorYolu
                )

            guard cevap.sonuc else {
                hataMesaji =
                    cevap.mesaj ?? "Klasör oluşturulamadı."
                yukleniyor = false
                return
            }

            yeniKlasorAdi = ""
            mesaj = "Klasör oluşturuldu."

            await klasorIceriginiGetir()

        } catch {
            hataMesaji =
                "Klasör oluşturma hatası: \(error.localizedDescription)"
        }

        yukleniyor = false
    }

    @MainActor
    private func secilenKlasoruYenidenAdlandir() async {
        guard let ticketID,
              let secilenKlasor else {
            return
        }

        let temizAd =
            yeniKlasorAdiDuzenleme
                .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !temizAd.isEmpty else {
            hataMesaji = "Yeni klasör adı boş olamaz."
            return
        }

        yukleniyor = true

        do {
            let cevap =
                try await APIService.shared.klasorGuncelle(
                    ticketID: ticketID,
                    klasorAdi: secilenKlasor.adi,
                    klasorYolu: klasorYolu,
                    yeniKlasorAdi: temizAd
                )

            guard cevap.sonuc else {
                hataMesaji =
                    cevap.mesaj ?? "Klasör yeniden adlandırılamadı."
                yukleniyor = false
                return
            }

            mesaj = "Klasör yeniden adlandırıldı."
            self.secilenKlasor = nil

            await klasorIceriginiGetir()

        } catch {
            hataMesaji =
                "Yeniden adlandırma hatası: \(error.localizedDescription)"
        }

        yukleniyor = false
    }

    @MainActor
    private func secilenKlasoruSil() async {
        guard let ticketID,
              let secilenKlasor else {
            return
        }

        yukleniyor = true

        do {
            let cevap =
                try await APIService.shared.klasorSil(
                    ticketID: ticketID,
                    klasorAdi: secilenKlasor.adi,
                    klasorYolu: klasorYolu
                )

            guard cevap.sonuc else {
                hataMesaji =
                    cevap.mesaj ?? "Klasör silinemedi."
                yukleniyor = false
                return
            }

            mesaj = "Klasör silindi."
            self.secilenKlasor = nil

            await klasorIceriginiGetir()

        } catch {
            hataMesaji =
                "Klasör silme hatası: \(error.localizedDescription)"
        }

        yukleniyor = false
    }

    // MARK: - Dosya İşlemleri

    @MainActor
    private func dosyaYukle() async {
        guard let ticketID else { return }

        guard let dosyaURL =
                await DosyaSecmeServisi.shared.dosyaSec()
        else {
            return
        }

        yukleniyor = true

        do {
            let cevap =
                try await APIService.shared.dosyaDirektYukle(
                    ticketID: ticketID,
                    klasorYolu: klasorYolu,
                    dosyaURL: dosyaURL
                )

            guard cevap.sonuc else {
                hataMesaji =
                    cevap.mesaj ?? "Dosya yüklenemedi."
                yukleniyor = false
                return
            }

            mesaj = "Dosya başarıyla yüklendi."

            await klasorIceriginiGetir()

        } catch {
            hataMesaji =
                "Dosya yükleme hatası: \(error.localizedDescription)"
        }

        yukleniyor = false
    }

    @MainActor
    private func secilenDosyayiIndir() async {
        guard let ticketID,
              let secilenDosya else {
            return
        }

        yukleniyor = true

        do {
            let kaydedilenURL =
                try await APIService.shared.dosyaIndir(
                    ticketID: ticketID,
                    klasorYolu: klasorYolu,
                    dosyaAdi: secilenDosya.adi
                )

            mesaj =
                "\(kaydedilenURL.lastPathComponent) indirildi."

        } catch {
            hataMesaji =
                "Dosya indirme hatası: \(error.localizedDescription)"
        }

        self.secilenDosya = nil
        yukleniyor = false
    }

    @MainActor
    private func secilenDosyayiYenidenAdlandir() async {
        guard let ticketID,
              let secilenDosya else {
            return
        }

        let temizAd =
            yeniDosyaAdiDuzenleme
                .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !temizAd.isEmpty else {
            hataMesaji = "Yeni dosya adı boş olamaz."
            return
        }

        yukleniyor = true

        do {
            let cevap =
                try await APIService.shared.dosyaGuncelle(
                    ticketID: ticketID,
                    klasorYolu: klasorYolu,
                    dosyaAdi: secilenDosya.adi,
                    yeniDosyaAdi: temizAd
                )

            guard cevap.sonuc else {
                hataMesaji =
                    cevap.mesaj ?? "Dosya yeniden adlandırılamadı."
                yukleniyor = false
                return
            }

            mesaj = "Dosya yeniden adlandırıldı."
            self.secilenDosya = nil

            await klasorIceriginiGetir()

        } catch {
            hataMesaji =
                "Yeniden adlandırma hatası: \(error.localizedDescription)"
        }

        yukleniyor = false
    }

    @MainActor
    private func secilenDosyayiSil() async {
        guard let ticketID,
              let secilenDosya else {
            return
        }

        yukleniyor = true

        do {
            let cevap =
                try await APIService.shared.dosyaSil(
                    ticketID: ticketID,
                    klasorYolu: klasorYolu,
                    dosyaAdi: secilenDosya.adi
                )

            guard cevap.sonuc else {
                hataMesaji =
                    cevap.mesaj ?? "Dosya silinemedi."
                yukleniyor = false
                return
            }

            mesaj = "Dosya silindi."
            self.secilenDosya = nil

            await klasorIceriginiGetir()

        } catch {
            hataMesaji =
                "Dosya silme hatası: \(error.localizedDescription)"
        }

        yukleniyor = false
    }

    // MARK: - Yardımcılar

    private func boyutuFormatla(
        _ boyut: Int
    ) -> String {
        let byteSayisi = Double(boyut)

        if byteSayisi < 1024 {
            return "\(boyut) B"
        }

        if byteSayisi < 1024 * 1024 {
            return String(
                format: "%.1f KB",
                byteSayisi / 1024
            )
        }

        if byteSayisi < 1024 * 1024 * 1024 {
            return String(
                format: "%.1f MB",
                byteSayisi / (1024 * 1024)
            )
        }

        return String(
            format: "%.1f GB",
            byteSayisi / (1024 * 1024 * 1024)
        )
    }

    private func dosyaTuru(
        _ dosyaAdi: String
    ) -> String {
        let uzanti =
            (dosyaAdi as NSString)
                .pathExtension
                .lowercased()

        return uzanti.isEmpty
            ? "Dosya"
            : uzanti.uppercased()
    }

    private func dosyaIkonu(
        _ dosyaAdi: String
    ) -> String {
        let uzanti =
            (dosyaAdi as NSString)
                .pathExtension
                .lowercased()

        switch uzanti {
        case "jpg", "jpeg", "png", "gif", "heic":
            return "photo.fill"

        case "pdf":
            return "doc.richtext.fill"

        case "txt", "md":
            return "doc.text.fill"

        case "doc", "docx":
            return "doc.fill"

        case "xls", "xlsx", "csv":
            return "tablecells.fill"

        case "ppt", "pptx":
            return "rectangle.on.rectangle.angled"

        case "zip", "rar", "7z":
            return "archivebox.fill"

        case "mp4", "mov", "avi":
            return "film.fill"

        case "mp3", "wav", "m4a":
            return "music.note"

        case "swift", "py", "java", "js", "html", "css":
            return "chevron.left.forwardslash.chevron.right"

        default:
            return "doc.fill"
        }
    }

    private func dosyaRengi(
        _ dosyaAdi: String
    ) -> Color {
        let uzanti =
            (dosyaAdi as NSString)
                .pathExtension
                .lowercased()

        switch uzanti {
        case "jpg", "jpeg", "png", "gif", "heic":
            return .pink

        case "pdf":
            return .red

        case "xls", "xlsx", "csv":
            return .green

        case "zip", "rar", "7z":
            return .orange

        case "mp4", "mov", "avi":
            return .purple

        case "mp3", "wav", "m4a":
            return .indigo

        default:
            return .blue
        }
    }
}

#Preview {
    ContentView()
}

