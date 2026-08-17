import FileProvider
import Foundation
import SQLite3

struct YerelFileProviderKaydi: Equatable {

    let identifierRaw: String
    let parentIdentifierRaw: String
    let tur: OgeTuru
    let sunucuID: Int?
    let ad: String
    let tamYol: String
    let boyut: Int64?

    var identifier: NSFileProviderItemIdentifier {
        NSFileProviderItemIdentifier(identifierRaw)
    }

    var parentIdentifier: NSFileProviderItemIdentifier {
        NSFileProviderItemIdentifier(parentIdentifierRaw)
    }

    var item: FileProviderItem {
        FileProviderItem(kayit: self)
    }
}

final class YerelFileProviderDeposu {

    static let shared = YerelFileProviderDeposu()

    private let appGroup =
        "group.com.aysekoca.iPhoneBulutDosyaSenkronizasyon"

    private let kuyruk =
        DispatchQueue(
            label: "BulutFileProvider.SQLiteDepo"
        )

    private var db: OpaquePointer?
    private let dosyaURL: URL

    private init() {

        // /tmp KULLANMIYORUZ.
        // Öncelik ortak App Group alanı.
        if let grupURL =
            FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier:
                    appGroup
            ) {

            let klasorURL =
                grupURL.appendingPathComponent(
                    "FileProviderDB",
                    isDirectory: true
                )

            try? FileManager.default.createDirectory(
                at: klasorURL,
                withIntermediateDirectories: true
            )

            dosyaURL =
                klasorURL.appendingPathComponent(
                    "fileprovider.sqlite"
                )

        } else {

            // App Group erişilemezse tmp yerine kalıcı
            // Application Support alanını kullan.
            let applicationSupport =
                FileManager.default.urls(
                    for: .applicationSupportDirectory,
                    in: .userDomainMask
                ).first!

            let klasorURL =
                applicationSupport.appendingPathComponent(
                    "FileProviderDB",
                    isDirectory: true
                )

            try? FileManager.default.createDirectory(
                at: klasorURL,
                withIntermediateDirectories: true
            )

            dosyaURL =
                klasorURL.appendingPathComponent(
                    "fileprovider.sqlite"
                )

            print(
                "⚠️ App Group açılamadı. Application Support kullanılıyor."
            )
        }

        veritabaniniAc()
        tablolariOlustur()
        rootuHazirla()

