import SwiftUI

struct ContentView: View {

    @State private var kullaniciAdi = "Test"
    @State private var sifre = "123456Abc."

    @State private var mesaj = ""
    @State private var yukleniyor = false

    @State private var klasorler: [Klasor] = []
    @State private var dosyalar: [Dosya] = []

    private let appGroup =
        "group.com.aysekoca.iPhoneBulutDosya"

    var body: some View {

        NavigationStack {

            VStack(spacing: 16) {

                Text("Bulut Dosya")
                    .font(.largeTitle)
                    .bold()

                TextField(
                    "Kullanıcı Adı",
                    text: $kullaniciAdi
                )
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

                SecureField(
                    "Şifre",
                    text: $sifre
                )
                .textFieldStyle(.roundedBorder)

                Button {

                    Task {
                        await girisYap()
                    }

                } label: {

                    if yukleniyor {

                        ProgressView()

                    } else {

                        Text("Giriş Yap")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(yukleniyor)

                Text(mesaj)
                    .font(.footnote)
                    .multilineTextAlignment(.center)

                List {

                    if !klasorler.isEmpty {

                        Section("Klasörler") {

                            ForEach(
                                klasorler,
                                id: \.ID
                            ) { klasor in

                                HStack {

                                    Image(
                                        systemName: "folder.fill"
                                    )

                                    Text(klasor.Adi)
                                }
                            }
                        }
                    }

                    if !dosyalar.isEmpty {

                        Section("Dosyalar") {

                            ForEach(
                                dosyalar,
                                id: \.ID
                            ) { dosya in

                                HStack {

                                    Image(
                                        systemName: "doc.fill"
                                    )

                                    VStack(
                                        alignment: .leading
                                    ) {

                                        Text(dosya.Adi)

                                        Text(
                                            "\(dosya.Boyut) byte"
                                        )
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .padding()
            .navigationTitle("Dosyalarım")
        }
    }

    func girisYap() async {

        yukleniyor = true

        mesaj = "Giriş yapılıyor..."

        klasorler = []
        dosyalar = []

        do {

            // 1 - API'den ticket al
            let ticket =
                try await APIServisi.shared.ticketAl(
                    kullaniciAdi: kullaniciAdi,
                    sifre: sifre
                )

            guard ticket.Sonuc else {

                mesaj = "Giriş başarısız."
                yukleniyor = false

                return
            }

            print(
                "TICKET:",
                ticket.ID
            )

            // 2 - Ticket'ı File Provider ile paylaş
            guard let defaults =
                    UserDefaults(
                        suiteName: appGroup
                    )
            else {

                mesaj =
                    "App Group açılamadı."

                yukleniyor = false

                return
            }

            defaults.set(
                ticket.ID.uuidString,
                forKey: "ticketID"
            )

            print(
                "Ticket App Group'a kaydedildi."
            )

            // 3 - File Provider domain oluştur
            do {

                try await FileProviderYoneticisi.shared
                    .domainEkle()

                print(
                    "File Provider domain eklendi."
                )

            } catch {

                print(
                    "DOMAIN HATASI:",
                    error
                )
            }

            // 4 - API'den kök klasörleri getir
            mesaj =
                "Dosya ve klasörler getiriliyor..."

            let gelenKlasorler =
                try await APIServisi.shared
                    .klasorleriGetir(
                        ticketID: ticket.ID,
                        klasorYolu: ""
                    )

            // 5 - API'den kök dosyaları getir
            let gelenDosyalar =
                try await APIServisi.shared
                    .dosyalariGetir(
                        ticketID: ticket.ID,
                        klasorYolu: ""
                    )

            klasorler = gelenKlasorler
            dosyalar = gelenDosyalar

            mesaj =
                "Dosya ve klasörler başarıyla getirildi."

            for klasor in gelenKlasorler {

                print(
                    "KLASÖR:",
                    klasor.ID,
                    klasor.Adi
                )
            }

            for dosya in gelenDosyalar {

                print(
                    "DOSYA:",
                    dosya.ID,
                    dosya.Adi,
                    dosya.Boyut
                )
            }

        } catch {

            mesaj =
                "Hata: \(error.localizedDescription)"

            print(
                "HATA:",
                error
            )
        }

        yukleniyor = false
    }
}

#Preview {
    ContentView()
}
