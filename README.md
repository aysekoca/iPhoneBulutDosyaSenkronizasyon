# iPhone Bulut Dosya Senkronizasyon

Swift ve SwiftUI kullanılarak geliştirilen bulut dosya yönetimi ve senkronizasyon uygulamasıdır. Uygulama, REST API üzerinden uzak sunucuyla haberleşerek kullanıcıların dosya ve klasörlerini yönetmesini sağlar.

## Projenin Amacı

Projenin temel amacı, bulut sunucusunda bulunan dosya ve klasörlerin uygulama üzerinden görüntülenmesi ve yönetilmesidir. Kullanıcı oturumu güvenli şekilde saklanırken dosya sistemi tarafında Apple File Provider altyapısından yararlanılmıştır.

## Özellikler

* Kullanıcı girişi ve oturum yönetimi
* Ticket tabanlı kimlik doğrulama
* Keychain ile oturum bilgilerinin güvenli saklanması
* REST API ile sunucu iletişimi
* Klasör listeleme
* Klasör oluşturma, güncelleme, taşıma ve silme
* Dosya oluşturma/yükleme
* Dosya indirme
* Dosya güncelleme, taşıma ve silme
* File Provider Extension desteği
* Dosya ve klasörlerin yerel File Provider yapısında tutulması
* SQLite tabanlı yerel File Provider deposu
* API hata yönetimi

## Kullanılan Teknolojiler

* Swift
* SwiftUI
* FileProvider Framework
* URLSession
* REST API
* Keychain Services
* SQLite
* Xcode

## Proje Yapısı

### Models

API ile veri alışverişinde kullanılan kullanıcı, ticket, dosya ve klasör modellerini içerir.

### Services

`APIService` sunucuyla yapılan REST API iletişimini yönetir. `KeychainService` oturum bilgilerinin güvenli şekilde saklanmasından, `DosyaSecmeServisi` ise yerel dosya seçim işlemlerinden sorumludur.

### BulutFileProvider

File Provider entegrasyonunun bulunduğu bölümdür. Dosya ve klasörlerin File Provider öğelerine dönüştürülmesi, listelenmesi ve yerel kayıtlarının yönetilmesi burada gerçekleştirilir.

### ContentView

Uygulamanın temel kullanıcı arayüzünü ve kullanıcı işlemlerini içerir.

## Genel Çalışma Mantığı

Kullanıcı giriş yaptıktan sonra sunucudan alınan ticket bilgisi oturum işlemlerinde kullanılır. Uygulama REST API aracılığıyla sunucudaki dosya ve klasörlere erişir. Yapılan oluşturma, güncelleme, taşıma ve silme işlemleri API üzerinden sunucuya iletilir.

File Provider tarafında ise sunucudan alınan dosya sistemi bilgileri yerel yapıya dönüştürülerek Apple'ın File Provider altyapısıyla çalışacak şekilde yönetilir.

## Geliştirme Ortamı

Proje Xcode üzerinde Swift ve SwiftUI kullanılarak geliştirilmiştir.