        print(
            "💾 SQLite DB yolu: \(dosyaURL.path)"
        )
    }

    deinit {
        if db != nil {
            sqlite3_close(db)
        }
    }

    // MARK: - ROOT

    func rootuHazirla() {

        kuyruk.sync {

            let rootRaw =
                NSFileProviderItemIdentifier
                    .rootContainer
                    .rawValue

            let sql = """
            INSERT OR REPLACE INTO items
            (
                identifier,
                parent_identifier,
                tur,
                sunucu_id,
                ad,
                tam_yol,
                boyut
            )
            VALUES (?, ?, ?, NULL, ?, ?, NULL);
            """

            var statement: OpaquePointer?

            guard sqlite3_prepare_v2(
                db,
                sql,
                -1,
                &statement,
                nil
            ) == SQLITE_OK
            else {
                sqliteHatasiYaz(
                    "Root prepare"
                )
                return
            }

            defer {
                sqlite3_finalize(statement)
            }

            textBagla(
                statement,
                index: 1,
                deger: rootRaw
            )

            textBagla(
                statement,
                index: 2,
                deger: rootRaw
            )

            textBagla(
                statement,
                index: 3,
                deger: OgeTuru.klasor.rawValue
            )

            textBagla(
                statement,
                index: 4,
                deger: "Bulut Dosyalarım"
            )

            textBagla(
                statement,
                index: 5,
                deger: ""
            )

            guard sqlite3_step(statement)
                == SQLITE_DONE
            else {
                sqliteHatasiYaz(
                    "Root insert"
                )
                return
            }

            print(
                "✅ ROOT SQLite'a kaydedildi. ID: \(rootRaw)"
            )

            if let root =
                kayitKilitsiz(
                    NSFileProviderItemIdentifier
                        .rootContainer
                ) {

                print(
                    "✅ ROOT LOCAL KONTROL: \(root.identifierRaw) | yol='\(root.tamYol)'"
                )

            } else {

                print(
                    "❌ ROOT local DB'den geri okunamadı."
                )
            }
        }
    }

    // MARK: - TEK KAYIT

    func kayit(
        _ identifier:
            NSFileProviderItemIdentifier
    ) -> YerelFileProviderKaydi? {

        kuyruk.sync {
            kayitKilitsiz(identifier)
        }
    }

    func klasorYolu(
        _ identifier:
            NSFileProviderItemIdentifier
    ) -> String? {

        if identifier == .rootContainer {
            return ""
        }

        return kayit(identifier)?.tamYol
    }

    // MARK: - CHILDREN

    func elemanlariGetir(
        for parentIdentifier:
            NSFileProviderItemIdentifier
    ) -> [YerelFileProviderKaydi] {

        kuyruk.sync {

            let sql = """
            SELECT
                identifier,
                parent_identifier,
                tur,
                sunucu_id,
                ad,
                tam_yol,
                boyut
            FROM items
            WHERE parent_identifier = ?
              AND identifier != ?
            ORDER BY tur, ad;
            """

            var statement: OpaquePointer?

            guard sqlite3_prepare_v2(
                db,
                sql,
                -1,
                &statement,
                nil
            ) == SQLITE_OK
            else {
                sqliteHatasiYaz(
                    "Children prepare"
                )
                return []
            }

            defer {
                sqlite3_finalize(statement)
            }

            textBagla(
                statement,
                index: 1,
                deger:
                    parentIdentifier.rawValue
            )

            textBagla(
                statement,
                index: 2,
                deger:
                    NSFileProviderItemIdentifier
                        .rootContainer
                        .rawValue
            )

            var sonuc:
                [YerelFileProviderKaydi] = []

            while sqlite3_step(statement)
                == SQLITE_ROW {

                if let kayit =
                    kayitOlustur(
                        statement
                    ) {
                    sonuc.append(kayit)
                }
            }

            return sonuc
        }
    }

    // MARK: - BACKEND SNAPSHOT

    @discardableResult
    func klasorIceriginiDegistir(
        parentIdentifier:
            NSFileProviderItemIdentifier,
        parentYolu: String,
        klasorler: [Klasor],
        dosyalar: [Dosya]
    ) -> (
        guncellenen:
            [YerelFileProviderKaydi],
        silinen:
            [NSFileProviderItemIdentifier]
    ) {

        kuyruk.sync {

            let eski =
                elemanlariGetirKilitsiz(
                    parentIdentifier:
                        parentIdentifier
                )

            var yeni:
                [YerelFileProviderKaydi] = []

            // Hocanın dediği gibi itemIdentifier
            // STABİL YOLDAN oluşturuluyor.
            for klasor in klasorler {

                let tamYol =
                    parentYolu.isEmpty
                    ? klasor.adi
                    : "\(parentYolu)/\(klasor.adi)"

                let kayit =
                    YerelFileProviderKaydi(
                        identifierRaw:
                            FileProviderYol.identifier(
                                tur: .klasor,
                                sunucuID: klasor.id
                            ).rawValue,
                        parentIdentifierRaw:
                            parentIdentifier.rawValue,
                        tur: .klasor,
                        sunucuID: klasor.id,
                        ad: klasor.adi,
                        tamYol: tamYol,
                        boyut: nil
                    )

                yeni.append(kayit)
            }

            for dosya in dosyalar {

                let tamYol =
                    parentYolu.isEmpty
                    ? dosya.adi
                    : "\(parentYolu)/\(dosya.adi)"

                let kayit =
                    YerelFileProviderKaydi(
                        identifierRaw:
                            FileProviderYol.identifier(
                                tur: .dosya,
                                sunucuID: dosya.id
                            ).rawValue,
                        parentIdentifierRaw:
                            parentIdentifier.rawValue,
                        tur: .dosya,
                        sunucuID: dosya.id,
                        ad: dosya.adi,
                        tamYol: tamYol,
                        boyut:
                            Int64(dosya.boyut)
                    )

                yeni.append(kayit)
            }

            let yeniIDler =
                Set(
                    yeni.map {
                        $0.identifierRaw
                    }
                )

            let silinen =
                eski
                    .filter {
                        !yeniIDler.contains(
                            $0.identifierRaw
                        )
                    }
                    .map {
                        $0.identifier
                    }

            transactionBaslat()

            // Sadece bu parent'ın çocuklarını yenile.
            cocuklariSilKilitsiz(
                parentIdentifier:
                    parentIdentifier
            )

            for kayit in yeni {
                kaydiYazKilitsiz(kayit)
            }

            anchorArtirKilitsiz()
            transactionBitir()

            print(
                "✅ BACKEND -> SQLITE: \(klasorler.count) klasör, \(dosyalar.count) dosya"
            )

            print(
                "✅ PARENT ID: \(parentIdentifier.rawValue)"
            )

            if let ilk = yeni.first {
                print(
                    "🔎 ÖRNEK ITEM ID: \(ilk.identifierRaw)"
                )
                print(
                    "🔎 ÖRNEK YOL: \(ilk.tamYol)"
                )
            }

            return (
                yeni,
                silinen
            )
        }
    }

    // MARK: - ANCHOR

    func guncelAnchor()
    -> NSFileProviderSyncAnchor {

        kuyruk.sync {

            let sql =
                "SELECT deger FROM meta WHERE anahtar = 'anchor' LIMIT 1;"

            var statement: OpaquePointer?

            guard sqlite3_prepare_v2(
                db,
                sql,
                -1,
                &statement,
                nil
            ) == SQLITE_OK
            else {
                return NSFileProviderSyncAnchor(
                    Data("1".utf8)
                )
            }

            defer {
                sqlite3_finalize(statement)
            }

            var anchor = "1"

            if sqlite3_step(statement)
                == SQLITE_ROW,
               let cMetin =
                sqlite3_column_text(
                    statement,
                    0
                ) {

                anchor =
                    String(
                        cString: cMetin
                    )
            }

            return NSFileProviderSyncAnchor(
                Data(anchor.utf8)
            )
        }
    }

    func veritabaniDosyaYolu()
    -> String {
        dosyaURL.path
    }

    // MARK: - SQLITE KURULUM

    private func veritabaniniAc() {

        let sonuc =
            sqlite3_open(
                dosyaURL.path,
                &db
            )

        guard sonuc == SQLITE_OK
        else {
            sqliteHatasiYaz(
                "DB open"
            )
            return
        }

        sqlite3_busy_timeout(
            db,
            3000
        )
    }

    private func tablolariOlustur() {

        let itemsSQL = """
        CREATE TABLE IF NOT EXISTS items
        (
            identifier TEXT PRIMARY KEY NOT NULL,
            parent_identifier TEXT NOT NULL,
            tur TEXT NOT NULL,
            sunucu_id INTEGER,
            ad TEXT NOT NULL,
            tam_yol TEXT NOT NULL,
            boyut INTEGER
        );
        """

        let metaSQL = """
        CREATE TABLE IF NOT EXISTS meta
        (
            anahtar TEXT PRIMARY KEY NOT NULL,
            deger TEXT NOT NULL
        );
        """

        sqlCalistir(itemsSQL)
        sqlCalistir(metaSQL)

        sqlCalistir(
            """
            INSERT OR IGNORE INTO meta
            (anahtar, deger)
            VALUES ('anchor', '1');
            """
        )
    }

    private func sqlCalistir(
        _ sql: String
    ) {

        var hataMetni:
            UnsafeMutablePointer<Int8>?

        let sonuc =
            sqlite3_exec(
                db,
                sql,
                nil,
                nil,
                &hataMetni
            )

        if sonuc != SQLITE_OK {

            if let hataMetni {
                print(
                    "❌ SQLite: \(String(cString: hataMetni))"
                )
                sqlite3_free(hataMetni)
            }
        }
    }

    // MARK: - INTERNAL READ

    private func kayitKilitsiz(
        _ identifier:
            NSFileProviderItemIdentifier
    ) -> YerelFileProviderKaydi? {

        let sql = """
        SELECT
            identifier,
            parent_identifier,
            tur,
            sunucu_id,
            ad,
            tam_yol,
            boyut
        FROM items
        WHERE identifier = ?
        LIMIT 1;
        """

        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(
            db,
            sql,
            -1,
            &statement,
            nil
        ) == SQLITE_OK
        else {
            sqliteHatasiYaz(
                "Item prepare"
            )
            return nil
        }

        defer {
            sqlite3_finalize(statement)
        }

        textBagla(
            statement,
            index: 1,
            deger:
                identifier.rawValue
        )

        guard sqlite3_step(statement)
            == SQLITE_ROW
        else {
            return nil
        }

        return kayitOlustur(
            statement
        )
    }

    private func elemanlariGetirKilitsiz(
        parentIdentifier:
            NSFileProviderItemIdentifier
    ) -> [YerelFileProviderKaydi] {

        let sql = """
        SELECT
            identifier,
            parent_identifier,
            tur,
            sunucu_id,
            ad,
            tam_yol,
            boyut
        FROM items
        WHERE parent_identifier = ?
          AND identifier != ?;
        """

        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(
            db,
            sql,
            -1,
            &statement,
            nil
        ) == SQLITE_OK
        else {
            return []
        }

        defer {
            sqlite3_finalize(statement)
        }

        textBagla(
            statement,
            index: 1,
            deger:
                parentIdentifier.rawValue
        )

        textBagla(
            statement,
            index: 2,
            deger:
                NSFileProviderItemIdentifier
                    .rootContainer
                    .rawValue
        )

        var sonuc:
            [YerelFileProviderKaydi] = []

        while sqlite3_step(statement)
            == SQLITE_ROW {

            if let kayit =
                kayitOlustur(
                    statement
                ) {

                sonuc.append(kayit)
            }
        }

        return sonuc
    }

    private func kayitOlustur(
        _ statement:
            OpaquePointer?
    ) -> YerelFileProviderKaydi? {

        guard
            let identifierC =
                sqlite3_column_text(
                    statement,
                    0
                ),
            let parentC =
                sqlite3_column_text(
                    statement,
                    1
                ),
            let turC =
                sqlite3_column_text(
                    statement,
                    2
                ),
            let adC =
                sqlite3_column_text(
                    statement,
                    4
                ),
            let yolC =
                sqlite3_column_text(
                    statement,
                    5
                )
        else {
            return nil
        }

        let identifier =
            String(
                cString:
                    identifierC
            )

        let parent =
            String(
                cString:
                    parentC
            )

        let turRaw =
            String(
                cString:
                    turC
            )

        let ad =
            String(
                cString:
                    adC
            )

        let tamYol =
            String(
                cString:
                    yolC
            )

        guard let tur =
                OgeTuru(
                    rawValue:
                        turRaw
                )
        else {
            return nil
        }

        let sunucuID: Int?

        if sqlite3_column_type(
            statement,
            3
        ) == SQLITE_NULL {

            sunucuID = nil

        } else {

            sunucuID =
                Int(
                    sqlite3_column_int64(
                        statement,
                        3
                    )
                )
        }

        let boyut: Int64?

        if sqlite3_column_type(
            statement,
            6
        ) == SQLITE_NULL {

            boyut = nil

        } else {

            boyut =
                sqlite3_column_int64(
                    statement,
                    6
                )
        }

        return YerelFileProviderKaydi(
            identifierRaw:
                identifier,
            parentIdentifierRaw:
                parent,
            tur: tur,
            sunucuID:
                sunucuID,
            ad: ad,
            tamYol:
                tamYol,
            boyut:
                boyut
        )
    }

    // MARK: - INTERNAL WRITE

    private func kaydiYazKilitsiz(
        _ kayit:
            YerelFileProviderKaydi
    ) {

        let sql = """
        INSERT OR REPLACE INTO items
        (
            identifier,
            parent_identifier,
            tur,
            sunucu_id,
            ad,
            tam_yol,
            boyut
        )
        VALUES (?, ?, ?, ?, ?, ?, ?);
        """

        var statement:
            OpaquePointer?

        guard sqlite3_prepare_v2(
            db,
            sql,
            -1,
            &statement,
            nil
        ) == SQLITE_OK
        else {
            sqliteHatasiYaz(
                "Insert prepare"
            )
            return
        }

        defer {
            sqlite3_finalize(statement)
        }

        textBagla(
            statement,
            index: 1,
            deger:
                kayit.identifierRaw
        )

        textBagla(
            statement,
            index: 2,
            deger:
                kayit.parentIdentifierRaw
        )

        textBagla(
            statement,
            index: 3,
            deger:
                kayit.tur.rawValue
        )

        if let sunucuID =
            kayit.sunucuID {

            sqlite3_bind_int64(
                statement,
                4,
                sqlite3_int64(
                    sunucuID
                )
            )

        } else {

            sqlite3_bind_null(
                statement,
                4
            )
        }

        textBagla(
            statement,
            index: 5,
            deger:
                kayit.ad
        )

        textBagla(
            statement,
            index: 6,
            deger:
                kayit.tamYol
        )

        if let boyut =
            kayit.boyut {

            sqlite3_bind_int64(
                statement,
                7,
                boyut
            )

        } else {

            sqlite3_bind_null(
                statement,
                7
            )
        }

        if sqlite3_step(statement)
            != SQLITE_DONE {

            sqliteHatasiYaz(
                "Insert step"
            )
        }
    }

    private func cocuklariSilKilitsiz(
        parentIdentifier:
            NSFileProviderItemIdentifier
    ) {

        let sql = """
        DELETE FROM items
        WHERE parent_identifier = ?
          AND identifier != ?;
        """

        var statement:
            OpaquePointer?

        guard sqlite3_prepare_v2(
            db,
            sql,
            -1,
            &statement,
            nil
        ) == SQLITE_OK
        else {
            return
        }

        defer {
            sqlite3_finalize(statement)
        }

        textBagla(
            statement,
            index: 1,
            deger:
                parentIdentifier.rawValue
        )

        textBagla(
            statement,
            index: 2,
            deger:
                NSFileProviderItemIdentifier
                    .rootContainer
                    .rawValue
        )

        _ = sqlite3_step(statement)
    }

    private func anchorArtirKilitsiz() {

        sqlCalistir(
            """
            UPDATE meta
            SET deger =
                CAST(deger AS INTEGER) + 1
            WHERE anahtar = 'anchor';
            """
        )
    }

    // MARK: - TRANSACTION

    private func transactionBaslat() {
        sqlCalistir(
            "BEGIN IMMEDIATE TRANSACTION;"
        )
    }

    private func transactionBitir() {
        sqlCalistir(
            "COMMIT;"
        )
    }

    // MARK: - HELPERS

    private func textBagla(
        _ statement:
            OpaquePointer?,
        index: Int32,
        deger: String
    ) {

        _ = deger.withCString {
            sqlite3_bind_text(
                statement,
                index,
                $0,
                -1,
                SQLITE_TRANSIENT
            )
        }
    }

    private func sqliteHatasiYaz(
        _ baslik: String
    ) {

        guard let db else {
            print(
                "❌ \(baslik): DB yok."
            )
            return
        }

        print(
            "❌ \(baslik): \(String(cString: sqlite3_errmsg(db)))"
        )
    }
}

private let SQLITE_TRANSIENT =
    unsafeBitCast(
        -1,
        to: sqlite3_destructor_type.self
    )

